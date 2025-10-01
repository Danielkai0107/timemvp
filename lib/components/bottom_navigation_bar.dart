import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'design_system/app_colors.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
            top: BorderSide(
              color: AppColors.grey300,
              width: 1,
            ),
          ),  
      ),
      child: SafeArea(
        child: Container(
          height: 58,
          padding: const EdgeInsets.only(left: 12, right: 12, top: 0, bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildNavItem(
                index: 0,
                iconPath: 'assets/images/home.svg',
                label: '首頁',
              ),
              _buildNavItem(
                index: 1,
                iconPath: 'assets/images/activity.svg',
                label: '我的活動',
              ),
              _buildNavItem(
                index: 2,
                iconPath: 'assets/images/user.svg',
                label: '個人資料',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String iconPath,
    required String label,
  }) {
    final isActive = currentIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: SvgPicture.asset(
                  iconPath,
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    isActive ? AppColors.primary900 : Colors.grey.shade600,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? AppColors.primary900 : Colors.grey.shade600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
