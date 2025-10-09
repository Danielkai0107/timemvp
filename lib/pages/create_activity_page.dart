import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'dart:io';
import '../components/design_system/custom_text_input.dart';
import '../components/design_system/custom_dropdown.dart';
import '../components/design_system/custom_button.dart';
import '../components/design_system/step_indicator.dart';
import '../components/design_system/app_colors.dart';
import '../components/design_system/success_popup.dart';
import '../components/design_system/date_picker.dart';
import '../components/design_system/time_picker.dart';
import '../components/design_system/custom_snackbar.dart';
import '../components/design_system/photo_upload.dart';
import '../services/activity_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/category_service.dart';
import 'main_navigation.dart';
import 'kyc_page.dart';

/// 發布活動頁面
class CreateActivityPage extends StatefulWidget {
  const CreateActivityPage({super.key});

  @override
  CreateActivityPageState createState() => CreateActivityPageState();
}

class CreateActivityPageState extends State<CreateActivityPage> with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  int _currentStep = 1;
  int _totalSteps = 8; // 動態調整步驟總數
  double _previousViewInsetsBottom = 0;
  
  // 服務實例
  final ActivityService _activityService = ActivityService();
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final CategoryService _categoryService = CategoryService();
  
  // 用戶狀態
  bool _isLoadingUserStatus = true;
  bool _hasCompletedKyc = false;
  bool _showProfitStep = true; // 是否顯示營利活動選擇步驟
  bool _canEditPrice = false; // 是否可以編輯價格
  
  // 步驟一：營利活動確認
  bool? _isProfitActivity;
  
  // 步驟二：發布類型
  String? _activityType;
  
  // 步驟三：舉辦方式
  String? _hostingMethod;
  
  // 步驟四：基本資料
  final TextEditingController _nameController = TextEditingController();
  String? _category;
  List<Category> _availableCategories = []; // 可用的分類列表
  bool _isLoadingCategories = false;
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _participantsController = TextEditingController();
  int _maxParticipants = 1;
  bool _isUnlimited = false;
  
  // 錯誤狀態管理
  String? _nameError;
  String? _categoryError;
  String? _startDateError;
  String? _startTimeError;
  String? _endDateError;
  String? _endTimeError;
  String? _addressError;
  String? _youtubeUrlError;
  
  // 步驟五：描述內容
  final TextEditingController _youtubeUrlController = TextEditingController();
  final TextEditingController _introductionController = TextEditingController();
  YoutubePlayerController? _youtubePreviewController;
  
  // 步驟六：相片上傳
  final List<String> _uploadedPhotos = [];
  
  // 步驟七：價格設定
  final TextEditingController _priceController = TextEditingController();
  int _price = 0;
  
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 初始化名額控制器
    _participantsController.text = _maxParticipants.toString();
    // 初始化價格控制器
    _priceController.text = _price.toString();
    // 設定預設值
    _activityType = 'individual'; // 預設為"舉辦活動"
    _hostingMethod = 'offline'; // 預設為"實體"
    // 檢查用戶狀態
    _checkUserStatus();
    // 載入預設活動類型的分類
    _loadCategories();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _nameController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _participantsController.dispose();
    _youtubeUrlController.dispose();
    _introductionController.dispose();
    _priceController.dispose();
    _youtubePreviewController?.dispose();
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

  /// 載入可用的分類
  Future<void> _loadCategories() async {
    if (_activityType == null) return;
    
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      debugPrint('載入分類，活動類型: $_activityType');
      
      // 根據活動類型載入對應的分類（優先使用 Firebase）
      final String categoryType = _activityType == 'individual' ? 'event' : 'task';
      final categories = await _categoryService.getCategoriesByType(categoryType);
      
      debugPrint('從 Firebase 載入了 ${categories.length} 個分類');
      
      if (mounted) {
        setState(() {
          _availableCategories = categories;
          _isLoadingCategories = false;
          
          // 如果當前選中的分類不在新的分類列表中，清除選擇
          if (_category != null && !categories.any((cat) => cat.name == _category)) {
            _category = null;
            _categoryError = null;
          }
        });
      }
    } catch (e) {
      debugPrint('從 Firebase 載入分類失敗: $e');
      
      // 只有在 Firebase 完全失敗時才使用備用數據
      try {
        final String categoryType = _activityType == 'individual' ? 'event' : 'task';
        final fallbackCategories = await _categoryService.getCategoriesByTypeWithFallback(categoryType);
        
        debugPrint('使用備用分類數據，載入了 ${fallbackCategories.length} 個分類');
        
        if (mounted) {
          setState(() {
            _availableCategories = fallbackCategories;
            _isLoadingCategories = false;
            
            // 如果當前選中的分類不在新的分類列表中，清除選擇
            if (_category != null && !fallbackCategories.any((cat) => cat.name == _category)) {
              _category = null;
              _categoryError = null;
            }
          });
          
          // 顯示警告，告知用戶正在使用備用數據
          CustomSnackBar.showError(
            context,
            message: '無法連接到服務器，正在使用離線分類數據',
          );
        }
      } catch (fallbackError) {
        debugPrint('備用分類數據也載入失敗: $fallbackError');
        if (mounted) {
          setState(() {
            _isLoadingCategories = false;
            _availableCategories = [];
          });
          
          CustomSnackBar.showError(
            context,
            message: '無法載入分類數據，請檢查網路連接',
          );
        }
      }
    }
  }


  /// 檢查用戶狀態（KYC 和帳號類型）
  Future<void> _checkUserStatus() async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        // 用戶未登入，使用預設設定
        setState(() {
          _isLoadingUserStatus = false;
          _showProfitStep = true;
          _canEditPrice = false;
        });
        return;
      }

      // 並行檢查 KYC 狀態和帳號類型
      final futures = await Future.wait([
        _userService.getUnifiedKycStatus(user.uid), // 使用統一的 KYC 狀態方法
        _userService.getUserAccountType(user.uid),
      ]);

      final kycStatus = futures[0];
      final accountType = futures[1];

      debugPrint('用戶統一 KYC 狀態: $kycStatus');
      debugPrint('用戶帳號類型: $accountType');

      setState(() {
        _isLoadingUserStatus = false;
        _hasCompletedKyc = kycStatus == 'approved';
        
        // 決定是否顯示營利活動選擇步驟
        // 修改：KYC approved 或 pending 狀態都不顯示營利活動選擇步驟
        if (kycStatus == 'approved' || kycStatus == 'pending') {
          // 已完成或待審核 KYC 的用戶：不顯示營利活動選擇，直接可編輯價格
          _showProfitStep = false;
          _canEditPrice = true;
          _totalSteps = 7; // 減少一個步驟
          _isProfitActivity = true; // 預設為營利活動
        } else {
          // 未完成 KYC 的用戶：顯示營利活動選擇步驟
          _showProfitStep = true;
          _canEditPrice = false; // 初始不可編輯，需要根據選擇決定
          _totalSteps = 8; // 保持原有步驟數
        }
      });
    } catch (e) {
      debugPrint('檢查用戶狀態失敗: $e');
      setState(() {
        _isLoadingUserStatus = false;
        _showProfitStep = true;
        _canEditPrice = false;
      });
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps) {
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

  // 驗證各步驟是否可以繼續
  bool _canProceedFromStep1() => _showProfitStep ? (_isProfitActivity != null) : true;
  bool _canProceedFromStep2() => _activityType != null;
  bool _canProceedFromStep3() => _hostingMethod != null;
  bool _canProceedFromStep4() {
    return _nameController.text.trim().isNotEmpty &&
           _category != null &&
           _startDate != null &&
           _startTime != null &&
           _endDate != null &&
           _endTime != null &&
           _addressController.text.trim().isNotEmpty &&
           _isEndTimeAfterStartTime(); // 新增：驗證結束時段晚於開始時段
  }
  bool _canProceedFromStep5() => _introductionController.text.trim().isNotEmpty;
  bool _canProceedFromStep6() => _uploadedPhotos.isNotEmpty;
  bool _canProceedFromStep7() => true; // 價格設定總是可以繼續

  VoidCallback? _getNextStepAction() {
    // 如果不顯示營利活動步驟，需要調整步驟編號
    final adjustedStep = _showProfitStep ? _currentStep : _currentStep + 1;
    
    switch (adjustedStep) {
      case 1: return _canProceedFromStep1() ? _handleStep1Next : () => _showStep1Errors();
      case 2: return _canProceedFromStep2() ? _nextStep : () => _showStep2Errors();
      case 3: return _canProceedFromStep3() ? _nextStep : () => _showStep3Errors();
      case 4: return _canProceedFromStep4() ? _nextStep : () => _showStep4Errors();
      case 5: return _canProceedFromStep5() ? _nextStep : () => _showStep5Errors();
      case 6: return _canProceedFromStep6() ? _nextStep : () => _showStep6Errors();
      case 7: return _canProceedFromStep7() ? _nextStep : () => _showStep7Errors();
      case 8: return _publishActivity; // 發布活動
      default: return null;
    }
  }

  /// 驗證結束時段是否晚於開始時段
  bool _isEndTimeAfterStartTime() {
    if (_startDate == null || _startTime == null || _endDate == null || _endTime == null) {
      return false;
    }
    
    final startDateTime = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );
    
    final endDateTime = DateTime(
      _endDate!.year,
      _endDate!.month,
      _endDate!.day,
      _endTime!.hour,
      _endTime!.minute,
    );
    
    return endDateTime.isAfter(startDateTime);
  }

  /// 顯示步驟4的錯誤提醒
  void _showStep4Errors() {
    setState(() {
      _nameError = _nameController.text.trim().isEmpty ? '請填寫活動名稱' : null;
      _categoryError = _category == null ? '請選擇活動類型' : null;
      _startDateError = _startDate == null ? '請選擇開始日期' : null;
      _startTimeError = _startTime == null ? '請選擇開始時間' : null;
      _endDateError = _endDate == null ? '請選擇結束日期' : null;
      _endTimeError = _endTime == null ? '請選擇結束時間' : null;
      _addressError = _addressController.text.trim().isEmpty ? '請填寫活動地址' : null;
      
      // 新增：檢查時段邏輯
      if (_startDate != null && _startTime != null && _endDate != null && _endTime != null) {
        if (!_isEndTimeAfterStartTime()) {
          _endDateError = '結束時間必須晚於開始時間';
          _endTimeError = '結束時間必須晚於開始時間';
        }
      }
    });

    // 顯示錯誤提示
    String errorMessage = '請完成所有必填欄位';
    if (!_isEndTimeAfterStartTime() && _startDate != null && _startTime != null && _endDate != null && _endTime != null) {
      errorMessage = '結束時間必須晚於開始時間';
    }
    CustomSnackBarBuilder.validationError(context, errorMessage);
  }

  /// 處理第一步的下一步邏輯
  Future<void> _handleStep1Next() async {
    if (!_showProfitStep) {
      // 不顯示營利活動步驟，直接進入下一步
      _nextStep();
      return;
    }

    // 顯示營利活動步驟的處理
    if (_isProfitActivity == null) {
      _showStep1Errors();
      return;
    }

    if (_isProfitActivity == true) {
      // 選擇營利活動，需要檢查是否已完成 KYC
      if (!_hasCompletedKyc) {
        // 未完成 KYC，導向 KYC 流程
        await _navigateToKyc();
        return;
      } else {
        // 已完成 KYC，允許編輯價格並繼續
        if (mounted) {
          setState(() {
            _canEditPrice = true;
          });
        }
        _nextStep();
      }
    } else {
      // 選擇非營利活動，不允許編輯價格
      if (mounted) {
        setState(() {
          _canEditPrice = false;
          _price = 0; // 設為免費
          _priceController.text = '0';
        });
      }
      _nextStep();
    }
  }

  /// 導向 KYC 流程
  Future<void> _navigateToKyc() async {
    try {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => const KycPage(fromRegistration: false),
        ),
      );

      if (result == true) {
        // KYC 完成，重新檢查用戶狀態
        await _checkUserStatus();
        if (_hasCompletedKyc && mounted) {
          setState(() {
            _canEditPrice = true;
          });
          _nextStep();
        }
      }
      // 如果 result 為 null 或 false，用戶取消了 KYC，留在當前步驟
    } catch (e) {
      debugPrint('導向 KYC 流程失敗: $e');
      if (mounted) {
        CustomSnackBar.showError(
          context,
          message: '無法進入 KYC 認證流程',
        );
      }
    }
  }

  /// 其他步驟的錯誤提醒
  void _showStep1Errors() {
    CustomSnackBarBuilder.validationError(context, '請選擇是否為營利活動');
  }

  void _showStep2Errors() {
    CustomSnackBarBuilder.validationError(context, '請選擇發布類型');
  }

  void _showStep3Errors() {
    CustomSnackBarBuilder.validationError(context, '請選擇舉辦方式');
  }

  void _showStep5Errors() {
    CustomSnackBarBuilder.validationError(context, '請填寫活動簡介');
  }

  void _showStep6Errors() {
    CustomSnackBarBuilder.validationError(context, '請至少上傳一張活動相片');
  }

  void _showStep7Errors() {
    // 價格設定通常不會有錯誤
  }

  /// 初始化或更新 YouTube 預覽控制器
  void _updateYoutubePreview(String url) {
    if (url.trim().isEmpty) {
      _youtubePreviewController?.dispose();
      _youtubePreviewController = null;
      _youtubeUrlError = null;
      return;
    }

    try {
      final videoId = YoutubePlayer.convertUrlToId(url);
      if (videoId != null) {
        _youtubePreviewController?.dispose();
        _youtubePreviewController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            mute: false,
            enableCaption: true,
            captionLanguage: 'zh-TW',
          ),
        );
        _youtubeUrlError = null; // 清除錯誤
        debugPrint('YouTube 預覽控制器初始化成功: $videoId');
      } else {
        debugPrint('無效的 YouTube URL: $url');
        _youtubePreviewController?.dispose();
        _youtubePreviewController = null;
        _youtubeUrlError = '請輸入有效的 YouTube 影片連結';
      }
    } catch (e) {
      debugPrint('YouTube 預覽控制器初始化失敗: $e');
      _youtubePreviewController?.dispose();
      _youtubePreviewController = null;
      _youtubeUrlError = '無效的 YouTube 連結格式';
    }
  }


  /// 建構 YouTube 預覽區域
  Widget _buildYoutubePreview() {
    if (_youtubePreviewController != null) {
      // 有效的 YouTube 連結，顯示播放器
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: YoutubePlayer(
            controller: _youtubePreviewController!,
            showVideoProgressIndicator: true,
            progressIndicatorColor: AppColors.primary900,
            progressColors: ProgressBarColors(
              playedColor: AppColors.primary900,
              handleColor: AppColors.primary900,
            ),
            onReady: () {
              debugPrint('YouTube 預覽播放器準備就緒');
            },
          ),
        ),
      );
    } else {
      // 無效的 YouTube 連結，不顯示任何內容
      return const SizedBox.shrink();
    }
  }

  /// 建構確認頁面的 YouTube 播放器
  Widget _buildConfirmationYoutubePlayer() {
    if (_youtubePreviewController != null) {
      // 有效的 YouTube 連結，顯示完整播放器
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: YoutubePlayer(
            controller: _youtubePreviewController!,
            showVideoProgressIndicator: true,
            progressIndicatorColor: AppColors.primary900,
            progressColors: ProgressBarColors(
              playedColor: AppColors.primary900,
              handleColor: AppColors.primary900,
            ),
            onReady: () {
              debugPrint('確認頁面 YouTube 播放器準備就緒');
            },
          ),
        ),
      );
    } else {
      // 無效的 YouTube 連結，不顯示任何內容
      return const SizedBox.shrink();
    }
  }

  String _getNextButtonText() {
    return _currentStep == 8 ? '確認發布' : '下一步';
  }

  bool _getNextButtonEnabled() {
    // 始終啟用下一步按鈕，讓用戶可以點擊來觸發錯誤檢查
    return true;
  }

  /// 發布活動
  Future<void> _publishActivity() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('=== 開始發布活動 ===');
      debugPrint('活動名稱: ${_nameController.text.trim()}');
      debugPrint('活動類型: $_activityType');
      debugPrint('舉辦方式: $_hostingMethod');
      debugPrint('價格: $_price');
      debugPrint('圖片數量: ${_uploadedPhotos.length}');
      
      // 檢查必要欄位
      if (_nameController.text.trim().isEmpty) {
        throw Exception('活動名稱不能為空');
      }
      if (_category == null) {
        throw Exception('請選擇活動類別');
      }
      if (_startDate == null || _startTime == null) {
        throw Exception('請設定開始時間');
      }
      if (_endDate == null || _endTime == null) {
        throw Exception('請設定結束時間');
      }
      if (_addressController.text.trim().isEmpty) {
        throw Exception('請填寫活動地址');
      }
      if (_uploadedPhotos.isEmpty) {
        throw Exception('請至少上傳一張活動照片');
      }
      if (_introductionController.text.trim().isEmpty) {
        throw Exception('請填寫活動介紹');
      }

      // 獲取當前用戶的 KYC 狀態以決定活動狀態
      final user = _authService.currentUser;
      String activityStatus = 'active'; // 預設狀態
      String? draftReason; // 草稿原因
      
      if (user != null && _isProfitActivity == true && _price > 0) {
        // 營利活動需要檢查 KYC 狀態
        final kycStatus = await _userService.getUnifiedKycStatus(user.uid);
        if (kycStatus == 'pending') {
          // KYC 待審核狀態，營利活動設為草稿
          activityStatus = 'draft';
          draftReason = 'kyc_pending'; // 標記為 KYC 待審核草稿
        } else if (kycStatus == 'approved') {
          // KYC 已通過，直接上架
          activityStatus = 'active';
        } else {
          // KYC 未完成或被拒絕，也設為草稿
          activityStatus = 'draft';
          draftReason = 'kyc_required';
        }
      }
      // 免費活動不看 KYC 狀態，直接上架

      // 準備活動資料
      final activityData = {
        'name': _nameController.text.trim(),
        'type': _activityType == 'individual' ? 'event' : 'task',
        'status': activityStatus,
        'draftReason': draftReason, // 新增：草稿原因
        'category': _getCategoryKey(_category!),
        'startDateTime': DateTime(
          _startDate!.year,
          _startDate!.month,
          _startDate!.day,
          _startTime!.hour,
          _startTime!.minute,
        ).toIso8601String(),
        'endDateTime': DateTime(
          _endDate!.year,
          _endDate!.month,
          _endDate!.day,
          _endTime!.hour,
          _endTime!.minute,
        ).toIso8601String(),
        'price': _price,
        'seats': _isUnlimited ? -1 : _maxParticipants,
        'introduction': _introductionController.text.trim(),
        'locationName': _addressController.text.trim(), // 使用地址作為位置名稱
        'address': _addressController.text.trim(),
        'city': '台北市', // 暫時固定
        'area': '大安區', // 暫時固定
        'latitude': 25.029659, // 暫時固定
        'longitude': 121.536287, // 暫時固定
        'isOnline': _hostingMethod == 'online',
        'youtubeUrl': _youtubeUrlController.text.trim().isEmpty 
            ? null 
            : _youtubeUrlController.text.trim(),
        'remark': null,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'isProfitActivity': _isProfitActivity,
      };

      debugPrint('活動資料準備完成: $activityData');

      // 使用 ActivityService 發布活動
      final activityId = await _activityService.publishActivity(
        activityData: activityData,
        imagePaths: _uploadedPhotos,
      );

      debugPrint('活動發布成功，ID: $activityId');

      if (mounted) {
        // 顯示發布成功的彈窗
        SuccessPopupBuilder.publishActivity(
          context,
          onConfirm: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const MainNavigationPage()),
              (route) => false,
            );
          },
        );
      }
    } catch (e) {
      debugPrint('發布活動失敗詳細錯誤: $e');
      if (mounted) {
        CustomSnackBar.showError(
          context,
          message: '發布失敗: ${e.toString().replaceAll('Exception: ', '')}',
          duration: const Duration(seconds: 5),
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



  /// 將分類名稱轉換為資料庫鍵值
  String _getCategoryKey(String categoryName) {
    // 直接返回分類名稱，因為現在使用的就是資料庫中的名稱
    return categoryName;
  }

  /// 獲取分類的顯示名稱
  String _getCategoryDisplayName(String categoryName) {
    if (categoryName.isEmpty) return '';
    
    // 從可用分類列表中找到對應的顯示名稱
    final category = _availableCategories.firstWhere(
      (cat) => cat.name == categoryName,
      orElse: () => Category(
        id: categoryName,
        name: categoryName, 
        displayName: categoryName, 
        type: 'event',
        sortOrder: 0,
        isActive: true,
      ),
    );
    
    return category.displayName;
  }

  /// 根據用戶狀態構建步驟頁面列表
  List<Widget> _buildStepPages() {
    final pages = <Widget>[];
    
    if (_showProfitStep) {
      pages.add(_buildStep1()); // 營利活動確認
    }
    
    pages.addAll([
      _buildStep2(), // 選擇發布類型
      _buildStep3(), // 選擇舉辦方式
      _buildStep4(), // 填寫基本資料
      _buildStep5(), // 填寫描述內容
      _buildStep6(), // 新增相片
      _buildStep7(), // 設定價格
      _buildStep8(), // 確認發布內容
    ]);
    
    return pages;
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
                child: _isLoadingUserStatus
                    ? const Center(child: CircularProgressIndicator())
                    : PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: _buildStepPages(),
                      ),
              ),
              
              // 底部步驟指示器
              StepIndicator(
                currentStep: _currentStep,
                totalSteps: _totalSteps,
              ),
              
              // 導航按鈕
              StepNavigationButtons(
                onPrevious: _currentStep > 1 ? _previousStep : null,
                onNext: _getNextStepAction(),
                showPrevious: _currentStep > 1,
                showNext: true,
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

  /// 步驟一：營利活動確認
  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '今天是否舉辦營利活動',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              '第一次發起營利活動，為保障你的權益並符合金融法規要求，需進行 KYC 實名認證，完成認證後即可安全使用平台功能。',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 選項
            _buildOptionCard(
              title: '是',
              isSelected: _isProfitActivity == true,
              onTap: () {
                setState(() {
                  _isProfitActivity = true;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            _buildOptionCard(
              title: '否',
              isSelected: _isProfitActivity == false,
              onTap: () {
                setState(() {
                  _isProfitActivity = false;
                });
              },
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// 步驟二：選擇發布類型
  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '首先，選擇發布類型',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            
            const SizedBox(height: 32),
            
            _buildOptionCard(
              title: '舉辦活動',
              icon: Icons.person,
              isSelected: _activityType == 'individual',
              onTap: () {
                setState(() {
                  _activityType = 'individual';
                });
                // 載入對應的分類
                _loadCategories();
              },
            ),
            
            const SizedBox(height: 16),
            
            _buildOptionCard(
              title: '任務委託',
              icon: Icons.people,
              isSelected: _activityType == 'group',
              onTap: () {
                setState(() {
                  _activityType = 'group';
                });
                // 載入對應的分類
                _loadCategories();
              },
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// 步驟三：選擇舉辦方式
  Widget _buildStep3() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '選擇舉辦方式',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            
            const SizedBox(height: 32),
            
            _buildOptionCard(
              title: '線上',
              isSelected: _hostingMethod == 'online',
              onTap: () {
                setState(() {
                  _hostingMethod = 'online';
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            _buildOptionCard(
              title: '實體',
              isSelected: _hostingMethod == 'offline',
              onTap: () {
                setState(() {
                  _hostingMethod = 'offline';
                });
              },
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// 步驟四：填寫基本資料
  Widget _buildStep4() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '接著，填寫基本資料',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 1. 活動名稱
            _buildSectionTitle('活動名稱'),
            CustomTextInput(
              label: '標題',
              controller: _nameController,
              errorText: _nameError,
              onChanged: (value) {
                if (mounted) {
                  setState(() {
                    _nameError = null; // 清除錯誤當用戶輸入時
                  });
                }
              },
            ),
            
            _buildSectionDivider(),
            
            // 2. 活動類型
            _buildSectionTitle('活動類型'),
            _isLoadingCategories 
                ? Container(
                    height: 64,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary900,
                        ),
                      ),
                    ),
                  )
                : DropdownBuilder.dialog<String>(
                    label: '類別',
                    dialogTitle: '選擇類別',
                    value: _category,
                    errorText: _categoryError,
                    onChanged: (value) {
                      setState(() {
                        _category = value;
                        _categoryError = null; // 清除錯誤當用戶選擇時
                      });
                    },
                    items: _availableCategories.map((category) => 
                      DropdownItem(
                        value: category.name, 
                        label: category.displayName,
                      )
                    ).toList(),
                  ),
            
            _buildSectionDivider(),
            
            // 3. 開始時段
            _buildSectionTitle('開始時段'),
            Row(
              children: [
                Expanded(
                  child: DatePickerBuilder.standard(
                    label: '開始日期',
                    value: _startDate,
                    errorText: _startDateError,
                    onChanged: (date) {
                      setState(() {
                        _startDate = date;
                        _startDateError = null; // 清除錯誤
                        // 如果結束日期未設定或早於開始日期，自動設定為開始日期
                        if (_endDate == null || (_endDate != null && date != null && _endDate!.isBefore(date))) {
                          _endDate = date;
                          _endDateError = null; // 清除結束日期錯誤
                        }
                      });
                    },
                    dialogTitle: '選擇開始日期',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TimePickerBuilder.standard(
                    label: '開始時間',
                    value: _startTime,
                    errorText: _startTimeError,
                    onChanged: (time) {
                      setState(() {
                        _startTime = time;
                        _startTimeError = null; // 清除錯誤
                        // 如果結束時間已設定，檢查並清除時段錯誤
                        if (_endTime != null && _endTimeError == '結束時間必須晚於開始時間') {
                          _endTimeError = null;
                        }
                        if (_endDate != null && _endDateError == '結束時間必須晚於開始時間') {
                          _endDateError = null;
                        }
                      });
                    },
                    dialogTitle: '選擇開始時間',
                  ),
                ),
              ],
            ),
            
            _buildSectionDivider(),
            
            // 4. 結束時段
            _buildSectionTitle('結束時段'),
            Row(
              children: [
                Expanded(
                  child: DatePickerBuilder.standard(
                    label: '結束日期',
                    value: _endDate,
                    errorText: _endDateError,
                    onChanged: (date) {
                      setState(() {
                        _endDate = date;
                        _endDateError = null; // 清除錯誤
                        // 如果結束時間已設定且有時段錯誤，檢查並清除
                        if (_endTime != null && _endTimeError == '結束時間必須晚於開始時間') {
                          _endTimeError = null;
                        }
                        if (_endDateError == '結束時間必須晚於開始時間') {
                          _endDateError = null;
                        }
                      });
                    },
                    dialogTitle: '選擇結束日期',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TimePickerBuilder.standard(
                    label: '結束時間',
                    value: _endTime,
                    errorText: _endTimeError,
                    onChanged: (time) {
                      setState(() {
                        _endTime = time;
                        _endTimeError = null; // 清除錯誤
                      });
                    },
                    dialogTitle: '選擇結束時間',
                  ),
                ),
              ],
            ),
            
            _buildSectionDivider(),
            
            // 5. 地點
            _buildSectionTitle('地點'),
            CustomTextInput(
              label: '地址',
              controller: _addressController,
              errorText: _addressError,
              onChanged: (value) {
                if (mounted) {
                  setState(() {
                    _addressError = null; // 清除錯誤當用戶輸入時
                  });
                }
              },
            ),
            
            _buildSectionDivider(),
            
            // 6. 名額
            _buildSectionTitle('名額'),
            // 名額輸入區域（與無限制按鈕相同樣式和高度）
            Container(
              height: 64, // 與無限制按鈕相同高度：16(上) + 32(內容) + 16(下) = 64
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (!_isUnlimited && _maxParticipants > 1) {
                        setState(() {
                          _maxParticipants--;
                          _participantsController.text = _maxParticipants.toString();
                        });
                      }
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.remove, 
                        size: 20,
                        color: (!_isUnlimited && _maxParticipants > 1) ? Colors.grey : Colors.grey.shade300,
                      ),
                    ),
                  ),
                  
                  Expanded(
                    child: Container(
                      height: 32, // 確保與按鈕相同高度
                      alignment: Alignment.center,
                      child: _isUnlimited 
                          ? const Text(
                              '-',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            )
                          : _buildEditableNumberInput(),
                    ),
                  ),
                  
                  GestureDetector(
                    onTap: () {
                      if (!_isUnlimited) {
                        setState(() {
                          _maxParticipants++;
                          _participantsController.text = _maxParticipants.toString();
                        });
                      }
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.add, 
                        size: 20,
                        color: !_isUnlimited ? Colors.grey : Colors.grey.shade300,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 無限制選項
            GestureDetector(
              onTap: () {
                setState(() {
                  _isUnlimited = !_isUnlimited;
                  if (_isUnlimited) {
                    // 切換到無限制時，清空輸入框焦點
                    FocusScope.of(context).unfocus();
                  } else {
                    // 切換回有限制時，更新輸入框文字
                    _participantsController.text = _maxParticipants.toString();
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _isUnlimited ? AppColors.primary900 : Colors.grey.shade300,
                    width: _isUnlimited ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: _isUnlimited ? AppColors.primary900.withValues(alpha: 0.1) : Colors.white,
                ),
                child: Center(
                  child: Text(
                    '無限制',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: _isUnlimited ? FontWeight.bold : FontWeight.w500,
                      color: Colors.black,
                    ),
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

  /// 步驟五：填寫描述內容
  Widget _buildStep5() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '填寫描述內容',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 1. 活動影片
            _buildSectionTitle('活動影片'),
            
            CustomTextInput(
              label: 'Youtube 影片網址',
              controller: _youtubeUrlController,
              errorText: _youtubeUrlError,
              onChanged: (value) {
                if (mounted) {
                  _updateYoutubePreview(value);
                  setState(() {});
                }
              },
            ),
            
            // YouTube 預覽區域
            if (_youtubeUrlController.text.isNotEmpty && _youtubePreviewController != null) ...[
              const SizedBox(height: 16),
              _buildYoutubePreview(),
            ],
            
            _buildSectionDivider(),
            
            // 2. 活動簡介
            _buildSectionTitle('活動簡介'),
            
            const Text(
              '若您的活動為收費活動，為避免消費糾紛，請於活動內容中明確主辦者開立發票之相關說明。',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
                height: 1.4,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _introductionController,
                    maxLines: 8,
                    maxLength: 1000,
                    decoration: const InputDecoration(
                      hintText: '描述內容',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                      counterStyle: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    onChanged: (value) {
                      if (mounted) {
                        setState(() {});
                      }
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// 步驟六：新增相片
  Widget _buildStep6() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '新增相片',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 相片上傳組件 - 使用新的2x2佈局
            PhotoUploadBuilder.personal(
              onPhotosChanged: (photos) {
                setState(() {
                  _uploadedPhotos.clear();
                  _uploadedPhotos.addAll(photos);
                });
              },
              photos: _uploadedPhotos,
              maxPhotos: 4,
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// 步驟七：設定價格
  Widget _buildStep7() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '最後一步，設定價格吧',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              _canEditPrice 
                  ? '請輸入每人報名費用，盈利最低金額 50 TWD。'
                  : '您選擇了非營利活動，因此活動費用固定為免費。',
              style: TextStyle(
                fontSize: 14,
                color: _canEditPrice ? Colors.black : Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 價格調整器（移除外框和高度限制）
            Row(
              children: [
                GestureDetector(
                  onTap: _canEditPrice ? () {
                    setState(() {
                      if (_price > 50) {
                        // 大於50時，正常減1
                        _price = _price - 1;
                        _priceController.text = _price.toString();
                      } else if (_price == 50) {
                        // 等於50時，減到0（顯示免費）
                        _price = 0;
                        _priceController.text = _price.toString();
                      }
                    });
                  } : null,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(25),
                    ),
                      child: Icon(
                        Icons.remove, 
                        size: 24,
                        color: (_canEditPrice && _price >= 50) ? Colors.grey : Colors.grey.shade300,
                      ),
                  ),
                ),
                
                Expanded(
                  child: Center(
                    child: _buildEditablePriceInput(),
                  ),
                ),
                
                GestureDetector(
                  onTap: _canEditPrice ? () {
                    setState(() {
                      if (_price < 50) {
                        // 小於50時（免費狀態），加到50
                        _price = 50;
                        _priceController.text = _price.toString();
                      } else {
                        // 大於等於50時，正常加1
                        _price = _price + 1;
                        _priceController.text = _price.toString();
                      }
                    });
                  } : null,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Icon(
                      Icons.add, 
                      size: 24,
                      color: _canEditPrice ? Colors.grey : Colors.grey.shade300,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // 費用明細
            if (_price > 0) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '每單位費用',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        '\$${_price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} TWD',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '平台服務費 (11%)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        '- \$${((_price * 0.11).round()).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} TWD',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            if (_price > 0) Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '每單位收入',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    '\$${((_price * 0.89).round()).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} TWD',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// 步驟八：確認發布內容
  Widget _buildStep8() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '確認發布內容',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              '請務必確認資訊，發布後無法修改任何內容。',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 1. 照片滿版滑動預覽
            if (_uploadedPhotos.isNotEmpty) ...[
              _buildConfirmationCoverImage(),
              const SizedBox(height: 24),
            ],
            
            // 2. 活動標題
            _buildSectionHeader('活動標題'),
            _buildSectionContent(_nameController.text),
            _buildDivider(),
            
            // 3. 類別
            _buildSectionHeader('類別'),
            _buildSectionContent(_getCategoryDisplayName(_category ?? '')),
            _buildDivider(),
            
            // 4. 日期
            _buildSectionHeader('日期'),
            _buildSectionContent(_startDate != null && _endDate != null 
                ? '${_startDate!.year}/${_startDate!.month}/${_startDate!.day} (${_getWeekday(_startDate!)}) ${_startTime?.format(context)} - ${_endDate!.year}/${_endDate!.month}/${_endDate!.day}(${_getWeekday(_endDate!)}) ${_endTime?.format(context)}'
                : ''),
            _buildDivider(),
            
            // 5. 地點
            _buildSectionHeader('地點'),
            _buildSectionContent(_addressController.text),
            _buildDivider(),
            
            // 6. 人數
            _buildSectionHeader('人數'),
            _buildSectionContent(_isUnlimited ? '共 不限 人' : '共 $_maxParticipants 人'),
            _buildDivider(),
            
            // 7. 報名費用
            _buildSectionHeader('報名費用'),
            _buildSectionContent(_price < 50 ? '免費' : '\$${_price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} TWD'),
            _buildDivider(),
            
            // 8. 活動介紹
            _buildSectionHeader('活動介紹'),
            
            // YouTube 影片播放器
            if (_youtubeUrlController.text.isNotEmpty && _youtubePreviewController != null) ...[
              _buildConfirmationYoutubePlayer(),
              const SizedBox(height: 12),
            ],
            
            // 活動描述文字
            _buildSectionContent(_introductionController.text),
            _buildDivider(),
            
            // 9. 收入詳情
            if (_price >= 50) ...[
              _buildSectionHeader('收入詳情'),
              const SizedBox(height: 8), // 增加8px距離
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildInfoRow('每單位費用', '\$${_price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} TWD'),
                    const SizedBox(height: 8),
                    _buildInfoRow('平台服務費 (11%)', '- \$${((_price * 0.11).round()).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} TWD'),
                    
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      height: 1,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 12),
                    
                    _buildInfoRow('每單位收入', '\$${((_price * 0.89).round()).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} TWD', isHighlight: true),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// 構建選項卡片
  Widget _buildOptionCard({
    required String title,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary900 : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? AppColors.primary900.withValues(alpha: 0.1) : Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center, // 內容居中
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 24,
                color: isSelected ? Colors.black : Colors.grey, // 被選擇時圖標變黑色
              ),
              const SizedBox(width: 16),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, // 被選擇時文字變粗體
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 構建小標題
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      ),
    );
  }

  /// 構建分隔線
  Widget _buildSectionDivider() {
    return Container(
      margin: const EdgeInsets.only(top: 8.0, bottom: 16.0),
      height: 1,
      color: Colors.grey.shade200,
    );
  }


  /// 構建可編輯的數字輸入框
  Widget _buildEditableNumberInput() {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 80,
        maxWidth: 120,
      ),
      child: TextField(
        controller: _participantsController,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
        onChanged: (value) {
          final number = int.tryParse(value);
          if (number != null && number >= 1) {
            setState(() {
              _maxParticipants = number;
            });
          }
        },
        onSubmitted: (value) {
          final number = int.tryParse(value);
          if (number != null && number >= 1) {
            setState(() {
              _maxParticipants = number;
            });
          } else {
            // 如果輸入無效，恢復原值
            setState(() {
              _participantsController.text = _maxParticipants.toString();
            });
          }
          FocusScope.of(context).unfocus();
        },
        onTap: () {
          // 點擊時選中所有文字，方便編輯
          _participantsController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _participantsController.text.length,
          );
        },
      ),
    );
  }




  /// 構建信息行
  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isHighlight ? Colors.black : Colors.grey.shade600,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  /// 獲取星期幾
  String _getWeekday(DateTime date) {
    const weekdays = ['日', '一', '二', '三', '四', '五', '六'];
    return weekdays[date.weekday % 7];
  }

  /// 構建區塊標題（黑字小標）
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      ),
    );
  }

  /// 構建區塊內容（灰字）
  Widget _buildSectionContent(String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        content,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
          height: 1.4,
        ),
      ),
    );
  }

  /// 構建分隔線
  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      height: 1,
      color: Colors.grey.shade200,
    );
  }

  /// 構建可編輯的價格輸入框（直接編輯，無popup）
  Widget _buildEditablePriceInput() {
    // 顯示免費或價格
    if (_price < 50) {
      return GestureDetector(
        onTap: _canEditPrice ? () {
          // 點擊免費時，設置為50開始編輯
          setState(() {
            _price = 50;
            _priceController.text = _price.toString();
          });
          // 延遲一點再選中文字，確保輸入框已更新
          Future.delayed(const Duration(milliseconds: 50), () {
            _priceController.selection = TextSelection(
              baseOffset: 0,
              extentOffset: _priceController.text.length,
            );
          });
        } : null,
        child: Text(
          '免費',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: _canEditPrice ? Colors.black : Colors.grey.shade400,
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(
        minWidth: 150,
        maxWidth: 250,
      ),
      child: Focus(
        onFocusChange: (hasFocus) {
          if (!hasFocus) {
            // 失去焦點時更新價格
            _updatePriceFromInput();
          }
        },
        child: TextField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          enabled: _canEditPrice,
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: _canEditPrice ? Colors.black : Colors.grey.shade400,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
          ),
          onChanged: (value) {
            // 不在這裡更新價格，等用戶完成編輯
          },
          onSubmitted: (value) {
            // 用戶按確認時更新價格
            _updatePriceFromInput();
            FocusScope.of(context).unfocus();
          },
          onEditingComplete: () {
            // 用戶完成編輯時更新價格
            _updatePriceFromInput();
          },
          onTap: () {
            // 點擊時選中所有文字，方便編輯
            _priceController.selection = TextSelection(
              baseOffset: 0,
              extentOffset: _priceController.text.length,
            );
          },
        ),
      ),
    );
  }

  /// 從輸入框更新價格
  void _updatePriceFromInput() {
    final number = int.tryParse(_priceController.text);
    if (number != null && number >= 0) {
      setState(() {
        // 0-49 的輸入都設為0（免費）
        _price = number < 50 ? 0 : number;
        _priceController.text = _price.toString();
      });
    } else {
      // 如果輸入無效，恢復原值
      setState(() {
        _priceController.text = _price.toString();
      });
    }
  }

  /// 建構確認頁面的封面圖片（滑動預覽）
  Widget _buildConfirmationCoverImage() {
    int currentImageIndex = 0; // 本地變量追蹤當前圖片索引
    
    return StatefulBuilder(
      builder: (context, setState) {
        return Stack(
          children: [
            // 圖片容器 (5:3 比例)
            AspectRatio(
              aspectRatio: 5 / 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.grey100,
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: PageView.builder(
                    itemCount: _uploadedPhotos.length,
                    onPageChanged: (index) {
                      setState(() {
                        currentImageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          image: DecorationImage(
                            image: FileImage(File(_uploadedPhotos[index])),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            
            // 頁數標籤（如果有多張圖片）
            if (_uploadedPhotos.length > 1)
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${currentImageIndex + 1}/${_uploadedPhotos.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            
            // 分頁指示器（如果有多張圖片）
            if (_uploadedPhotos.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _buildConfirmationPageIndicators(_uploadedPhotos.length, currentImageIndex),
                ),
              ),
          ],
        );
      },
    );
  }

  /// 建構確認頁面的分頁指示器
  List<Widget> _buildConfirmationPageIndicators(int count, int currentIndex) {
    return List.generate(count, (index) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: index == currentIndex ? Colors.white : Colors.white.withValues(alpha: 0.5),
        ),
      );
    });
  }


}

/// 步驟導航按鈕組件
class StepNavigationButtons extends StatelessWidget {
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onSkip;
  final bool showPrevious;
  final bool showNext;
  final bool showSkip;
  final String previousText;
  final String nextText;
  final String skipText;
  final bool isNextEnabled;
  final bool isLoading;

  const StepNavigationButtons({
    super.key,
    this.onPrevious,
    this.onNext,
    this.onSkip,
    this.showPrevious = true,
    this.showNext = true,
    this.showSkip = false,
    this.previousText = '上一步',
    this.nextText = '下一步',
    this.skipText = '略過',
    this.isNextEnabled = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          // 上一步按鈕
          if (showPrevious)
            Expanded(
              child: SizedBox(
                height: 60,
                child: OutlinedButton(
                  onPressed: onPrevious,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.grey300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    previousText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          
          if (showPrevious && (showNext || showSkip))
            const SizedBox(width: 16),
          
          // 略過按鈕
          if (showSkip)
            Expanded(
              child: SizedBox(
                height: 60,
                child: OutlinedButton(
                  onPressed: onSkip,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.grey300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    skipText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          
          if (showSkip && showNext)
            const SizedBox(width: 16),
          
          // 下一步按鈕
          if (showNext)
            Expanded(
              child: SizedBox(
                height: 60,
                child: ElevatedButton(
                  onPressed: isNextEnabled && !isLoading ? onNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary900,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: AppColors.grey300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : Text(
                          nextText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
