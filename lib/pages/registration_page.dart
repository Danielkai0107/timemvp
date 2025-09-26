import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../components/design_system/custom_text_input.dart';
import '../components/design_system/custom_dropdown.dart';
import '../components/design_system/custom_button.dart';
import '../components/design_system/step_indicator.dart';
import '../components/design_system/photo_upload.dart';
import '../components/design_system/app_colors.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/firestore_test.dart';
import 'kyc_page.dart';
import 'home.dart';

/// 註冊頁面
class RegistrationPage extends StatefulWidget {
  final bool isBusinessRegistration;
  
  const RegistrationPage({
    super.key, 
    this.isBusinessRegistration = false,
  });

  @override
  RegistrationPageState createState() => RegistrationPageState();
}

class RegistrationPageState extends State<RegistrationPage> {
  final PageController _pageController = PageController();
  int _currentStep = 1;
  
  // 服務實例
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  
  // 動態計算總步驟數
  int get _totalSteps {
    if (_selectedAccountType == 'business') {
      return 9; // 企業帳戶流程：帳戶類型 → 聯絡人 → 企業資料 → 4個文件 → 密碼 → 完成頁面
    } else {
      return 5; // 個人帳戶流程：帳戶類型 → 基本資料 → 密碼 → 相片 → 實名制認證
    }
  }

  // 步驟一：帳戶類型選擇
  String? _selectedAccountType;

  // 個人帳戶資料
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  String? _selectedGender;
  int? _selectedAge;
  List<String> _uploadedPhotos = [];
  String? _emailError;

  // 企業帳戶資料
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _companyPhoneController = TextEditingController();
  final TextEditingController _companyAddressController = TextEditingController();
  final TextEditingController _taxIdController = TextEditingController();
  final TextEditingController _companyEmailController = TextEditingController();
  final TextEditingController _accountHolderController = TextEditingController();
  final TextEditingController _bankCodeController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  
  // 企業文件上傳
  List<String> _businessRegistrationDocs = [];
  List<String> _bankBookCover = [];
  List<String> _idCardFront = [];
  List<String> _idCardBack = [];
  String? _contactEmailError;
  String? _companyEmailError;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 根據傳入的參數設置初始帳戶類型
    if (widget.isBusinessRegistration) {
      _selectedAccountType = 'business';
    } else {
      _selectedAccountType = 'personal';
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    
    // 個人帳戶控制器
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    
    // 企業帳戶控制器
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    _companyNameController.dispose();
    _companyPhoneController.dispose();
    _companyAddressController.dispose();
    _taxIdController.dispose();
    _companyEmailController.dispose();
    _accountHolderController.dispose();
    _bankCodeController.dispose();
    _accountNumberController.dispose();
    
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps) {
      // 自動關閉鍵盤
      FocusScope.of(context).unfocus();
      
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 1) {
      // 自動關閉鍵盤
      FocusScope.of(context).unfocus();
      
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _canProceedFromStep1() {
    return _selectedAccountType != null;
  }

  bool _canProceedFromStep2() {
    return _nameController.text.trim().isNotEmpty &&
           _selectedGender != null &&
           _selectedAge != null &&
           _emailController.text.trim().isNotEmpty &&
           _emailController.text.contains('@');
  }


  bool _canProceedFromStep3() {
    return _passwordController.text.length >= 6 &&
           _passwordController.text == _confirmPasswordController.text;
  }

  bool _canProceedFromStep4() {
    debugPrint('=== 檢查步驟4是否可以繼續 ===');
    debugPrint('當前 _uploadedPhotos 數量: ${_uploadedPhotos.length}');
    debugPrint('_uploadedPhotos 內容: $_uploadedPhotos');
    final canProceed = _uploadedPhotos.isNotEmpty;
    debugPrint('步驟4可以繼續: $canProceed');
    
    // 暫時允許跳過圖片上傳來測試
    return true; // 原本是: _uploadedPhotos.isNotEmpty;
  }

  // 企業註冊步驟驗證
  bool _canProceedFromBusinessContactStep() {
    return _contactNameController.text.trim().isNotEmpty &&
           _contactPhoneController.text.trim().isNotEmpty &&
           _contactEmailController.text.trim().isNotEmpty &&
           _contactEmailController.text.contains('@');
  }


  bool _canProceedFromBusinessInfoStep() {
    return _companyNameController.text.trim().isNotEmpty &&
           _companyPhoneController.text.trim().isNotEmpty &&
           _companyAddressController.text.trim().isNotEmpty &&
           _taxIdController.text.trim().isNotEmpty &&
           _companyEmailController.text.trim().isNotEmpty &&
           _companyEmailController.text.contains('@');
  }

  bool _canProceedFromBusinessRegistrationStep() {
    return _businessRegistrationDocs.isNotEmpty;
  }

  bool _canProceedFromBankBookStep() {
    return _accountHolderController.text.trim().isNotEmpty &&
           _bankCodeController.text.trim().isNotEmpty &&
           _accountNumberController.text.trim().isNotEmpty &&
           _bankBookCover.isNotEmpty;
  }

  bool _canProceedFromIdCardFrontStep() {
    return _idCardFront.isNotEmpty;
  }

  bool _canProceedFromIdCardBackStep() {
    return _idCardBack.isNotEmpty;
  }

  // 動態獲取 PageView 的子頁面
  List<Widget> _getPageViewChildren() {
    if (_selectedAccountType == 'business') {
      // 企業帳戶流程：9步
      return [
        _buildStep1(), // 1. 帳戶類型選擇
        _buildBusinessContactStep(), // 2. 主要聯絡人資料
        _buildBusinessInfoStep(), // 3. 企業資料
        _buildBusinessRegistrationStep(), // 4. 商業登記書
        _buildBankBookStep(), // 5. 帳戶存摺封面
        _buildIdCardFrontStep(), // 6. 身分證正面
        _buildIdCardBackStep(), // 7. 身分證背面
        _buildStep3(), // 8. 密碼設定
        _buildBusinessCompletionStep(), // 9. 完成頁面
      ];
    } else {
      // 個人帳戶流程：5步
      return [
        _buildStep1(), // 1. 帳戶類型選擇
        _buildStep2(), // 2. 基本資料
        _buildStep3(), // 3. 密碼設定
        _buildStep4(), // 4. 相片上傳
        _buildStep5(), // 5. 實名制認證
      ];
    }
  }

  /// 跳過認證，直接登入
  Future<void> _skipVerificationAndLogin() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 先創建 Firebase 帳戶
      await _authService.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      
      // 準備基本註冊資料（不含 KYC）
      final registrationData = {
        'accountType': _selectedAccountType,
        'name': _nameController.text,
        'email': _emailController.text,
        'gender': _selectedGender,
        'age': _selectedAge,
        'password': _passwordController.text,
        'photos': _uploadedPhotos,
        'isVerified': false, // 未認證
      };

      // 如果是企業帳戶，添加企業相關資料
      if (_selectedAccountType == 'business') {
        registrationData.addAll({
          'contactName': _contactNameController.text,
          'contactPhone': _contactPhoneController.text,
          'contactEmail': _contactEmailController.text,
          'companyName': _companyNameController.text,
          'companyPhone': _companyPhoneController.text,
          'companyAddress': _companyAddressController.text,
          'companyTaxId': _taxIdController.text,
          'businessRegistrationDocs': _businessRegistrationDocs,
          'bankBookCover': _bankBookCover,
          'idCardFrontDocs': _idCardFront,
          'idCardBackDocs': _idCardBack,
        });
      }
      
      // 保存用戶資料
      final user = _authService.currentUser;
      if (user != null) {
        await _userService.createUser(user.uid, registrationData);
        debugPrint('註冊資料保存成功（未認證）');
      }

      if (mounted) {
        // 顯示成功訊息
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('註冊成功！歡迎使用 TimeApp'),
            backgroundColor: AppColors.success900,
          ),
        );
        
