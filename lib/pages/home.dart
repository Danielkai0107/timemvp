import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../components/design_system/app_colors.dart';
import '../components/design_system/custom_tabs.dart';
import '../components/design_system/custom_snackbar.dart';
import '../components/category_tabs.dart';
import '../components/activity_card.dart';
import '../components/search_filter_popup.dart';
import '../services/auth_service.dart';
import '../services/activity_service.dart';
import '../services/search_filter_service.dart';
import 'login_page.dart';
import 'create_activity_page.dart';
import 'activity_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

/// 全域的 HomePage 狀態控制器
class HomePageController {
  static _HomePageState? _currentState;
  
  static void _register(_HomePageState state) {
    _currentState = state;
  }
  
  static void _unregister() {
    _currentState = null;
  }
  
  /// 觸發重新載入活動數據
  static void refreshActivities() {
    _currentState?._refreshFromExternal();
  }
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final ActivityService _activityService = ActivityService();
  final SearchFilterService _searchFilterService = SearchFilterService();
  
  AuthUser? _currentUser;
  bool _isLoading = true;
  List<Map<String, dynamic>> _eventActivities = [];
  List<Map<String, dynamic>> _taskActivities = [];
  List<Map<String, dynamic>> _filteredEventActivities = [];
  List<Map<String, dynamic>> _filteredTaskActivities = [];
  bool _isLoadingActivities = false;
  
  late TabController _tabController;
  int _selectedCategoryIndex = 0; // 分類篩選索引

  @override
  void initState() {
    super.initState();
    
    // 註冊到全域控制器
    HomePageController._register(this);
    
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    
    // 初始化搜尋篩選服務
    _initializeSearchFilter();
    
    _loadUserData();
    _loadActivities();
  }

  @override
  void dispose() {
    // 從全域控制器註銷
    HomePageController._unregister();
    _tabController.dispose();
    // 先移除監聽器再dispose
    _searchFilterService.removeListener(_onSearchFilterChanged);
    _searchFilterService.dispose();
    super.dispose();
  }
  
  /// 初始化搜尋篩選服務
  Future<void> _initializeSearchFilter() async {
    await _searchFilterService.initialize();
    _searchFilterService.addListener(_onSearchFilterChanged);
  }
  
  /// 搜尋篩選條件變更時的回調
  void _onSearchFilterChanged() {
    if (mounted) {
      _applyFilters();
    }
  }

