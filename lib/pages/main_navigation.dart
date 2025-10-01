
import 'package:flutter/material.dart';
import '../components/bottom_navigation_bar.dart';
import 'home.dart';
import 'my_activities_page.dart';
import 'profile_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const MyActivitiesPage(),
    const ProfilePage(),
  ];

  void _onTabSelected(int index) {
    final previousIndex = _currentIndex;
    
    setState(() {
      _currentIndex = index;
    });
    
    // 如果切換到「我的活動」頁面（index = 1），觸發自動重整
    if (index == 1 && previousIndex != 1) {
      debugPrint('切換到我的活動頁面，觸發自動重整');
      // 使用 Future.delayed 確保頁面已經完全切換
      Future.delayed(const Duration(milliseconds: 100), () {
        MyActivitiesPageController.refreshActivities();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: _pages,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
      ),
    );
  }
}
