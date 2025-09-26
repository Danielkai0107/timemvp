import 'package:flutter/material.dart';
import '../components/design_system/app_colors.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  
  AuthUser? _currentUser;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

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
        final doc = await _userService.getUserDocument(_currentUser!.uid);
        if (doc.exists && doc.data() != null) {
          if (mounted) {
            setState(() {
              _userData = doc.data() as Map<String, dynamic>;
              _isLoading = false;
            });
          }
          debugPrint('用戶資料載入成功');
        } else {
          debugPrint('用戶文檔不存在或為空');
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
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

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      _navigateToLogin();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('登出失敗: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
      appBar: AppBar(
        title: const Text(
          'TiMe',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout, color: Colors.black),
            tooltip: '登出',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 歡迎訊息
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary300,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '歡迎回來！',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _userData != null && _userData!['name'] != null
                          ? '您好，${_userData!['name']}'
                          : '您好，${_currentUser?.email ?? '用戶'}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // 帳戶資訊
              const Text(
                '帳戶資訊',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              
              const SizedBox(height: 16),
              
              _buildInfoCard('電子信箱', _currentUser?.email ?? '未知'),
              
              if (_userData != null) ...[
                _buildInfoCard(
                  '帳戶類型', 
                  _userData!['accountType'] == 'business' ? '企業帳戶' : '個人帳戶'
                ),
                
                if (_userData!['accountType'] == 'personal') ...[
                  if (_userData!['name'] != null)
                    _buildInfoCard('姓名', _userData!['name']),
                  if (_userData!['gender'] != null)
                    _buildInfoCard('性別', _getGenderDisplayName(_userData!['gender'])),
                  if (_userData!['age'] != null)
                    _buildInfoCard('年齡', '${_userData!['age']} 歲'),
                ] else ...[
                  if (_userData!['companyName'] != null)
                    _buildInfoCard('企業名稱', _userData!['companyName']),
                  if (_userData!['contactName'] != null)
                    _buildInfoCard('聯絡人', _userData!['contactName']),
                ],
                
                _buildInfoCard(
                  '驗證狀態', 
                  _userData!['isVerified'] == true ? '已驗證' : '未驗證'
                ),
              ],
              
              const SizedBox(height: 32),
              
              // 功能按鈕
              const Text(
                '功能',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              
              const SizedBox(height: 16),
              
              _buildActionButton(
                icon: Icons.refresh,
                title: '重新載入資料',
                onTap: () {
                  setState(() {
                    _isLoading = true;
                  });
                  _loadUserData();
                },
              ),
              
              const Spacer(),
              
              // 登出按鈕
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _signOut,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '登出',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary300,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.primary900,
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  String _getGenderDisplayName(String gender) {
    switch (gender) {
      case 'male':
        return '男性';
      case 'female':
        return '女性';
      case 'other':
        return '其他';
      case 'prefer_not_to_say':
        return '不願透露';
      default:
        return gender;
    }
  }
}
