import 'package:flutter/material.dart';
import 'design_system/app_colors.dart';

class CategoryTabs extends StatefulWidget {
  final List<String> categories;
  final int initialIndex;
  final Function(int)? onTabChanged;

  const CategoryTabs({
    super.key,
    required this.categories,
    this.initialIndex = 0,
    this.onTabChanged,
  });

  @override
  State<CategoryTabs> createState() => _CategoryTabsState();
}

class _CategoryTabsState extends State<CategoryTabs> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.categories.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedIndex;
          final isFirst = index == 0;
          final isLast = index == widget.categories.length - 1;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedIndex = index;
              });
              widget.onTabChanged?.call(index);
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
                  widget.categories[index],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color:  AppColors.black,
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
