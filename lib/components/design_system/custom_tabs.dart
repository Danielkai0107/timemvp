import 'package:flutter/material.dart';
import 'app_colors.dart';

class CustomTabs extends StatefulWidget {
  final List<TabItem> tabs;
  final int initialIndex;
  final ValueChanged<int>? onTabChanged;
  final double height;
  final Color? indicatorColor;
  final Color? selectedLabelColor;
  final Color? unselectedLabelColor;
  final Color? dividerColor;
  final TextStyle? selectedLabelStyle;
  final TextStyle? unselectedLabelStyle;
  final TabController? controller; // 新增外部 TabController 支持

  const CustomTabs({
    super.key,
    required this.tabs,
    this.initialIndex = 0,
    this.onTabChanged,
    this.height = 48,
    this.indicatorColor,
    this.selectedLabelColor,
    this.unselectedLabelColor,
    this.dividerColor,
    this.selectedLabelStyle,
    this.unselectedLabelStyle,
    this.controller, // 新增外部 TabController 支持
  });

  @override
  CustomTabsState createState() => CustomTabsState();
}

class CustomTabsState extends State<CustomTabs>
    with SingleTickerProviderStateMixin {
  TabController? _internalTabController;
  TabController get _tabController => widget.controller ?? _internalTabController!;

  @override
  void initState() {
    super.initState();
    
    // 如果沒有外部 TabController，創建內部的
    if (widget.controller == null) {
      _internalTabController = TabController(
        length: widget.tabs.length,
        vsync: this,
        initialIndex: widget.initialIndex,
      );
    }

    // 監聽 Tab 切換事件
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        widget.onTabChanged?.call(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _internalTabController?.dispose();
    super.dispose();
  }

  int get currentIndex => _tabController.index;

  void switchToTab(int index) {
    if (index >= 0 && index < widget.tabs.length) {
      _tabController.animateTo(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: TabBar(
        controller: _tabController,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        padding: EdgeInsets.zero,
        labelPadding: EdgeInsets.zero,
        dividerColor: widget.dividerColor ?? AppColors.divider,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            color: widget.indicatorColor ?? AppColors.black,
            width: 2.0,
          ),
          insets: EdgeInsets.zero,
        ),
        labelColor: widget.selectedLabelColor ?? AppColors.black,
        unselectedLabelColor: widget.unselectedLabelColor ?? AppColors.grey500,
        labelStyle: widget.selectedLabelStyle ??
            const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
        unselectedLabelStyle: widget.unselectedLabelStyle ??
            const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
            ),
        tabs: widget.tabs
            .map(
              (tab) => Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (tab.icon != null) ...[
                      Icon(tab.icon, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(tab.text),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class TabItem {
  final String text;
  final IconData? icon;

  const TabItem({
    required this.text,
    this.icon,
  });
}

// 預設樣式建構器
class TabsBuilder {
  // 個人/企業選項卡樣式（原登入頁使用的樣式）
  static CustomTabs personalBusiness({
    int initialIndex = 0,
    ValueChanged<int>? onTabChanged,
  }) {
    return CustomTabs(
      initialIndex: initialIndex,
      onTabChanged: onTabChanged,
      indicatorColor: AppColors.black,
      selectedLabelColor: AppColors.black,
      unselectedLabelColor: AppColors.grey500,
      dividerColor: AppColors.divider,
      selectedLabelStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
      ),
      tabs: const [
        TabItem(
          text: '個人',
          icon: Icons.person_outline_rounded,
        ),
        TabItem(
          text: '企業',
          icon: Icons.work_outline_rounded,
        ),
      ],
    );
  }

  // 基本樣式
  static CustomTabs basic({
    required List<TabItem> tabs,
    int initialIndex = 0,
    ValueChanged<int>? onTabChanged,
    TabController? controller,
  }) {
    return CustomTabs(
      tabs: tabs,
      initialIndex: initialIndex,
      onTabChanged: onTabChanged,
      controller: controller,
    );
  }

  // 黃色主題樣式
  static CustomTabs yellowTheme({
    required List<TabItem> tabs,
    int initialIndex = 0,
    ValueChanged<int>? onTabChanged,
  }) {
    return CustomTabs(
      tabs: tabs,
      initialIndex: initialIndex,
      onTabChanged: onTabChanged,
      indicatorColor: AppColors.primary900,
      selectedLabelColor: AppColors.primary900,
      unselectedLabelColor: AppColors.grey500,
    );
  }
}
