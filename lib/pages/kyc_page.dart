import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../components/design_system/custom_text_input.dart';
import '../components/design_system/custom_dropdown.dart';
import '../components/design_system/custom_button.dart';
import '../components/design_system/step_indicator.dart';
import '../components/design_system/app_colors.dart';
import '../components/design_system/custom_snackbar.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'main_navigation.dart';

/// KYC 認證頁面
/// 支援兩種模式：
/// 1. 註冊時認證 (fromRegistration: true) - 會連同註冊資料一起送出
/// 2. 獨立認證 (fromRegistration: false) - 只更新 KYC 資料
class KycPage extends StatefulWidget {
  final bool fromRegistration;
  final Map<String, dynamic>? registrationData; // 從註冊頁面傳來的資料
  
  const KycPage({
    super.key,
    this.fromRegistration = false,
    this.registrationData,
  });

  @override
  KycPageState createState() => KycPageState();
}

class KycPageState extends State<KycPage> with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  int _currentStep = 1;
  final int _totalSteps = 6;
  double _previousViewInsetsBottom = 0;
  
  // 服務實例
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  
  // 步驟一：實名制資料
  final TextEditingController _realNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  // 步驟二到六：證件和銀行資料
  List<String> _idCardFrontPhotos = [];
  List<String> _idCardBackPhotos = [];
  List<String> _healthCardPhotos = [];
  List<String> _bankBookPhotos = [];
  
  // 銀行帳戶資料
  final TextEditingController _accountHolderController = TextEditingController();
  final TextEditingController _bankCodeController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _realNameController.dispose();
    _addressController.dispose();
    _accountHolderController.dispose();
    _bankCodeController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    
    final currentViewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    
    // 檢查鍵盤是否從顯示變為隱藏
    if (_previousViewInsetsBottom > 0 && currentViewInsetsBottom == 0) {
      // 鍵盤隱藏時強制取消所有焦點
      _clearAllFocus();
    }
    
    _previousViewInsetsBottom = currentViewInsetsBottom;
  }

  /// 強制清除所有焦點
  void _clearAllFocus() {
    // 立即取消焦點
    FocusScope.of(context).unfocus();
    
    // 延遲再次確保焦點被清除
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        FocusScope.of(context).unfocus();
        // 強制將焦點移到一個不可見的節點
        FocusScope.of(context).requestFocus(FocusNode());
      }
    });
  }

  void _nextStep() {
    if (_currentStep < _totalSteps) {
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
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// 檢查步驟一是否可以繼續
  bool _canProceedFromStep1() {
    return _realNameController.text.isNotEmpty && 
           _addressController.text.isNotEmpty;
  }

  /// 檢查步驟二是否可以繼續
  bool _canProceedFromStep2() {
    return _idCardFrontPhotos.isNotEmpty;
  }

  /// 檢查步驟三是否可以繼續
  bool _canProceedFromStep3() {
    return _idCardBackPhotos.isNotEmpty;
  }

  /// 檢查步驟四是否可以繼續
  bool _canProceedFromStep4() {
    return _healthCardPhotos.isNotEmpty;
  }

  /// 檢查步驟五是否可以繼續
  bool _canProceedFromStep5() {
    return _accountHolderController.text.trim().isNotEmpty &&
           _bankCodeController.text.trim().isNotEmpty &&
           _accountNumberController.text.trim().isNotEmpty &&
           _bankBookPhotos.isNotEmpty;
  }

  VoidCallback? _getNextStepAction() {
    switch (_currentStep) {
      case 1: return _canProceedFromStep1() ? _nextStep : null;
      case 2: return _canProceedFromStep2() ? _nextStep : null;
      case 3: return _canProceedFromStep3() ? _nextStep : null;
      case 4: return _canProceedFromStep4() ? _nextStep : null;
      case 5: return _canProceedFromStep5() ? _completeKyc : null; // 提交 KYC 資料
      case 6: return null; // 第6步有自己的按鈕
      default: return null;
    }
  }

  String _getNextButtonText() {
    return _currentStep == 5 ? '提交認證' : '下一步';
  }

  bool _getNextButtonEnabled() {
    switch (_currentStep) {
      case 1: return _canProceedFromStep1();
      case 2: return _canProceedFromStep2();
      case 3: return _canProceedFromStep3();
      case 4: return _canProceedFromStep4();
      case 5: return _canProceedFromStep5();
      case 6: return true;
      default: return false;
    }
  }

  /// 完成 KYC 並自動登入
  Future<void> _completeKycAndLogin() async {
    if (!mounted) return;
    
    try {
      if (widget.fromRegistration) {
        // 註冊流程完成，導向主導覽頁面（包含底部導覽列）
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainNavigationPage()),
          (route) => false,
        );
      } else {
        // 獨立 KYC 完成，返回上一頁
        Navigator.of(context).pop(true); // 返回 true 表示 KYC 已完成
      }
    } catch (e) {
      debugPrint('導航時發生錯誤: $e');
      // 如果導航失敗，嘗試返回上一頁
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  /// 完成 KYC 流程
  Future<void> _completeKyc() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('用戶未登入');
      }

      // 上傳 KYC 相關圖片到 Firebase Storage
      debugPrint('開始上傳 KYC 圖片...');
      
      List<String> idCardFrontUrls = [];
      List<String> idCardBackUrls = [];
      List<String> healthCardUrls = [];
      List<String> bankBookUrls = [];

      // 上傳身分證正面
      if (_idCardFrontPhotos.isNotEmpty) {
        try {
          idCardFrontUrls = await _userService.uploadFiles(
            filePaths: _idCardFrontPhotos,
            folderName: 'kyc/id_card_front',
            uid: user.uid,
          );
          debugPrint('身分證正面上傳成功: $idCardFrontUrls');
        } catch (e) {
          debugPrint('身分證正面上傳失敗: $e');
        }
      }

      // 上傳身分證背面
      if (_idCardBackPhotos.isNotEmpty) {
        try {
          idCardBackUrls = await _userService.uploadFiles(
            filePaths: _idCardBackPhotos,
            folderName: 'kyc/id_card_back',
            uid: user.uid,
          );
          debugPrint('身分證背面上傳成功: $idCardBackUrls');
        } catch (e) {
          debugPrint('身分證背面上傳失敗: $e');
        }
      }

      // 上傳健保卡
      if (_healthCardPhotos.isNotEmpty) {
        try {
          healthCardUrls = await _userService.uploadFiles(
            filePaths: _healthCardPhotos,
            folderName: 'kyc/health_card',
            uid: user.uid,
          );
          debugPrint('健保卡上傳成功: $healthCardUrls');
        } catch (e) {
          debugPrint('健保卡上傳失敗: $e');
        }
      }

      // 上傳銀行存摺
      if (_bankBookPhotos.isNotEmpty) {
        try {
          bankBookUrls = await _userService.uploadFiles(
            filePaths: _bankBookPhotos,
            folderName: 'kyc/bank_book',
            uid: user.uid,
          );
          debugPrint('銀行存摺上傳成功: $bankBookUrls');
        } catch (e) {
          debugPrint('銀行存摺上傳失敗: $e');
        }
      }

      // 準備 KYC 資料（使用上傳後的 URLs）
      final kycData = {
        'realName': _realNameController.text,
        'address': _addressController.text,
        'idCardFrontPhotos': idCardFrontUrls,
        'idCardBackPhotos': idCardBackUrls,
        'healthCardPhotos': healthCardUrls,
        'bankBookPhotos': bankBookUrls,
        'accountHolder': _accountHolderController.text,
        'bankCode': _bankCodeController.text,
        'accountNumber': _accountNumberController.text,
        'kycStatus': 'pending', // pending, approved, rejected
        'kycSubmittedAt': DateTime.now().toIso8601String(),
      };

      if (widget.fromRegistration && widget.registrationData != null) {
        // 註冊時的 KYC：合併註冊資料和 KYC 資料
        final completeData = {
          ...widget.registrationData!,
          'kyc': kycData,
        };
        
        // Firebase 帳戶已在進入 KYC 前創建，這裡直接保存完整資料
        final user = _authService.currentUser;
        if (user != null) {
          await _userService.createUser(user.uid, completeData);
          debugPrint('註冊 + KYC 資料保存成功');
        }
      } else {
        // 獨立 KYC：只更新 KYC 資料
        final user = _authService.currentUser;
        if (user != null) {
          await _userService.updateUserKyc(user.uid, kycData);
          debugPrint('KYC 資料更新成功');
        }
      }

      if (mounted) {
        // 進入完成頁面（第6步）
        setState(() {
          _currentStep = 6;
        });
        
        _pageController.animateToPage(
          5, // 第6步的 index (0-based)
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        
        // 顯示成功訊息
        CustomSnackBar.showSuccess(
          context,
          message: 'KYC 資料提交成功，等待審核',
        );
      }
    } catch (e) {
      debugPrint('KYC 提交失敗: $e');
      if (mounted) {
        CustomSnackBar.showError(
          context,
          message: '提交失敗: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: GestureDetector(
        onTap: () {
          // 點擊空白區域時取消焦點
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
                      height: 54,
                      style: CustomButtonStyle.info,
                      borderRadius: 40.0,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 主要內容區域
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(), // 禁用滑動
                  children: [
                    _buildStep1(),
                    _buildStep2(),
                    _buildStep3(),
                    _buildStep4(),
                    _buildStep5(),
                    _buildStep6(),
                  ],
                ),
              ),
              
              // 底部步驟指示器（第6步隱藏）
              if (_currentStep != 6)
                StepIndicator(
                  currentStep: _currentStep,
                  totalSteps: _totalSteps,
                ),
              
              // 導航按鈕（第6步不顯示，因為有自己的按鈕）
              if (_currentStep != 6)
                StepNavigationButtons(
                  onPrevious: _currentStep > 1 ? _previousStep : null,
                  onNext: _getNextStepAction(),
                  showPrevious: _currentStep > 1,
                  previousText: '上一步',
                  nextText: _getNextButtonText(),
                  isNextEnabled: _getNextButtonEnabled(),
                  isLoading: _isLoading,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 步驟一：填寫實名制資料
  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題
            const Text(
              '首先，填寫實名制資料',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 說明文字
            const Text(
              '請填寫真實的個人資料，這將用於身份驗證',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 真實姓名輸入框
            CustomTextInput(
              label: '真實姓名',
              controller: _realNameController,
              onChanged: (value) {
                if (mounted) {
                  setState(() {}); // 更新按鈕狀態
                }
              },
            ),
            
            const SizedBox(height: 4),
            
            // 通訊地址輸入框
            CustomTextInput(
              label: '通訊地址',
              controller: _addressController,
              maxLines: 3,
              height: 100,
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

  /// 步驟二：上傳身分證件正面
  Widget _buildStep2() {
    return _buildDocumentUploadStep(
      title: '上傳身分證件正面',
      subtitle: '(1/4)',
      description: '請拍攝或上傳身分證正面照片，確保照片清晰可見',
      photos: _idCardFrontPhotos,
      onPhotosChanged: (photos) {
        setState(() {
          _idCardFrontPhotos = photos;
        });
      },
    );
  }

  /// 步驟三：上傳身分證件背面
  Widget _buildStep3() {
    return _buildDocumentUploadStep(
      title: '上傳身分證件背面',
      subtitle: '(2/4)',
      description: '請拍攝或上傳身分證背面照片，確保照片清晰可見',
      photos: _idCardBackPhotos,
      onPhotosChanged: (photos) {
        setState(() {
          _idCardBackPhotos = photos;
        });
      },
    );
  }

  /// 步驟四：上傳健保卡正面
  Widget _buildStep4() {
    return _buildDocumentUploadStep(
      title: '上傳健保卡正面',
      subtitle: '(3/4)',
      description: '請拍攝或上傳健保卡正面照片，確保照片清晰可見',
      photos: _healthCardPhotos,
      onPhotosChanged: (photos) {
        setState(() {
          _healthCardPhotos = photos;
        });
      },
    );
  }

  /// 步驟五：帳戶存摺封面影本
  Widget _buildStep5() {
    return _buildBankBookUploadStep();
  }

  /// 銀行存摺上傳步驟（與企業註冊相同）
  Widget _buildBankBookUploadStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題
            const Text(
              '帳戶存摺封面影本 (4/4)',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 說明文字
            const Text(
              '除永豐銀行帳戶外，其他銀行匯款將收取 30 元手續費。',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
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
                DropdownItem(value: '004', label: '004 台灣銀行'),
                DropdownItem(value: '006', label: '006 合作金庫'),
                DropdownItem(value: '007', label: '007 第一銀行'),
                DropdownItem(value: '008', label: '008 華南銀行'),
                DropdownItem(value: '009', label: '009 彰化銀行'),
                DropdownItem(value: '011', label: '011 上海銀行'),
                DropdownItem(value: '017', label: '017 兆豐銀行'),
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
            _PhotoUploadWidget(
              maxPhotos: 1,
              photos: _bankBookPhotos,
              onPhotosChanged: (photos) {
                setState(() {
                  _bankBookPhotos = photos;
                });
              },
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// 步驟六：完成申請
  Widget _buildStep6() {
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
              onPressed: _completeKycAndLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary900,
                foregroundColor: AppColors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '我知道了',
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

  /// 通用的文件上傳步驟 UI
  Widget _buildDocumentUploadStep({
    required String title,
    required String subtitle,
    required String description,
    required List<String> photos,
    required ValueChanged<List<String>> onPhotosChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題和副標題
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 說明文字
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 照片上傳區域
            _PhotoUploadWidget(
              maxPhotos: 1, // 每個證件只允許一張照片
              photos: photos,
              onPhotosChanged: onPhotosChanged,
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

/// KYC 照片上傳組件，使用與企業註冊相同的 UI 設計
class _PhotoUploadWidget extends StatefulWidget {
  final int maxPhotos;
  final List<String> photos;
  final ValueChanged<List<String>> onPhotosChanged;

  const _PhotoUploadWidget({
    required this.maxPhotos,
    required this.photos,
    required this.onPhotosChanged,
  });

  @override
  _PhotoUploadWidgetState createState() => _PhotoUploadWidgetState();
}

class _PhotoUploadWidgetState extends State<_PhotoUploadWidget> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImageFromGallery() async {
    if (widget.photos.length >= widget.maxPhotos) {
      _showErrorDialog('已達到最大照片數量限制');
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        final file = File(image.path);
        if (await file.exists()) {
          final updatedPhotos = [...widget.photos, image.path];
          widget.onPhotosChanged(updatedPhotos);
        }
      }
    } catch (e) {
      _showErrorDialog('選擇照片失敗，請確認已授予相簿權限');
    }
  }

  Future<void> _takePhoto() async {
    if (widget.photos.length >= widget.maxPhotos) {
      _showErrorDialog('已達到最大照片數量限制');
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        final updatedPhotos = [...widget.photos, image.path];
        widget.onPhotosChanged(updatedPhotos);
      }
    } catch (e) {
      _showErrorDialog('拍照失敗，請確認已授予相機權限');
    }
  }

  void _removePhoto(int index) {
    final updatedPhotos = [...widget.photos];
    updatedPhotos.removeAt(index);
    widget.onPhotosChanged(updatedPhotos);
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
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
                color: AppColors.grey300,
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
                  const Expanded(
                    child: Center(
                      child: Text(
                        '選擇照片來源',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
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
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 20,
                        color: AppColors.grey500,
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
                        color: AppColors.textSecondary,
                        size: 24,
                      ),
                      title: const Text(
                        '從相簿選擇',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _pickImageFromGallery();
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
                      color: AppColors.textSecondary,
                      size: 24,
                    ),
                    title: const Text(
                      '拍照',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _takePhoto();
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

  void _showErrorDialog(String message) {
    if (!mounted) return;
    
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

  @override
  Widget build(BuildContext context) {
    return _buildDocumentUploadSlot();
  }

  /// 與企業註冊相同的文件上傳 UI
  Widget _buildDocumentUploadSlot() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: SizedBox(
        height: 200,
        child: widget.photos.isEmpty
          ? CustomPaint(
              painter: DashedBorderPainter(
                color: AppColors.grey500,
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
                    color: AppColors.grey500,
                  ),
                ),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.border,
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    // 顯示照片
                    Image.file(
                      File(widget.photos.first),
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.grey100,
                          child: const Center(
                            child: Icon(
                              Icons.error_outline,
                              color: AppColors.grey500,
                              size: 32,
                            ),
                          ),
                        );
                      },
                    ),
                    // 重新上傳按鈕（右上角）
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _removePhoto(0),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.error900,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.refresh,
                            size: 18,
                            color: AppColors.white,
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
}

/// 虛線邊框繪製器（與企業註冊相同的實現）
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