        // 導向首頁
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('跳過認證註冊失敗: $e');
      
      if (mounted) {
        if (e.toString().contains('email-already-in-use') || 
            e.toString().contains('此電子郵件已被註冊')) {
          
          // 設置 email 錯誤訊息
          setState(() {
            _emailError = '此電子郵件已被註冊';
          });
          
          // 返回到第2步（填寫個人資料，包含 email）
          setState(() {
            _currentStep = 2;
          });
          
          _pageController.animateToPage(
            1, // 第2步的 index (0-based)
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          
          // 顯示提示訊息
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('此電子郵件已被註冊，請修改電子郵件或前往登入'),
              backgroundColor: AppColors.error900,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('註冊失敗: $e'),
              backgroundColor: AppColors.error900,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _goToVerification() async {
    if (!mounted) return;
    
    // 顯示載入狀態
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 先檢查 email 是否已被使用（透過嘗試創建帳戶）
      debugPrint('檢查 email 是否已被使用: ${_emailController.text}');
      
      await _authService.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      
      debugPrint('帳戶創建成功，可以進入 KYC 流程');
      
      // 準備註冊資料傳給 KYC 頁面
      final registrationData = {
        'accountType': _selectedAccountType,
        'name': _nameController.text,
        'email': _emailController.text,
        'gender': _selectedGender,
        'age': _selectedAge,
        'password': _passwordController.text,
        'photos': _uploadedPhotos,
        'isVerified': false, // KYC 完成後會更新為 true
      };

      // 如果是企業帳戶，添加企業相關資料
      if (_selectedAccountType == 'business') {
        registrationData.addAll({
          'contactName': _contactNameController.text,
          'contactPhone': _contactPhoneController.text,
          'contactEmail': _contactEmailController.text,
          'companyName': _companyNameController.text,
          'companyPhone': _companyPhoneController.text,
          'companyAddress': _companyAddressController.text,
          'companyTaxId': _taxIdController.text,
          'businessRegistrationDocs': _businessRegistrationDocs,
          'bankBookCover': _bankBookCover,
          'idCardFrontDocs': _idCardFront,
          'idCardBackDocs': _idCardBack,
        });
      }
      
      if (mounted) {
        // 導向 KYC 頁面
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => KycPage(
              fromRegistration: true,
              registrationData: registrationData,
            ),
          ),
        );
        
        // 如果 KYC 完成，關閉註冊頁面
        if (result == true && mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      debugPrint('進入 KYC 前的驗證失敗: $e');
      
      if (mounted) {
        // 檢查是否是 email 已被使用的錯誤
        if (e.toString().contains('email-already-in-use') || 
            e.toString().contains('此電子郵件已被註冊')) {
          
          // 設置 email 錯誤訊息
          setState(() {
            _emailError = '此電子郵件已被註冊';
          });
          
          // 返回到第2步（填寫個人資料，包含 email）
          setState(() {
            _currentStep = 2;
          });
          
          _pageController.animateToPage(
            1, // 第2步的 index (0-based)
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          
          // 顯示提示訊息
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('此電子郵件已被註冊，請修改電子郵件或前往登入'),
              backgroundColor: AppColors.error900,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          // 其他錯誤
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('驗證失敗: $e'),
              backgroundColor: AppColors.error900,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  Future<void> _saveUserData({required bool isVerified}) async {
    debugPrint('=== 開始註冊流程 ===');
    debugPrint('帳戶類型: $_selectedAccountType');
    debugPrint('個人相片數量: ${_uploadedPhotos.length}');
    debugPrint('個人相片路徑: $_uploadedPhotos');
    debugPrint('企業文件 - 商業登記書: ${_businessRegistrationDocs.length}');
    debugPrint('企業文件 - 存摺封面: ${_bankBookCover.length}');
    debugPrint('企業文件 - 身分證正面: ${_idCardFront.length}');
    debugPrint('企業文件 - 身分證背面: ${_idCardBack.length}');
    
    try {
      // 顯示載入指示器
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // 準備註冊資料
      String email;
      String password = _passwordController.text;
      
      if (_selectedAccountType == 'business') {
        // 企業帳戶使用企業電子信箱
        email = _companyEmailController.text.trim();
      } else {
        // 個人帳戶使用一般電子信箱
        email = _emailController.text.trim();
      }
      
      // 創建 Firebase 用戶帳戶
      AuthUser? user;
      try {
        user = await _authService.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        if (user == null) {
          throw Exception('帳戶創建失敗');
        }
      } catch (e) {
        // 檢查是否為電子郵件已被使用的錯誤
        if (e.toString().contains('email-already-in-use') || 
            e.toString().contains('此電子郵件已被註冊')) {
          debugPrint('檢測到重複電子郵件錯誤: $e');
          
          // 關閉載入指示器
          if (mounted) {
            Navigator.of(context).pop();
            
            // 等待一小段時間確保對話框完全關閉
            await Future.delayed(const Duration(milliseconds: 100));
            
            // 設置錯誤訊息
            if (mounted) {
              setState(() {
                if (_selectedAccountType == 'business') {
                  // 企業帳戶的錯誤顯示在企業電子信箱欄位
                  _companyEmailError = '此電子郵件已被註冊';
                } else {
                  _emailError = '此電子郵件已被註冊';
                }
              });
            }
            
            // 顯示錯誤對話框而不是嘗試導航
            showDialog(
              context: context,
              barrierDismissible: false, // 禁止點擊遮罩關閉對話框
              builder: (context) => AlertDialog(
                title: const Text('電子郵件已被註冊'),
                content: const Text('此電子郵件已被其他用戶註冊，請使用其他電子郵件地址。'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // 導航回到對應的電子郵件輸入步驟
                      if (mounted) {
                        final targetStep = _selectedAccountType == 'business' ? 3 : 2; // 企業帳戶回到第3步（企業資料），個人帳戶回到第2步（基本資料）
                        setState(() {
                          _currentStep = targetStep;
                        });
                        _pageController.animateToPage(
                          _currentStep - 1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: const Text('確定'),
                  ),
                ],
              ),
            );
            
            debugPrint('已設置電子郵件錯誤訊息');
          }
          return;
        } else {
          // 其他錯誤，重新拋出
          rethrow;
        }
      }
      
      debugPrint('用戶創建成功: ${user.uid}');

      // 等待一小段時間讓Firebase Auth狀態穩定
      await Future.delayed(const Duration(milliseconds: 500));

      // 測試Firestore連接和權限
      debugPrint('開始測試Firestore連接...');
      await FirestoreTestService.checkFirestoreRules();
      final canWriteToFirestore = await FirestoreTestService.testFirestoreWrite();
      debugPrint('Firestore寫入測試結果: $canWriteToFirestore');

      // 準備用戶資料
      final userData = <String, dynamic>{
        'accountType': _selectedAccountType ?? 'personal',
        'isVerified': isVerified,
      };

      // 根據帳戶類型添加不同的資料
      if (_selectedAccountType == 'business') {
        userData.addAll({
          'contactName': _contactNameController.text.trim(),
          'contactPhone': _contactPhoneController.text.trim(),
          'contactEmail': _contactEmailController.text.trim(),
          'companyName': _companyNameController.text.trim(),
          'companyPhone': _companyPhoneController.text.trim(),
          'companyAddress': _companyAddressController.text.trim(),
          'taxId': _taxIdController.text.trim(),
          'companyEmail': _companyEmailController.text.trim(),
          'accountHolder': _accountHolderController.text.trim(),
          'bankCode': _bankCodeController.text.trim(),
          'accountNumber': _accountNumberController.text.trim(),
        });

        // 上傳企業文件
        debugPrint('準備上傳企業文件...');
        if (_businessRegistrationDocs.isNotEmpty) {
          try {
            debugPrint('上傳商業登記書: $_businessRegistrationDocs');
            final docs = await _userService.uploadFiles(
              filePaths: _businessRegistrationDocs,
              folderName: 'business_registration',
              uid: user.uid,
            );
            userData['businessRegistrationDocs'] = docs;
            debugPrint('商業登記書上傳成功: $docs');
          } catch (e) {
            debugPrint('商業登記書上傳失敗: $e');
            userData['businessRegistrationDocs'] = <String>[];
          }
        }
        if (_bankBookCover.isNotEmpty) {
          try {
            debugPrint('上傳存摺封面: $_bankBookCover');
            final docs = await _userService.uploadFiles(
              filePaths: _bankBookCover,
              folderName: 'bank_book',
              uid: user.uid,
            );
            userData['bankBookCover'] = docs;
            debugPrint('存摺封面上傳成功: $docs');
          } catch (e) {
            debugPrint('存摺封面上傳失敗: $e');
            userData['bankBookCover'] = <String>[];
          }
        }
        if (_idCardFront.isNotEmpty) {
          try {
            debugPrint('上傳身分證正面: $_idCardFront');
            final docs = await _userService.uploadFiles(
              filePaths: _idCardFront,
              folderName: 'id_card_front',
              uid: user.uid,
            );
            userData['idCardFront'] = docs;
            debugPrint('身分證正面上傳成功: $docs');
          } catch (e) {
            debugPrint('身分證正面上傳失敗: $e');
            userData['idCardFront'] = <String>[];
          }
        }
        if (_idCardBack.isNotEmpty) {
          try {
            debugPrint('上傳身分證背面: $_idCardBack');
            final docs = await _userService.uploadFiles(
              filePaths: _idCardBack,
              folderName: 'id_card_back',
              uid: user.uid,
            );
            userData['idCardBack'] = docs;
            debugPrint('身分證背面上傳成功: $docs');
          } catch (e) {
            debugPrint('身分證背面上傳失敗: $e');
            userData['idCardBack'] = <String>[];
          }
        }
      } else {
        // 個人帳戶資料
        userData.addAll({
          'name': _nameController.text.trim(),
          'gender': _selectedGender ?? '',
          'age': _selectedAge ?? 0,
        });

        // 上傳個人相片
        debugPrint('準備上傳個人相片，數量: ${_uploadedPhotos.length}');
        if (_uploadedPhotos.isNotEmpty) {
          try {
            debugPrint('開始上傳個人相片: $_uploadedPhotos');
            final photos = await _userService.uploadFiles(
              filePaths: _uploadedPhotos,
              folderName: 'profile_images',
              uid: user.uid,
            );
            userData['profileImages'] = photos;
            debugPrint('個人相片上傳成功，URLs: $photos');
          } catch (e) {
            debugPrint('個人相片上傳失敗: $e');
            userData['profileImages'] = <String>[];
            // 繼續流程，但記錄錯誤
          }
        } else {
          userData['profileImages'] = <String>[];
          debugPrint('沒有個人相片需要上傳');
        }
      }

      // 創建用戶資料文檔
      try {
        await _userService.createUserDocument(
          uid: user.uid,
          email: user.email!,
          userData: userData,
        );
        debugPrint('用戶資料保存成功');
      } catch (e) {
        debugPrint('保存用戶資料時發生錯誤: $e');
        // 即使保存失敗，也繼續流程，讓用戶知道註冊成功但可能需要重新登入
      }

      // 等待一段時間確保所有操作完成
      await Future.delayed(const Duration(milliseconds: 300));

      // 關閉載入指示器
      if (mounted) {
        Navigator.of(context).pop();

        if (_selectedAccountType == 'business') {
          // 企業註冊：進入第9步完成頁面
          setState(() {
            _currentStep = 9;
          });
          
          _pageController.animateToPage(
            8, // 第9步的 index (0-based)
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          
          // 顯示成功訊息
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('企業註冊資料提交成功，等待審核'),
              backgroundColor: AppColors.success900,
            ),
          );
        } else {
          // 個人註冊：顯示對話框（保持原有邏輯）
          showDialog(
            context: context,
            barrierDismissible: false, // 禁止點擊遮罩關閉對話框
            builder: (context) => AlertDialog(
              title: const Text('註冊完成'),
              content: const Text('註冊成功！請使用您的電子郵件和密碼登入。'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(); // 返回登入頁面
                  },
                  child: const Text('確定'),
                ),
              ],
            ),
          );
        }
      }

    } catch (e) {
      // 關閉載入指示器
      if (mounted) {
        Navigator.of(context).pop();
        
        debugPrint('註冊過程中發生錯誤: $e');
        
        // 顯示錯誤訊息
        showDialog(
          context: context,
          barrierDismissible: false, // 禁止點擊遮罩關閉對話框
          builder: (context) => AlertDialog(
            title: const Text('註冊失敗'),
            content: Text('發生錯誤：$e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('確定'),
              ),
            ],
          ),
        );
      }
    }
  }

  // 企業註冊完成頁面
  Widget _buildBusinessCompletionStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題
          const Text(
            '恭喜你完成申請！',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 副標題
          const Text(
            '審核通過後，我們會通知你',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // 詳細說明文字
          const Text(
            '我們會在 3-7 天內發送 Email 通知，說明你是否通過驗證，這是需要請你提供更多資料。',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          
          const Spacer(),
          
          // 前往登入按鈕
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _businessCompletionAndLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary900,
                foregroundColor: AppColors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '前往登入',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /// 企業註冊完成並進入首頁
  Future<void> _businessCompletionAndLogin() async {
    if (!mounted) return;
    
    // 直接進入首頁（用戶已經登入狀態）
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomePage()),
      (route) => false,
    );
  }

  // 企業文件上傳區域（使用與 photo_upload 相同的 UI）
  Widget _buildDocumentUploadSlot({
    required VoidCallback onTap,
    required List<String> uploadedFiles,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 200,
        child: uploadedFiles.isEmpty
          ? CustomPaint(
              painter: DashedBorderPainter(
                color: Colors.grey,
                strokeWidth: 1.0,
                borderRadius: 12.0,
                dashWidth: 20.0,
                dashSpace: 8.0,
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    Icons.add_rounded,
                    size: 40,
                    color: Colors.grey,
                  ),
                ),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    // 顯示第一張圖片
                    Image.file(
                      File(uploadedFiles.first),
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                    // 如果有多張圖片，顯示數量
                    if (uploadedFiles.length > 1)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '+${uploadedFiles.length - 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    // 編輯按鈕
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: onTap,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  // 顯示圖片來源選擇對話框並實現真正的圖片上傳
  void _showImageSourceDialog(ValueChanged<List<String>> onPhotosChanged) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 頂部拖拽指示器
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // 標題列和關閉按鈕
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.grey100,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 32),
                  Expanded(
                    child: Center(
                      child: Text(
                        '選擇文件來源',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 20,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // 選項列表
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  // 相簿選項
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.grey100,
                          width: 1,
                        ),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      leading: const Icon(
                        Icons.photo_library_outlined,
                        color: Colors.black54,
                        size: 24,
                      ),
                      title: const Text(
                        '從相簿選擇',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        await _pickImageFromGallery(onPhotosChanged);
                      },
                    ),
                  ),
                  
                  // 拍照選項
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    leading: const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.black54,
                      size: 24,
                    ),
                    title: const Text(
                      '拍照',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await _takePhoto(onPhotosChanged);
                    },
                  ),
                ],
              ),
            ),
            
            // 添加底部安全區域間距
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  // 從相簿選擇圖片
  Future<void> _pickImageFromGallery(ValueChanged<List<String>> onPhotosChanged) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (image != null) {
        onPhotosChanged([image.path]);
      }
    } catch (e) {
      _showErrorDialog('選擇圖片失敗，請確認已授予相簿權限');
    }
  }

