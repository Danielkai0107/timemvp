
import 'package:flutter/material.dart';
import '../components/bottom_navigation_bar.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
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
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  final List<Widget> _pages = [
    const HomePage(),
    const MyActivitiesPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _startKycStatusListener();
  }

  @override
  void dispose() {
    _userService.stopKycStatusListener();
    super.dispose();
  }

  /// 啟動KYC狀態監聽器
  void _startKycStatusListener() {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      debugPrint('啟動KYC狀態監聽器: ${currentUser.uid}');
      _userService.startKycStatusListener(currentUser.uid);
    }
  }

  void _onTabSelected(int index) {
    final previousIndex = _currentIndex;
    
    setState(() {
      _currentIndex = index;
    });
    
    // 如果切換到「首頁」（index = 0），觸發自動重整
    if (index == 0 && previousIndex != 0) {
      debugPrint('切換到首頁，觸發自動重整');
      // 使用 Future.delayed 確保頁面已經完全切換
      Future.delayed(const Duration(milliseconds: 100), () {
        HomePageController.refreshActivities();
      });
    }
    
    // 如果切換到「我的活動」頁面（index = 1），觸發自動重整
    if (index == 1 && previousIndex != 1) {
      debugPrint('切換到我的活動頁面，觸發自動重整');
      // 使用 Future.delayed 確保頁面已經完全切換
      Future.delayed(const Duration(milliseconds: 100), () {
        MyActivitiesPageController.refreshActivities();
      });
    }
    
    // 如果切換到「個人資料」頁面（index = 2），觸發自動重整
    if (index == 2 && previousIndex != 2) {
      debugPrint('切換到個人資料頁面，觸發自動重整');
      // 使用 Future.delayed 確保頁面已經完全切換
      Future.delayed(const Duration(milliseconds: 100), () {
        ProfilePageController.refreshProfile();
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
