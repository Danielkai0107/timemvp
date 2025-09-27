import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../components/design_system/app_colors.dart';
import '../components/category_tabs.dart';
import '../components/activity_card.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  
  AuthUser? _currentUser;
  bool _isLoading = true;
  
  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
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

            const SizedBox(height: 8),
            
            // 分類標籤
            _buildCategoryTabs(),

            const SizedBox(height: 8),

            
            // 活動列表
            Expanded(
              child: _buildActivityList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('新增活動功能即將推出')),
          );
        },
        backgroundColor: AppColors.primary900,
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }


  // 頂部搜尋、位置和日期時間區域
  Widget _buildTopSection() {
    final now = DateTime.now();
    final dateStr = '${now.month}/${now.day}';
    
    return GestureDetector(
      onTap: () {
        // TODO: 打開篩選 popup
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('篩選功能即將推出')),
        );
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
                const Text(
                  '搜尋',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Spacer(),
                Text(
                  '台北市，大安區',
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
                  dateStr,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
                Text(
                  '08:00 - 17:00',
                  style: TextStyle(
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
  
  // 分類標籤
  Widget _buildCategoryTabs() {
    final categories = ['全部', '語言教學', '技能羅盤', '活動支援', '生活'];
    
    return CategoryTabs(
      categories: categories,
      initialIndex: _selectedCategoryIndex,
      onTabChanged: (index) {
        setState(() {
          _selectedCategoryIndex = index;
        });
      },
    );
  }
  
  // 活動列表
  Widget _buildActivityList() {
    final activities = _getSampleActivities();
    
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return ActivityCard(
          title: activity['title'],
          date: activity['date'],
          time: activity['time'],
          price: activity['price'],
          location: activity['location'],
          isPro: activity['isPro'] ?? false,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('點擊了活動: ${activity['title']}')),
            );
          },
        );
      },
    );
  }
  
  // 示例活動數據
  List<Map<String, dynamic>> _getSampleActivities() {
    return [
      {
        'title': '「台灣味！呷厲害」第一屆食農大會',
        'date': '10/10 (六)',
        'time': '9:00 - 12:00',
        'price': '\$1,500 TWD',
        'location': '台北市',
        'isPro': true,
      },
      {
        'title': '共讀時光｜打造專屬的親子攝影',
        'date': '10/10 (六)',
        'time': '12:00 - 16:00',
        'price': '\$1,200 TWD',
        'location': '台北市',
        'isPro': true,
      },
      {
        'title': '【免費線上講座】青少年的心聲，你聽見了嗎？',
        'date': '10/10 (六)',
        'time': '12:00 - 16:00',
        'price': '免費｜線上',
        'location': '',
        'isPro': false,
      },
      {
        'title': '孩子為什麼焦慮？理解青少年的壓力來源',
        'date': '10/10 (六)',
        'time': '12:00 - 16:00',
        'price': '免費｜線上',
        'location': '',
        'isPro': false,
      },
    ];
  }

}
