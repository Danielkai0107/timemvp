import 'package:flutter/material.dart';
import '../components/design_system/custom_text_input.dart';
import '../components/design_system/custom_button.dart';
import '../components/design_system/terms_popup.dart';
import '../components/design_system/app_colors.dart';
import '../services/auth_service.dart';
import 'registration_page.dart';
import 'home.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> with WidgetsBindingObserver {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _agreeToTerms = false;
  double _previousViewInsetsBottom = 0;
  String? _emailError;
  String? _passwordError;
  String? _generalError;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    
    final currentViewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    
    // 檢查鍵盤是否從顯示變為隱藏
    if (_previousViewInsetsBottom > 0 && currentViewInsetsBottom == 0) {
      // 鍵盤隱藏時取消所有焦點
      FocusScope.of(context).unfocus();
    }
    
    _previousViewInsetsBottom = currentViewInsetsBottom;
  }

  // 處理登入按鈕點擊
  void _handleLoginButtonPressed() {
    if (!_agreeToTerms) {
      // 如果沒有同意服務條款，顯示提示對話框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('提示'),
          content: const Text('請先勾選並同意服務條款及隱私權政策。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('確定'),
            ),
          ],
        ),
      );
      return;
    }
    
    // 如果已同意條款，執行登入
    _signInWithEmailPassword();
  }

  // Firebase Email/Password 登入
  Future<void> _signInWithEmailPassword() async {
    if (!_validateInputs()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final user = await _authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (user != null) {
        debugPrint('登入成功: ${user.email}');
        _onLoginSuccess();
      } else {
        setState(() {
          _generalError = '登入失敗：無法獲取用戶資訊';
        });
      }
    } catch (e) {
      debugPrint('登入錯誤: $e');
      _handleLoginError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleLoginError(String error) {
    setState(() {
      // 清除之前的錯誤訊息
      _emailError = null;
      _passwordError = null;
      _generalError = null;
      
      // 根據錯誤類型設置相對應的錯誤訊息
      if (error.contains('密碼錯誤') || error.contains('wrong-password')) {
        _passwordError = '密碼錯誤';
      } else if (error.contains('找不到此用戶帳號') || error.contains('user-not-found')) {
        _emailError = '找不到此用戶帳號';
      } else if (error.contains('電子郵件格式錯誤') || error.contains('invalid-email')) {
        _emailError = '電子郵件格式錯誤';
      } else if (error.contains('此帳號已被停用') || error.contains('user-disabled')) {
        _generalError = '此帳號已被停用';
      } else if (error.contains('嘗試次數過多') || error.contains('too-many-requests')) {
        _generalError = '嘗試次數過多，請稍後再試';
      } else {
        _generalError = '登入失敗：$error';
      }
    });
  }

  // 忘記密碼
  Future<void> _resetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _emailError = '請先輸入電子信箱';
      });
      return;
    }
    
    if (!_emailController.text.contains('@')) {
      setState(() {
        _emailError = '請輸入有效的電子信箱格式';
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('重設密碼郵件已發送，請檢查您的信箱'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _handlePasswordResetError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handlePasswordResetError(String error) {
    setState(() {
      _generalError = null;
      _passwordError = null;
      
      if (error.contains('找不到此電子郵件帳號') || error.contains('user-not-found')) {
        _emailError = '找不到此電子郵件帳號';
      } else if (error.contains('電子郵件格式錯誤') || error.contains('invalid-email')) {
        _emailError = '電子郵件格式錯誤';
      } else {
        _emailError = '發送失敗：$error';
      }
    });
  }

  bool _validateInputs() {
    bool isValid = true;
    
    // 清除之前的錯誤訊息
    setState(() {
      _emailError = null;
      _passwordError = null;
      _generalError = null;
    });
    
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _emailError = '請輸入電子信箱';
      });
      isValid = false;
    } else if (!_emailController.text.contains('@')) {
      setState(() {
        _emailError = '請輸入有效的電子信箱格式';
      });
      isValid = false;
    }
    
    if (_passwordController.text.isEmpty) {
      setState(() {
        _passwordError = '請輸入密碼';
      });
      isValid = false;
    }
    
    return isValid;
  }


  void _onLoginSuccess() {
    // 導航到首頁
    final user = _authService.currentUser;
    final email = user?.email ?? user?.uid ?? '未知用戶';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('登入成功！歡迎 $email'),
        backgroundColor: Colors.green,
      ),
    );
    
    debugPrint('登入成功，當前用戶: $email');
    
    // 導航到首頁
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      resizeToAvoidBottomInset: true, // 自動調整以避免鍵盤遮擋
      body: GestureDetector(
        onTap: () {
          // 點擊空白區域時取消所有輸入框的焦點
          FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.opaque, // 確保能夠接收到點擊事件
        child: SafeArea(
          child: Padding(
          padding: const EdgeInsets.only(
            left: 24.0,
            right: 24.0,
            bottom: 40.0,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
              // Logo
              Container(
                width: 200,
                height: 95,
                margin: const EdgeInsets.only(bottom: 40),
                decoration: BoxDecoration(
                  // color: const Color(0xFFFFBE0A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 200,
                    height: 95,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // 如果找不到圖片，顯示預設文字
                      return const Text(
                        'TiMe',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              
              // 表單內容區域
              Column(
                children: [
                      // 電子信箱輸入框
                      CustomTextInput(
                        label: '電子信箱',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        errorText: _emailError,
                        onChanged: (value) {
                          if (_emailError != null) {
                            setState(() {
                              _emailError = null;
                            });
                          }
                        },
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // 密碼輸入框
                      CustomTextInput(
                        label: '密碼',
                        controller: _passwordController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        errorText: _passwordError,
                        onChanged: (value) {
                          if (_passwordError != null) {
                            setState(() {
                              _passwordError = null;
                            });
                          }
                        },
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // 記住我 & 其他選項
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Transform.scale(
                            scale: 0.9,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                              activeColor: AppColors.primary900,
                              side: BorderSide(color: AppColors.border, width: 1.5),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _rememberMe = !_rememberMe;
                              });
                            },
                            child: const Text(
                              '記住我',
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.26,
                              ),
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _resetPassword,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              overlayColor: Colors.transparent,
                            ),
                            child: const Text(
                              '忘記密碼',
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.26,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            ' | ',
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.6,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.26,
                            ),
                          ),
                          const SizedBox(width: 6),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const RegistrationPage(
                                    isBusinessRegistration: false,
                                  ),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              overlayColor: Colors.transparent,
                            ),
                            child: const Text(
                              '創建帳戶',
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.26,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // 通用錯誤訊息區域（始終預留空間）
                      Container(
                        width: double.infinity,
                        height: _generalError != null ? null : 0, // 沒有錯誤時高度為0
                        margin: const EdgeInsets.only(bottom: 16),
                        child: _generalError != null 
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.error100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.error300),
                              ),
                              child: Text(
                                _generalError!,
                                style: const TextStyle(
                                  color: AppColors.error900,
                                  fontSize: 14,
                                ),
                              ),
                            )
                          : null, // 沒有錯誤時不顯示內容，但保持容器結構
                      ),
                      
                      // 登入按鈕
                      ButtonBuilder.primary(
                        onPressed: _handleLoginButtonPressed,
                        text: '登入',
                        width: double.infinity,
                        isLoading: _isLoading,
                        isEnabled: !_isLoading,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 同意條款
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Transform.scale(
                            scale: 0.9,
                            child: Checkbox(
                              value: _agreeToTerms,
                              onChanged: (value) {
                                setState(() {
                                  _agreeToTerms = value ?? false;
                                  if (_generalError != null) {
                                    _generalError = null;
                                  }
                                });
                              },
                              activeColor: AppColors.primary900,
                              side: BorderSide(color: AppColors.border, width: 1.5),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _agreeToTerms = !_agreeToTerms;
                                if (_generalError != null) {
                                  _generalError = null;
                                }
                              });
                            },
                            child: const Text(
                              '我同意',
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.26,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              TermsPopupBuilder.showTermsOfService(context);
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              overlayColor: Colors.transparent,
                            ),
                            child: const Text(
                              '服務條款',
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                fontWeight: FontWeight.w400,
                                color: AppColors.primary900,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.primary900,
                                letterSpacing: 0.26,
                              ),
                            ),
                          ),
                          const Text(
                            '、',
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.6,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.26,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              TermsPopupBuilder.showPrivacyPolicy(context);
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              overlayColor: Colors.transparent,
                            ),
                            child: const Text(
                              '隱私權政策',
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                fontWeight: FontWeight.w400,
                                color: AppColors.primary900,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.primary900,
                                letterSpacing: 0.26,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // 增加底部間距
                      const SizedBox(height: 60),
                    ],
                  ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        ),
      ),
    );
  }
}

