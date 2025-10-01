import 'package:flutter/material.dart';
import '../components/design_system/app_colors.dart';
import '../components/design_system/custom_snackbar.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
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
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
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
        CustomSnackBar.showError(
          context,
          message: '登出失敗: $e',
        );
      }
    }
  }

  Future<void> _refreshUserData() async {
    setState(() {
      _isLoading = true;
    });
    await _loadUserData();
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
          '個人資料',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _refreshUserData,
            icon: const Icon(Icons.refresh, color: Colors.black),
            tooltip: '重新載入',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshUserData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 用戶頭像和基本資訊
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.primary100,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary300,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: AppColors.primary900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _userData != null && _userData!['name'] != null
                          ? _userData!['name']
                          : _currentUser?.email?.split('@')[0] ?? '用戶',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentUser?.email ?? '未知信箱',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // 帳戶資訊區塊
              _buildSectionTitle('帳戶資訊'),
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
              
              // 設定區塊
              _buildSectionTitle('設定'),
              const SizedBox(height: 16),
              
              _buildActionButton(
                icon: Icons.edit,
                title: '編輯個人資料',
                subtitle: '更新您的個人資訊',
                onTap: () {
                  // TODO: 實作編輯個人資料功能
                  CustomSnackBar.showInfo(
                    context,
                    message: '編輯個人資料功能即將推出',
                  );
                },
              ),
              
              _buildActionButton(
                icon: Icons.notifications,
                title: '通知設定',
                subtitle: '管理您的通知偏好',
                onTap: () {
                  // TODO: 實作通知設定功能
                  CustomSnackBar.showInfo(
                    context,
                    message: '通知設定功能即將推出',
                  );
                },
              ),
              
              _buildActionButton(
                icon: Icons.security,
                title: '隱私與安全',
                subtitle: '管理您的隱私設定',
                onTap: () {
                  // TODO: 實作隱私設定功能
                  CustomSnackBar.showInfo(
                    context,
                    message: '隱私設定功能即將推出',
                  );
                },
              ),
              
              _buildActionButton(
                icon: Icons.help,
                title: '幫助與支援',
                subtitle: '取得協助或回報問題',
                onTap: () {
                  // TODO: 實作幫助功能
                  CustomSnackBar.showInfo(
                    context,
                    message: '幫助功能即將推出',
                  );
                },
              ),
              
              const SizedBox(height: 32),
              
              // 登出按鈕
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout),
                  label: const Text(
                    '登出',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black,
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
    required String subtitle,
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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppColors.primary900,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
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
