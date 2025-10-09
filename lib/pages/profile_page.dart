import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../components/design_system/app_colors.dart';
import '../components/design_system/custom_snackbar.dart';
import '../components/design_system/user_profile_popup.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'login_page.dart';
import 'kyc_page.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

/// 全域的 ProfilePage 狀態控制器
class ProfilePageController {
  static _ProfilePageState? _currentState;
  
  static void _register(_ProfilePageState state) {
    _currentState = state;
  }
  
  static void _unregister() {
    _currentState = null;
  }
  
  /// 觸發重新載入用戶資料
  static void refreshProfile() {
    _currentState?._refreshFromExternal();
  }
}

class _ProfilePageState extends State<ProfilePage> with WidgetsBindingObserver {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  
  AuthUser? _currentUser;
  Map<String, dynamic>? _userData;
  String? _kycStatus;
  String? _accountType;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // 註冊到全域控制器
    ProfilePageController._register(this);
    
    // 註冊應用生命週期監聽器
    WidgetsBinding.instance.addObserver(this);
    
    _loadUserData();
  }

  @override
  void dispose() {
    // 從全域控制器註銷
    ProfilePageController._unregister();
    
    // 移除應用生命週期監聽器
    WidgetsBinding.instance.removeObserver(this);
    
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // 當應用從背景回到前景時，重新載入用戶資料
    if (state == AppLifecycleState.resumed && mounted) {
      debugPrint('應用回到前景，重新載入個人資料');
      _refreshUserData();
    }
  }

  Future<void> _loadUserData() async {
    try {
      _currentUser = _authService.currentUser;
      if (_currentUser != null) {
        debugPrint('載入用戶資料: ${_currentUser!.uid}');
        
        // 並行載入用戶資料、KYC 狀態和帳號類型
        final futures = await Future.wait([
          _userService.getUserDocument(_currentUser!.uid),
          _userService.getUnifiedKycStatus(_currentUser!.uid), // 使用統一的 KYC 狀態方法
          _userService.getUserAccountType(_currentUser!.uid),
        ]);
        
        final doc = futures[0] as dynamic;
        final kycStatus = futures[1] as String?;
        final accountType = futures[2] as String?;
        
        if (mounted) {
          setState(() {
            if (doc?.exists == true && doc?.data() != null) {
              _userData = doc.data() as Map<String, dynamic>;
            }
            _kycStatus = kycStatus;
            _accountType = accountType;
            _isLoading = false;
          });
        }
        debugPrint('用戶資料載入成功 - KYC狀態: $kycStatus, 帳號類型: $accountType');
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
    debugPrint('導向登入頁面...');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false, // 清除所有頁面堆疊
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

  /// 從外部觸發的重整方法
  Future<void> _refreshFromExternal() async {
    debugPrint('=== 從外部觸發個人資料重整 ===');
    // 確保在 UI 線程中執行
    if (mounted) {
      await _refreshUserData();
    }
  }

  /// 導向編輯個人資料頁面
  Future<void> _showEditProfileDialog() async {
    try {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => const EditProfilePage(),
        ),
      );

      // 無論是否有變更，都重新載入用戶資料以確保狀態同步
      debugPrint('從編輯個人資料頁面返回，重新載入用戶資料');
      await _refreshUserData();
      
      if (result == true) {
        // 如果有變更，顯示成功訊息
        if (mounted) {
          CustomSnackBar.showSuccess(
            context,
            message: '個人資料已更新',
          );
        }
      }
    } catch (e) {
      debugPrint('導向編輯個人資料頁面失敗: $e');
      if (mounted) {
        CustomSnackBar.showError(
          context,
          message: '無法開啟編輯個人資料頁面',
        );
      }
    }
  }

  /// 顯示註銷帳號確認對話框
  Future<void> _showDeleteAccountDialog() async {
    final TextEditingController passwordController = TextEditingController();
    bool isDeleting = false;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red.shade600,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '註銷帳號',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.error900,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '此操作將永久刪除您的帳號和所有相關數據，包括：',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '• 個人資料和設定\n• 上傳的照片和文件\n• 活動記錄\n• 所有其他相關數據',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '此操作無法復原。請輸入您的密碼以確認：',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    enabled: !isDeleting,
                    decoration: InputDecoration(
                      labelText: '密碼',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.lock),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () {
                    passwordController.dispose();
                    Navigator.of(context).pop();
                  },
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: isDeleting ? null : () async {
                    if (passwordController.text.trim().isEmpty) {
                      CustomSnackBar.showError(
                        context,
                        message: '請輸入密碼',
                      );
                      return;
                    }

                    setState(() {
                      isDeleting = true;
                    });

                    try {
                      await _deleteAccount(passwordController.text.trim());
                      passwordController.dispose();
                      Navigator.of(context).pop();
                      
                      // 確保在對話框關閉後再導向登入頁面
                      if (mounted) {
                        CustomSnackBar.showSuccess(
                          context,
                          message: '帳號已成功註銷',
                        );
                        
                        // 延遲一下讓用戶看到成功訊息，然後導向登入頁面
                        Future.delayed(const Duration(seconds: 1), () {
                          if (mounted) {
                            _navigateToLogin();
                          }
                        });
                      }
                    } catch (e) {
                      setState(() {
                        isDeleting = false;
                      });
                      if (mounted) {
                        CustomSnackBar.showError(
                          context,
                          message: e.toString(),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: isDeleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('確認刪除'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 執行註銷帳號
  Future<void> _deleteAccount(String password) async {
    try {
      if (_currentUser == null) {
        throw Exception('沒有用戶登入');
      }

      debugPrint('開始註銷帳號流程...');

      // 1. 重新驗證用戶
      await _authService.reauthenticateUser(password: password);
      debugPrint('用戶重新驗證完成');

      // 2. 刪除用戶數據
      await _userService.deleteUserData(_currentUser!.uid);
      debugPrint('用戶數據刪除完成');

      // 3. 刪除Firebase Authentication帳號
      await _authService.deleteAccount();
      debugPrint('Firebase帳號刪除完成');

      debugPrint('註銷帳號流程完成');
    } catch (e) {
      debugPrint('註銷帳號失敗: $e');
      throw Exception(e.toString().replaceAll('Exception: ', ''));
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
      body: SafeArea(
        child: Column(
          children: [
            // 標題區域
            Container(
              padding: const EdgeInsets.only(top: 20),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                child: Row(
                  children: [
                    const Text(
                      '個人資料',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 內容區域
            Expanded(
              child: RefreshIndicator(
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
                    GestureDetector(
                      onTap: _showUserProfilePopup,
                      child: Container(
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
                        child: ClipOval(
                          child: _buildProfileAvatar(),
                        ),
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
                    const SizedBox(height: 8),
                    _buildKycStatusBadge(),
                    const SizedBox(height: 8),
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
              
              const SizedBox(height: 24),
              
              // 設定區塊
              _buildSectionTitle('設定'),
              const SizedBox(height: 16),
              
              _buildActionButton(
                icon: Icons.edit,
                title: '編輯個人資料',
                subtitle: '更新您的個人資訊',
                onTap: _showEditProfileDialog,
              ),
              
              const SizedBox(height: 32),
              
              // 危險區域標題
              _buildSectionTitle('危險區域'),
              const SizedBox(height: 16),
              
              // 註銷帳號按鈕
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _showDeleteAccountDialog,
                  icon: const Icon(Icons.delete_forever),
                  label: const Text(
                    '註銷帳號',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
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
                    backgroundColor: AppColors.primary900,
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
            ),
          ],
        ),
      ),
    );
  }

  /// 構建個人資料頭像
  Widget _buildProfileAvatar() {
    String? avatarUrl;
    
    // 優先檢查新的 avatar 欄位
    if (_userData != null && _userData!['avatar'] != null && _userData!['avatar'].toString().isNotEmpty) {
      avatarUrl = _userData!['avatar'] as String;
    }
    // 檢查舊的 profileImages 欄位
    else if (_userData != null && _userData!['profileImages'] != null) {
      final profileImages = _userData!['profileImages'] as List<dynamic>?;
      if (profileImages != null && profileImages.isNotEmpty) {
        avatarUrl = profileImages.first as String;
      }
    }
    
    if (avatarUrl != null) {
      return Image.network(
        avatarUrl,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary900),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('載入個人照片失敗: $error');
          return _buildDefaultAvatar();
        },
      );
    }
    
    // 沒有照片時顯示預設頭像
    return _buildDefaultAvatar();
  }

  /// 構建預設頭像
  Widget _buildDefaultAvatar() {
    return Container(
      width: 100,
      height: 100,
      color: AppColors.primary100,
      child: Icon(
        Icons.person,
        size: 50,
        color: AppColors.primary900,
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


  /// 構建 KYC 狀態徽章
  Widget _buildKycStatusBadge() {
    // 企業帳號和個人帳號都根據 KYC 狀態顯示
    switch (_kycStatus) {
      case 'approved':
        return _buildSvgStatusBadge(
          text: '身份已認證',
          svgPath: 'assets/images/kyc_success.svg',
          onTap: null,
        );
      
      case 'pending':
        return _buildSvgStatusBadge(
          text: '平台審核中',
          svgPath: 'assets/images/kyc_pending.svg',
          onTap: null,
        );
      
      case 'rejected':
        return _buildSvgStatusBadge(
          text: '審核未通過',
          svgPath: 'assets/images/kyc_error.svg',
          onTap: _navigateToKyc,
        );
      
      default:
        return _buildSvgStatusBadge(
          text: '尚未認證',
          svgPath: 'assets/images/kyc_error.svg',
          onTap: _accountType == 'business' ? null : _navigateToKyc, // 企業帳號不能進入個人 KYC 流程
        );
    }
  }

  /// 構建 SVG 狀態徽章的方法
  Widget _buildSvgStatusBadge({
    required String text,
    required String svgPath,
    VoidCallback? onTap,
  }) {
    final badge = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          svgPath,
          width: 16,
          height: 16,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Colors.grey,
          ),
        ),
        if (onTap != null) ...[
          const SizedBox(width: 4),
          const Icon(
            Icons.arrow_forward_ios,
            size: 12,
            color: Colors.grey,
          ),
        ],
      ],
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: badge,
      );
    }

    return badge;
  }


  /// 導向 KYC 認證頁面
  Future<void> _navigateToKyc() async {
    try {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => const KycPage(fromRegistration: false),
        ),
      );

      if (result == true) {
        // KYC 完成，重新載入用戶資料
        await _refreshUserData();
        if (mounted) {
          CustomSnackBar.showSuccess(
            context,
            message: 'KYC 認證已提交，等待審核',
          );
        }
      }
    } catch (e) {
      debugPrint('導向 KYC 頁面失敗: $e');
      if (mounted) {
        CustomSnackBar.showError(
          context,
          message: '無法開啟 KYC 認證頁面',
        );
      }
    }
  }

  /// 顯示用戶資料卡片彈窗
  void _showUserProfilePopup() {
    if (_currentUser == null) return;
    
    // 獲取頭像URL（使用與個人資料頁面相同的邏輯）
    String? avatarUrl = _getAvatarUrl();
    
    // 準備用戶數據
    final userData = <String, dynamic>{
      'id': _currentUser!.uid,
      'name': _userData?['name'] ?? _currentUser!.email?.split('@')[0] ?? '用戶',
      'avatar': avatarUrl,
      'status': _userData?['status'] ?? 'pending',
      'kycStatus': _kycStatus,
      'accountType': _accountType,
      'rating': _userData?['rating']?.toString() ?? '5.0',
      'participantRating': _userData?['participantRating'] ?? 5.0,
      'participantRatingCount': _userData?['participantRatingCount'] ?? 0,
    };
    
    UserProfilePopupBuilder.show(
      context,
      userId: _currentUser!.uid,
      initialUserData: userData,
    );
  }

  /// 獲取頭像URL（與個人資料頁面使用相同邏輯）
  String? _getAvatarUrl() {
    // 優先檢查新的 avatar 欄位
    if (_userData != null && _userData!['avatar'] != null && _userData!['avatar'].toString().isNotEmpty) {
      return _userData!['avatar'] as String;
    }
    // 檢查舊的 profileImages 欄位
    else if (_userData != null && _userData!['profileImages'] != null) {
      final profileImages = _userData!['profileImages'] as List<dynamic>?;
      if (profileImages != null && profileImages.isNotEmpty) {
        return profileImages.first as String;
      }
    }
    return null;
  }
}