  // 拍照
  Future<void> _takePhoto(ValueChanged<List<String>> onPhotosChanged) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      if (image != null) {
        onPhotosChanged([image.path]);
      }
    } catch (e) {
      _showErrorDialog('拍照失敗，請確認已授予相機權限');
    }
  }

  // 顯示錯誤對話框
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false, // 禁止點擊遮罩關閉對話框
      builder: (context) => AlertDialog(
        title: const Text('錯誤'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Column(
            children: [
              // 頂部離開按鈕
              Padding(
                padding: const EdgeInsets.only(
                  left: 24.0,
                  right: 24.0,
                  top: 40.0,
                ),
                child: Row(
                  children: [
                    CustomButton(
                      onPressed: () => Navigator.of(context).pop(),
                      text: '離開',
                      width: 80,
                      style: CustomButtonStyle.info,
                      borderRadius: 30.0,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 主要內容區域
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: _getPageViewChildren(),
                ),
              ),
              
              // 底部步驟指示器（企業第9步隱藏）
              if (!(_selectedAccountType == 'business' && _currentStep == 9))
                StepIndicator(
                  currentStep: _currentStep,
                  totalSteps: _totalSteps,
                ),
              
              // 導航按鈕（企業第9步隱藏）
              if (!(_selectedAccountType == 'business' && _currentStep == 9))
                StepNavigationButtons(
                onPrevious: _currentStep > 1 ? _previousStep : null,
                onNext: _getNextStepAction(),
                onSkip: (_selectedAccountType == 'personal' && _currentStep == 5) 
                    ? _skipVerificationAndLogin : null,
                showPrevious: _currentStep > 1,
                showNext: !(_selectedAccountType == 'personal' && _currentStep == 5),
                showSkip: _selectedAccountType == 'personal' && _currentStep == 5,
                previousText: '上一步',
                nextText: _getNextButtonText(),
                skipText: '稍後認證',
                isNextEnabled: _getNextButtonEnabled(),
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題
            const Text(
              '選擇你的帳戶類型',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 說明文字
            const Text(
              '請選擇適合您的帳戶類型，這將影響您可使用的功能',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 帳戶類型選擇
            DropdownBuilder.dialog<String>(
              label: '帳戶類型',
              dialogTitle: '選擇帳戶類型',
              value: _selectedAccountType,
              onChanged: (value) {
                // 自動關閉鍵盤
                FocusScope.of(context).unfocus();
                
                if (mounted) {
                  setState(() {
                    _selectedAccountType = value;
                  });
                }
              },
              items: const [
                DropdownItem(value: 'personal', label: '個人帳戶'),
                DropdownItem(value: 'business', label: '企業帳戶'),
              ],
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題
            const Text(
              '首先，填寫個人的基本資料',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 姓名輸入框
            CustomTextInput(
              label: '姓名',
              controller: _nameController,
              onChanged: (value) {
                if (mounted) {
                  setState(() {}); // 更新按鈕狀態
                }
              },
            ),
            
            const SizedBox(height: 4),
            
            // 性別下拉選單（對話框模式）
            DropdownBuilder.dialog<String>(
              label: '性別',
              dialogTitle: '選擇性別',
              value: _selectedGender,
              onChanged: (value) {
                // 自動關閉鍵盤
                FocusScope.of(context).unfocus();
                
                if (mounted) {
                  setState(() {
                    _selectedGender = value;
                  });
                }
              },
              items: const [
                DropdownItem(value: 'male', label: '男性'),
                DropdownItem(value: 'female', label: '女性'),
                DropdownItem(value: 'other', label: '其他'),
                DropdownItem(value: 'prefer_not_to_say', label: '不願透露'),
              ],
            ),
            
            const SizedBox(height: 4),
            
            // 年齡下拉選單（對話框模式）
            DropdownBuilder.dialog<int>(
              label: '年齡',
              dialogTitle: '選擇年齡',
              value: _selectedAge,
              onChanged: (value) {
                // 自動關閉鍵盤
                FocusScope.of(context).unfocus();
                
                if (mounted) {
                  setState(() {
                    _selectedAge = value;
                  });
                }
              },
              items: List.generate(
                48, // 18-65 歲
                (index) => DropdownItem<int>(
                  value: 18 + index,
                  label: '${18 + index} 歲',
                ),
              ),
            ),
            
            const SizedBox(height: 4),
            
            // 信箱輸入框
            TextInputBuilder.email(
              controller: _emailController,
              errorText: _emailError,
              onChanged: (value) {
                if (mounted) {
                  setState(() {
                    _emailError = null; // 清除錯誤訊息當用戶輸入時
                  });
                }
              },
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題
            const Text(
              '設定你的密碼',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 說明文字
            const Text(
              '請設定一個安全的密碼，密碼長度至少需要6個字符',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 密碼輸入框
            TextInputBuilder.password(
              label: '密碼',
              controller: _passwordController,
              onChanged: (value) {
                if (mounted) {
                  setState(() {}); // 更新按鈕狀態
                }
              },
            ),
            
            const SizedBox(height: 4),
            
            // 確認密碼輸入框
            TextInputBuilder.password(
              label: '確認密碼',
              controller: _confirmPasswordController,
              errorText: _passwordController.text != _confirmPasswordController.text && 
                        _confirmPasswordController.text.isNotEmpty
                  ? '密碼不符合'
                  : null,
              onChanged: (value) {
                if (mounted) {
                  setState(() {}); // 更新按鈕狀態
                }
              },
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStep4() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題
            const Text(
              '新增幾張你的相片',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 說明文字
            const Text(
              '請上傳幾張您的相片，這將會顯示在您的個人檔案中。',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 相片上傳組件
            PhotoUploadBuilder.personal(
              onPhotosChanged: (photos) {
                setState(() {
                  _uploadedPhotos = photos;
                });
              },
              photos: _uploadedPhotos,
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStep5() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題
            const Text(
              '邀請你進行實名制認證',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 說明文字
            const Text(
              '完成身份認證，將提高 60% 媒合成功率。驗證後，即可使用平台金流服務。',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.black,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 角色卡片
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
        
                boxShadow: [
                  BoxShadow(
                    color: AppColors.grey300.withOpacity(0.7),
                    blurRadius: 12,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // 用戶頭像
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                 
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: _uploadedPhotos.isNotEmpty
                          ? Image.file(
                              File(_uploadedPhotos.first),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppColors.grey100,
                                  child: Icon(
                                    Icons.person,
                                    size: 30,
                                    color: AppColors.grey500,
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: AppColors.grey100,
                              child: Icon(
                                Icons.person,
                                size: 30,
                                color: AppColors.grey500,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // 用戶資訊
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nameController.text.isNotEmpty ? _nameController.text : '用戶',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 16,
                              color: AppColors.error900,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              '尚未認證',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.error900,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 前往認證按
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _goToVerification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success900,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                        ),
                      )
                    : const Text(
                        '前往認證',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // 企業註冊步驟：主要聯絡人資料
  Widget _buildBusinessContactStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題
            const Text(
              '首先，填寫主要聯絡人資料',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 主要聯絡人姓名
            CustomTextInput(
              label: '主要聯絡人・姓名',
              controller: _contactNameController,
              onChanged: (value) {
                if (mounted) {
                  setState(() {}); // 更新按鈕狀態
                }
              },
            ),
            
            const SizedBox(height: 4),
            
            // 主要聯絡人手機
            CustomTextInput(
              label: '主要聯絡人・手機',
              controller: _contactPhoneController,
              keyboardType: TextInputType.phone,
              onChanged: (value) {
                if (mounted) {
                  setState(() {}); // 更新按鈕狀態
                }
              },
            ),
            
            const SizedBox(height: 4),
            
            // 主要聯絡人電子信箱
            TextInputBuilder.email(
              label: '主要聯絡人・電子信箱',
              controller: _contactEmailController,
              errorText: _contactEmailError,
              onChanged: (value) {
                if (mounted) {
                  setState(() {
                    _contactEmailError = null; // 清除錯誤訊息當用戶輸入時
                  });
                }
              },
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // 企業註冊步驟：企業資料
  Widget _buildBusinessInfoStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題
            const Text(
              '接著，輸入企業資料',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 企業名稱
            CustomTextInput(
              label: '企業名稱',
              controller: _companyNameController,
              onChanged: (value) {
                if (mounted) {
                  setState(() {}); // 更新按鈕狀態
                }
              },
            ),
            
            const SizedBox(height: 4),
            
            // 聯絡電話
            CustomTextInput(
              label: '聯絡電話',
              controller: _companyPhoneController,
              keyboardType: TextInputType.phone,
              onChanged: (value) {
                if (mounted) {
                  setState(() {}); // 更新按鈕狀態
                }
              },
            ),
            
            const SizedBox(height: 4),
            
            // 營業地址
            CustomTextInput(
              label: '營業地址',
              controller: _companyAddressController,
              onChanged: (value) {
                if (mounted) {
                  setState(() {}); // 更新按鈕狀態
                }
              },
            ),
            
            const SizedBox(height: 4),
            
            // 統一編號
            CustomTextInput(
              label: '統一編號',
              controller: _taxIdController,
              keyboardType: TextInputType.number,
              onChanged: (value) {
                if (mounted) {
                  setState(() {}); // 更新按鈕狀態
                }
              },
            ),
            
            const SizedBox(height: 4),
            
            // 企業電子信箱
            TextInputBuilder.email(
              label: '企業・電子信箱',
              controller: _companyEmailController,
              errorText: _companyEmailError,
              onChanged: (value) {
                if (mounted) {
                  setState(() {
                    _companyEmailError = null; // 清除錯誤訊息當用戶輸入時
                  });
                }
              },
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  VoidCallback? _getNextStepAction() {
    if (_selectedAccountType == 'business') {
      // 企業帳戶流程：9步
      switch (_currentStep) {
        case 1: return _canProceedFromStep1() ? _nextStep : null;
        case 2: return _canProceedFromBusinessContactStep() ? _nextStep : null;
        case 3: return _canProceedFromBusinessInfoStep() ? _nextStep : null;
        case 4: return _canProceedFromBusinessRegistrationStep() ? _nextStep : null;
        case 5: return _canProceedFromBankBookStep() ? _nextStep : null;
        case 6: return _canProceedFromIdCardFrontStep() ? _nextStep : null;
        case 7: return _canProceedFromIdCardBackStep() ? _nextStep : null;
        case 8: return _canProceedFromStep3() ? () => _saveUserData(isVerified: false) : null; // 密碼設定後進入完成頁面
        case 9: return null; // 第9步有自己的按鈕
        default: return null;
      }
    } else {
      // 個人帳戶流程：5步
      switch (_currentStep) {
        case 1: return _canProceedFromStep1() ? _nextStep : null;
        case 2: return _canProceedFromStep2() ? _nextStep : null;
        case 3: return _canProceedFromStep3() ? _nextStep : null;
        case 4: return _canProceedFromStep4() ? _nextStep : null;
        case 5: return _goToVerification; // 進行認證（可選）
        default: return null;
      }
    }
  }


  String _getNextButtonText() {
    if (_selectedAccountType == 'business') {
      return _currentStep == 8 ? '提交註冊' : '下一步';
    } else {
      if (_currentStep == 5) {
        return '確認前往'; // 第5步確認進入認證流程
      } else {
        return '下一步';
      }
    }
  }

  bool _getNextButtonEnabled() {
    if (_selectedAccountType == 'business') {
      // 企業帳戶流程：9步
      switch (_currentStep) {
        case 1: return _canProceedFromStep1();
        case 2: return _canProceedFromBusinessContactStep();
        case 3: return _canProceedFromBusinessInfoStep();
        case 4: return _canProceedFromBusinessRegistrationStep();
        case 5: return _canProceedFromBankBookStep();
        case 6: return _canProceedFromIdCardFrontStep();
        case 7: return _canProceedFromIdCardBackStep();
        case 8: return _canProceedFromStep3(); // 密碼設定
        case 9: return true; // 完成頁面
        default: return false;
      }
    } else {
      // 個人帳戶流程：5步
      switch (_currentStep) {
        case 1: return _canProceedFromStep1();
        case 2: return _canProceedFromStep2();
        case 3: return _canProceedFromStep3();
        case 4: return _canProceedFromStep4();
        case 5: return true; // 實名制認證
        default: return false;
      }
    }
  }

  // 企業註冊步驟：商業登記書上傳
  Widget _buildBusinessRegistrationStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題
            const Text(
              '完整版商業登記書 (1/4)',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 說明文字
            const Text(
              '請確保文件內容清楚，所有資訊可清楚辨識。',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 文件上傳區域
            _buildDocumentUploadSlot(
              onTap: () => _showImageSourceDialog((photos) {
                setState(() {
                  _businessRegistrationDocs = photos;
                });
              }),
              uploadedFiles: _businessRegistrationDocs,
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // 企業註冊步驟：帳戶存摺封面影本
  Widget _buildBankBookStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題
            const Text(
              '帳戶存摺封面影本 (2/4)',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 說明文字
            const Text(
              '除永豐銀行帳戶外，其他銀行匯款將收取 30 元手續費。',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 戶名
            CustomTextInput(
              label: '戶名',
              controller: _accountHolderController,
              onChanged: (value) {
                if (mounted) {
                  setState(() {}); // 更新按鈕狀態
                }
              },
            ),
            
            const SizedBox(height: 4),
            
            // 銀行代碼下拉選單
            DropdownBuilder.dialog<String>(
              label: '銀行代碼',
              dialogTitle: '選擇銀行',
              value: _bankCodeController.text.isEmpty ? null : _bankCodeController.text,
              onChanged: (value) {
                // 自動關閉鍵盤
                FocusScope.of(context).unfocus();
                
                if (mounted) {
                  setState(() {
                    _bankCodeController.text = value ?? '';
                  });
                }
              },
              items: const [
                DropdownItem(value: '013', label: '013 國泰世華'),
                DropdownItem(value: '012', label: '012 台北富邦'),
                DropdownItem(value: '808', label: '808 永豐銀行'),
                DropdownItem(value: '822', label: '822 中國信託'),
              ],
            ),
            
            const SizedBox(height: 4),
            
            // 銀行帳號
            CustomTextInput(
              label: '銀行帳號',
              controller: _accountNumberController,
              keyboardType: TextInputType.number,
              onChanged: (value) {
                if (mounted) {
                  setState(() {}); // 更新按鈕狀態
                }
              },
            ),
            
            const SizedBox(height: 4),
            
            // 文件上傳區域
            _buildDocumentUploadSlot(
              onTap: () => _showImageSourceDialog((photos) {
                setState(() {
                  _bankBookCover = photos;
                });
              }),
              uploadedFiles: _bankBookCover,
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // 企業註冊步驟：身分證正面
  Widget _buildIdCardFrontStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題
            const Text(
              '負責人身分證正面 (3/4)',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 說明文字
            const Text(
              '我們承諾客戶應有的個人資料，僅用於身份驗證用途。',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 文件上傳區域
            _buildDocumentUploadSlot(
              onTap: () => _showImageSourceDialog((photos) {
                setState(() {
                  _idCardFront = photos;
                });
              }),
              uploadedFiles: _idCardFront,
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // 企業註冊步驟：身分證背面
  Widget _buildIdCardBackStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題
            const Text(
              '負責人身分證背面 (4/4)',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 說明文字
            const Text(
              '這能幫助我們確認你的身份，身份認證是我們確保 TIME 安全的措施之一，不會提供給任何同用戶。',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 文件上傳區域
            _buildDocumentUploadSlot(
              onTap: () => _showImageSourceDialog((photos) {
                setState(() {
                  _idCardBack = photos;
                });
              }),
              uploadedFiles: _idCardBack,
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

}

/// 虛線邊框繪製器
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double borderRadius;
  final double dashWidth;
  final double dashSpace;

  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.borderRadius,
    this.dashWidth = 5.0,
    this.dashSpace = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rect);
    
    _drawDashedPath(canvas, path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final pathMetrics = path.computeMetrics();
    
    for (final metric in pathMetrics) {
      double distance = 0.0;
      bool draw = true;
      
      while (distance < metric.length) {
        final length = draw ? dashWidth : dashSpace;
        final endDistance = distance + length;
        
        if (draw) {
          final extractPath = metric.extractPath(distance, endDistance);
          canvas.drawPath(extractPath, paint);
        }
        
        distance = endDistance;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