  Future<void> _loadUserData() async {
    try {
      _currentUser = _authService.currentUser;
      if (_currentUser != null) {
        debugPrint('載入用戶資料: ${_currentUser!.uid}');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        debugPrint('用戶資料載入成功');
      } else {
        // 用戶未登入，但不立即導航，讓AuthStateWidget處理
        debugPrint('用戶未登入，應該由AuthStateWidget處理');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        // 使用延遲導航避免立即導航衝突
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _navigateToLogin();
          }
        });
      }
    } catch (e) {
      debugPrint('載入用戶資料失敗: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  /// 載入活動資料
  Future<void> _loadActivities() async {
    if (_isLoadingActivities) return;
    
    setState(() {
      _isLoadingActivities = true;
    });

    try {
      debugPrint('開始載入活動資料...');
      
      // 根據選中的分類獲取活動
      String? categoryFilter;
      if (_selectedCategoryIndex > 0) {
        final categories = ['', 'EventCategory_language_teaching', 'EventCategory_skill_experience', 'EventCategory_event_support', 'EventCategory_life_service'];
        categoryFilter = categories[_selectedCategoryIndex];
      }
      
      // 分別載入活動和任務
      final eventActivities = await _activityService.getAllActivities(
        type: 'event',
        category: categoryFilter,
        limit: 20,
      );
      
      final taskActivities = await _activityService.getAllActivities(
        type: 'task',
        category: categoryFilter,
        limit: 20,
      );
      
      debugPrint('載入了 ${eventActivities.length} 個活動，${taskActivities.length} 個任務');
      
      if (mounted) {
        setState(() {
          _eventActivities = eventActivities;
          _taskActivities = taskActivities;
        });
        _applyFilters(); // 載入活動後應用篩選
      }
    } catch (e) {
      debugPrint('載入活動失敗: $e');
      if (mounted) {
        CustomSnackBar.showError(
          context,
          message: '載入活動失敗: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingActivities = false;
        });
      }
    }
  }

  /// 重整特定類型的活動
  Future<void> _refreshActivities(String type) async {
    try {
      debugPrint('重整 $type 活動資料...');
      
      // 根據選中的分類獲取活動
      String? categoryFilter;
      if (_selectedCategoryIndex > 0) {
        final categories = ['', 'EventCategory_language_teaching', 'EventCategory_skill_experience', 'EventCategory_event_support', 'EventCategory_life_service'];
        categoryFilter = categories[_selectedCategoryIndex];
      }
      
      final activities = await _activityService.getAllActivities(
        type: type,
        category: categoryFilter,
        limit: 20,
      );
      
      debugPrint('重整載入了 ${activities.length} 個 $type');
      
      if (mounted) {
        setState(() {
          if (type == 'event') {
            _eventActivities = activities;
          } else {
            _taskActivities = activities;
          }
        });
        _applyFilters(); // 重整活動後應用篩選
      }
    } catch (e) {
      debugPrint('重整 $type 活動失敗: $e');
      if (mounted) {
        CustomSnackBar.showError(
          context,
          message: '重整活動失敗: $e',
        );
      }
    }
  }

  /// 從外部觸發的重整方法
  Future<void> _refreshFromExternal() async {
    debugPrint('=== 從外部觸發首頁重整 ===');
    await _loadActivities();
  }
  
  /// 應用搜尋篩選條件
  void _applyFilters() {
    if (mounted) {
      setState(() {
        _filteredEventActivities = _eventActivities
            .where((activity) => _searchFilterService.matchesFilters(activity))
            .toList();
        _filteredTaskActivities = _taskActivities
            .where((activity) => _searchFilterService.matchesFilters(activity))
            .toList();
      });
    }
  }
  
  /// 顯示篩選彈窗
  void _showFilterPopup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SearchFilterPopup(
        searchFilterService: _searchFilterService,
        onApplyFilters: _applyFilters,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary900,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 頂部搜尋、位置和日期時間區域
            _buildTopSection(),

            const SizedBox(height: 12),
            
            // 發布類型標籤
            _buildCustomTabs(),

            const SizedBox(height: 24),
            
            // 分類標籤
            _buildCategoryTabs(),

            const SizedBox(height: 12),

            
            // 活動列表（支持左右滑動）
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildActivityList(_filteredEventActivities, 'event'),
                  _buildActivityList(_filteredTaskActivities, 'task'),
                ],
              ),
            ),
          ],
        ),
      ),
      
      floatingActionButton: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary900,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(32),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CreateActivityPage(),
                ),
              );
            },
            child: const Center(
              child: Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }


  // 頂部搜尋、位置和日期時間區域
  Widget _buildTopSection() {
    return GestureDetector(
      onTap: () {
        _showFilterPopup();
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // 搜尋和位置區域
            Row(
              children: [
                SvgPicture.asset(
                  'assets/images/search.svg',
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    Colors.grey.shade600,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _searchFilterService.searchKeyword.isEmpty 
                        ? '搜尋' 
                        : _searchFilterService.searchKeyword,
                    style: TextStyle(
                      fontSize: 16,
                      color: _searchFilterService.searchKeyword.isEmpty 
                          ? Colors.grey.shade600 
                          : Colors.black,
                      fontWeight: FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                // 位置顯示區域
                Text(
                  _searchFilterService.locationText,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // 日期和時間區域
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _searchFilterService.dateText,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
                Text(
                  _searchFilterService.timeText,
                  style: const TextStyle(
                    fontSize: 30,
                    color: Colors.black,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // 發布類型標籤
  Widget _buildCustomTabs() {
    final customTabItems = [
      const TabItem(text: '找活動', icon: Icons.sports_bar_outlined),
      const TabItem(text: '找任務', icon: Icons.work_outline_rounded),
    ];
    
    return TabsBuilder.basic(
      tabs: customTabItems,
      controller: _tabController,
      onTabChanged: (index) {
        // 這裡不需要手動切換，因為使用了外部 TabController
      },
    );
  }
  
  // 分類標籤
  Widget _buildCategoryTabs() {
    final categories = ['全部', '語言教學', '技能羅盤', '活動支援', '生活服務'];
    
    return CategoryTabs(
      categories: categories,
      initialIndex: _selectedCategoryIndex,
      onTabChanged: (index) {
        setState(() {
          _selectedCategoryIndex = index;
        });
        _loadActivities(); // 分類改變時重新載入活動
      },
    );
  }
  
  // 活動列表
  Widget _buildActivityList(List<Map<String, dynamic>> activities, String type) {
    if (_isLoadingActivities) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary900,
        ),
      );
    }

    if (activities.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _refreshActivities(type),
        color: AppColors.primary900,
        backgroundColor: Colors.white,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 200),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '目前沒有活動',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: () => _refreshActivities(type),
      color: AppColors.primary900,
      backgroundColor: Colors.white,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: activities.length,
        itemBuilder: (context, index) {
          final activity = activities[index];
          return ActivityCard(
            title: activity['name'] ?? '',
            date: _formatDate(activity['startDateTime']),
            time: _formatTimeRange(activity['startDateTime'], activity['endDateTime']),
            price: _formatPrice(activity['price']),
            location: _getLocationText(activity),
            imageUrl: _getActivityImageUrl(activity),
            isPro: activity['price'] != null && activity['price'] > 0,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ActivityDetailPage(
                    activityId: activity['id'] ?? '',
                    activityData: activity,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// 格式化日期顯示
  String _formatDate(String? dateTimeString) {
    if (dateTimeString == null) return '';
    
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final weekdays = ['日', '一', '二', '三', '四', '五', '六'];
      final weekday = weekdays[dateTime.weekday % 7];
      return '${dateTime.month}/${dateTime.day} ($weekday)';
    } catch (e) {
      return '';
    }
  }

  /// 格式化時間範圍顯示
  String _formatTimeRange(String? startDateTimeString, String? endDateTimeString) {
    if (startDateTimeString == null || endDateTimeString == null) return '';
    
    try {
      final startDateTime = DateTime.parse(startDateTimeString);
      final endDateTime = DateTime.parse(endDateTimeString);
      
      return '${startDateTime.hour.toString().padLeft(2, '0')}:${startDateTime.minute.toString().padLeft(2, '0')} - ${endDateTime.hour.toString().padLeft(2, '0')}:${endDateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  /// 格式化價格顯示
  String _formatPrice(dynamic price) {
    if (price == null || price == 0 || price < 50) {
      return '免費';
    }
    
    if (price is int) {
      return '\$${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} TWD';
    }
    
    return price.toString();
  }

  /// 獲取地點文字
  String _getLocationText(Map<String, dynamic> activity) {
    final isOnline = activity['isOnline'] ?? false;
    if (isOnline) {
      return '線上活動';
    }
    
    final address = activity['address'] ?? '';
    final city = activity['city'] ?? '';
    final area = activity['area'] ?? '';
    
    if (address.isNotEmpty) {
      if (city.isNotEmpty && area.isNotEmpty) {
        return '$city$area';
      } else {
        return address;
      }
    }
    
    return '地點未提供';
  }

  /// 獲取活動圖片URL
  String? _getActivityImageUrl(Map<String, dynamic> activity) {
    debugPrint('檢查活動圖片: ${activity['name']}');
    
    // 優先使用 cover 欄位
    if (activity['cover'] != null && activity['cover'].toString().isNotEmpty) {
      debugPrint('使用 cover 圖片: ${activity['cover']}');
      return activity['cover'];
    }
    
    // 其次使用 files 陣列中的第一張圖片
    if (activity['files'] != null && activity['files'] is List) {
      final files = activity['files'] as List;
      debugPrint('files 陣列長度: ${files.length}');
      if (files.isNotEmpty && files.first is Map) {
        final firstFile = files.first as Map<String, dynamic>;
        debugPrint('使用 files 第一張圖片: ${firstFile['url']}');
        return firstFile['url'];
      }
    }
    
    debugPrint('沒有找到圖片URL');
    return null;
  }

}
