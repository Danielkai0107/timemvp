import 'package:flutter/material.dart';
import '../components/design_system/custom_text_input.dart';
import '../components/design_system/custom_button.dart';
import '../components/design_system/terms_popup.dart';
import '../services/auth_service.dart';
import 'registration_page.dart';
import 'home.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _agreeToTerms = false;
  double _previousViewInsetsBottom = 0;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    
    // 監聽 Tab 切換事件
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          // 重新構建 UI 以反映 Tab 變化
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
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
        _showErrorDialog('登入失敗：無法獲取用戶資訊');
      }
    } catch (e) {
      debugPrint('登入錯誤: $e');
      _showErrorDialog(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 忘記密碼
  Future<void> _resetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      _showErrorDialog('請先輸入電子信箱');
      return;
    }
    
    if (!_emailController.text.contains('@')) {
      _showErrorDialog('請輸入有效的電子信箱格式');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('重設密碼郵件已發送，請檢查您的信箱'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _validateInputs() {
    if (_emailController.text.trim().isEmpty) {
      _showErrorDialog('請輸入電子信箱');
      return false;
    }
    if (!_emailController.text.contains('@')) {
      _showErrorDialog('請輸入有效的電子信箱格式');
      return false;
    }
    if (_passwordController.text.isEmpty) {
      _showErrorDialog('請輸入密碼');
      return false;
    }
    if (!_agreeToTerms) {
      _showErrorDialog('請同意服務條款');
      return false;
    }
    return true;
  }


  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('錯誤'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('確定'),
          ),
        ],
      ),
    );
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
      backgroundColor: Colors.white,
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
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              // 個人/企業選項卡
              SizedBox(
                height: 48,
                child: TabBar(
                  controller: _tabController,
                  splashFactory: NoSplash.splashFactory, // 移除點擊水波紋效果
                  overlayColor: WidgetStateProperty.all(Colors.transparent), // 移除點擊背景色
                  padding: EdgeInsets.zero, // 移除TabBar的左右padding
                  labelPadding: EdgeInsets.zero, // 移除每個Tab的padding
                  dividerColor: Colors.grey[300],
                  indicator: const UnderlineTabIndicator(
                    borderSide: BorderSide(
                      color: Colors.black,
                      width: 2.0,
                    ),
                    insets: EdgeInsets.zero, // 移除內邊距，讓底線橫跨整個選項卡
                  ),
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                  ),
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_outline_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('個人'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.work_outline_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('企業'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 表單內容區域
              Column(
                children: [
                      // 電子信箱輸入框
                      CustomTextInput(
                        label: _tabController.index == 0 ? '電子信箱' : '企業電子信箱',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onChanged: (value) {
                          // 可以在這裡添加驗證邏輯
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 密碼輸入框
                      CustomTextInput(
                        label: '密碼',
                        controller: _passwordController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onChanged: (value) {
                          // 可以在這裡添加驗證邏輯
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
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
                              activeColor: const Color(0xFFFFBE0A),
                              side: BorderSide(color: Colors.grey, width: 1.5),
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
                                color: Colors.grey,
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
                                color: Colors.grey,
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
                              color: Colors.grey,
                              letterSpacing: 0.26,
                            ),
                          ),
                          const SizedBox(width: 6),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => RegistrationPage(
                                    isBusinessRegistration: _tabController.index == 1,
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
                                color: Colors.grey,
                                letterSpacing: 0.26,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // 登入按鈕
                      ButtonBuilder.primary(
                        onPressed: _agreeToTerms ? _signInWithEmailPassword : null,
                        text: '登入',
                        width: double.infinity,
                        isLoading: _isLoading,
                        isEnabled: _agreeToTerms && !_isLoading,
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
                                });
                              },
                              activeColor: const Color(0xFFFFBE0A),
                              side: BorderSide(color: Colors.grey, width: 1.5),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _agreeToTerms = !_agreeToTerms;
                              });
                            },
                            child: const Text(
                              '我同意',
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey,
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
                                color: Color(0xFFFFBE0A),
                                decoration: TextDecoration.underline,
                                decorationColor: Color(0xFFFFBE0A),
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
                              color: Colors.grey,
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
                                color: Color(0xFFFFBE0A),
                                decoration: TextDecoration.underline,
                                decorationColor: Color(0xFFFFBE0A),
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

