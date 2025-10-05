import 'package:flutter/material.dart';
import 'design_system/app_colors.dart';
import '../services/category_service.dart';

/// 分類標籤數據模型
class CategoryTabData {
  final String id;
  final String displayName;
  final String? categoryName; // 對應後端的分類名稱，null 表示"全部"

  const CategoryTabData({
    required this.id,
    required this.displayName,
    this.categoryName,
  });
}

class CategoryTabs extends StatefulWidget {
  final String activityType; // 'event' 或 'task' 或 'all'
  final int initialIndex;
  final Function(int, CategoryTabData?)? onTabChanged;
  final bool showAllTab; // 是否顯示"全部"標籤

  const CategoryTabs({
    super.key,
    required this.activityType,
    this.initialIndex = 0,
    this.onTabChanged,
    this.showAllTab = true,
  });

  @override
  State<CategoryTabs> createState() => _CategoryTabsState();
}

class _CategoryTabsState extends State<CategoryTabs> {
  late int _selectedIndex;
  final CategoryService _categoryService = CategoryService();
  List<CategoryTabData> _categoryTabs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _loadCategories();
  }

  @override
  void didUpdateWidget(CategoryTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果活動類型改變，重新載入分類
    if (oldWidget.activityType != widget.activityType) {
      _loadCategories();
    }
  }

  /// 載入分類數據
  Future<void> _loadCategories() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      List<Category> categories = [];
      
      // 首先嘗試從 Firebase 獲取數據
      if (widget.activityType == 'all') {
        categories = await _categoryService.getAllCategories();
      } else {
        categories = await _categoryService.getCategoriesByType(widget.activityType);
      }

      // 構建標籤數據
      final categoryTabs = <CategoryTabData>[];
      
      // 添加"全部"標籤（如果需要）
      if (widget.showAllTab) {
        categoryTabs.add(const CategoryTabData(
          id: 'all',
          displayName: '全部',
          categoryName: null,
        ));
      }
      
      // 添加分類標籤
      for (final category in categories) {
        categoryTabs.add(CategoryTabData(
          id: category.id,
          displayName: category.displayName,
          categoryName: category.name,
        ));
      }

      if (mounted) {
        setState(() {
          _categoryTabs = categoryTabs;
          _isLoading = false;
          _error = null;
          
          // 確保選中的索引在有效範圍內
          if (_selectedIndex >= categoryTabs.length) {
            _selectedIndex = 0;
          }
        });
      }
    } catch (e) {
      debugPrint('從 Firebase 載入分類失敗，嘗試使用備用數據: $e');
      
      // Firebase 失敗時，嘗試使用備用數據
      try {
        List<Category> fallbackCategories = [];
        
        if (widget.activityType == 'all') {
          fallbackCategories = await _categoryService.getCategoriesWithFallback();
        } else {
          fallbackCategories = await _categoryService.getCategoriesByTypeWithFallback(widget.activityType);
        }

        // 構建標籤數據
        final categoryTabs = <CategoryTabData>[];
        
        // 添加"全部"標籤（如果需要）
        if (widget.showAllTab) {
          categoryTabs.add(const CategoryTabData(
            id: 'all',
            displayName: '全部',
            categoryName: null,
          ));
        }
        
        // 添加分類標籤
        for (final category in fallbackCategories) {
          categoryTabs.add(CategoryTabData(
            id: category.id,
            displayName: category.displayName,
            categoryName: category.name,
          ));
        }

        if (mounted) {
        setState(() {
          _categoryTabs = categoryTabs;
          _isLoading = false;
          _error = null;
            
            // 確保選中的索引在有效範圍內
            if (_selectedIndex >= categoryTabs.length) {
              _selectedIndex = 0;
            }
          });
        }
      } catch (fallbackError) {
        debugPrint('備用分類數據也載入失敗: $fallbackError');
        if (mounted) {
          setState(() {
            _error = '無法載入分類數據';
            _isLoading = false;
            // 只顯示"全部"標籤
            _categoryTabs = widget.showAllTab 
                ? [const CategoryTabData(id: 'all', displayName: '全部', categoryName: null)]
                : [];
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary900,
            ),
          ),
        ),
      );
    }

    if (_error != null || _categoryTabs.isEmpty) {
      // 錯誤狀態或沒有分類時，顯示預設的"全部"標籤
      final defaultTabs = widget.showAllTab 
          ? [const CategoryTabData(id: 'all', displayName: '全部', categoryName: null)]
          : <CategoryTabData>[];
      
      return Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 0),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: defaultTabs.length,
          itemBuilder: (context, index) {
            final isSelected = index == _selectedIndex;
            final isFirst = index == 0;
            final isLast = index == defaultTabs.length - 1;
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                });
                widget.onTabChanged?.call(index, defaultTabs[index]);
              },
              child: Container(
                margin: EdgeInsets.only(
                  left: isFirst ? 16 : 0,
                  right: isLast ? 16 : 12,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary900 : AppColors.grey100,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    defaultTabs[index].displayName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categoryTabs.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedIndex;
          final isFirst = index == 0;
          final isLast = index == _categoryTabs.length - 1;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedIndex = index;
              });
              widget.onTabChanged?.call(index, _categoryTabs[index]);
            },
            child: Container(
              margin: EdgeInsets.only(
                left: isFirst ? 16 : 0,
                right: isLast ? 16 : 12,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary900 : AppColors.grey100,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Center(
                child: Text(
                  _categoryTabs[index].displayName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
