import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'dart:io';
import '../components/design_system/custom_text_input.dart';
import '../components/design_system/custom_dropdown.dart';
import '../components/design_system/custom_button.dart';
import '../components/design_system/step_indicator.dart';
import '../components/design_system/app_colors.dart';
import '../components/design_system/date_picker.dart';
import '../components/design_system/time_picker.dart';
import '../components/design_system/custom_snackbar.dart';
import '../services/activity_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/category_service.dart';
import 'my_activities_page.dart';
import 'home.dart';

/// 編輯活動頁面
class EditActivityPage extends StatefulWidget {
  final String activityId;
  final Map<String, dynamic> activityData;

  const EditActivityPage({
    super.key,
    required this.activityId,
    required this.activityData,
  });

  @override
  EditActivityPageState createState() => EditActivityPageState();
}

class EditActivityPageState extends State<EditActivityPage> with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  int _currentStep = 1;
  int _totalSteps = 7; // 編輯流程：發布類型 → 舉辦方式 → 基本資料 → 描述內容 → 相片 → 價格 → 確認更新
  double _previousViewInsetsBottom = 0;
  
  // 服務實例
  final ActivityService _activityService = ActivityService();
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final CategoryService _categoryService = CategoryService();
  
  // KYC 狀態
  bool _hasCompletedKyc = false;
  bool _canEditPrice = true;
  
  // 步驟一：發布類型
  String? _activityType;
  
  // 步驟二：舉辦方式
  String? _hostingMethod;
  
  // 步驟三：基本資料
  final TextEditingController _nameController = TextEditingController();
  String? _category;
  List<Category> _availableCategories = []; // 可用的分類列表
  bool _isLoadingCategories = false;
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _participantsController = TextEditingController();
  int _maxParticipants = 0;
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
  
  // 步驟四：描述內容
  final TextEditingController _youtubeUrlController = TextEditingController();
  final TextEditingController _introductionController = TextEditingController();
  YoutubePlayerController? _youtubePreviewController;
  
  // 步驟五：相片上傳
  final List<String> _uploadedPhotos = [];
  final List<String> _existingPhotoUrls = []; // 現有的網路圖片
  
  // 步驟六：價格設定
  final TextEditingController _priceController = TextEditingController();
  int _price = 0;
  bool _isProfitActivity = true;
  
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeWithActivityData();
    _checkUserKycStatus();
    // 載入預設活動類型的分類
    _loadCategories();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _nameController.dispose();
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
    FocusScope.of(context).unfocus();
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        FocusScope.of(context).unfocus();
        FocusScope.of(context).requestFocus(FocusNode());
      }
    });
  }

  /// 檢查用戶 KYC 狀態
  Future<void> _checkUserKycStatus() async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        setState(() {
          _canEditPrice = false;
        });
        return;
      }

      final kycStatus = await _userService.getUnifiedKycStatus(user.uid);
      debugPrint('編輯頁面 - 用戶 KYC 狀態: $kycStatus');

      setState(() {
        _hasCompletedKyc = kycStatus == 'approved';
        _canEditPrice = _hasCompletedKyc;
        
        // 如果 KYC 未通過且當前是營利活動，強制設為免費
        if (!_hasCompletedKyc && _price > 0) {
          _price = 0;
          _priceController.text = '0';
          _isProfitActivity = false;
        }
      });
    } catch (e) {
      debugPrint('檢查 KYC 狀態失敗: $e');
      setState(() {
        _canEditPrice = false;
      });
    }
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
          
          // 設定當前分類（從活動數據中獲取）
          _setCurrentCategoryFromData(categories);
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
            
            // 設定當前分類（從活動數據中獲取）
            _setCurrentCategoryFromData(fallbackCategories);
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

  /// 設定當前分類（從活動數據中獲取）
  void _setCurrentCategoryFromData(List<Category> categories) {
    final data = widget.activityData;
    final originalCategory = data['category'];
    
    if (originalCategory != null) {
      // 嘗試根據 name 匹配分類
      final matchedCategory = categories.firstWhere(
        (cat) => cat.name == originalCategory,
        orElse: () => categories.firstWhere(
          (cat) => cat.id == originalCategory,
          orElse: () => categories.firstWhere(
            (cat) => cat.displayName == _getCategoryDisplayName(originalCategory),
            orElse: () => Category(
              id: '', 
              name: '', 
              displayName: '', 
              type: '', 
              sortOrder: 0, 
              isActive: false
            ),
          ),
        ),
      );
      
      if (matchedCategory.name.isNotEmpty) {
        _category = matchedCategory.name;
        debugPrint('設定分類為: ${matchedCategory.displayName} (${matchedCategory.name})');
      } else {
        debugPrint('無法匹配分類: $originalCategory');
        _category = null;
      }
    }
  }

  /// 使用現有活動數據初始化表單
  void _initializeWithActivityData() {
    final data = widget.activityData;
    
    // 基本資料
    _nameController.text = data['name'] ?? '';
    _addressController.text = data['address'] ?? '';
    _introductionController.text = data['introduction'] ?? '';
    
    // 活動類型
    _activityType = data['type'] == 'event' ? 'individual' : 'group';
    
    // 舉辦方式
    _hostingMethod = data['isOnline'] == true ? 'online' : 'offline';
    
    // 時間設定
    if (data['startDateTime'] != null) {
      final startDateTime = DateTime.parse(data['startDateTime']);
      _startDate = startDateTime;
      _startTime = TimeOfDay.fromDateTime(startDateTime);
    }
    
    if (data['endDateTime'] != null) {
      final endDateTime = DateTime.parse(data['endDateTime']);
      _endDate = endDateTime;
      _endTime = TimeOfDay.fromDateTime(endDateTime);
    }
    
    // 人數設定
    final seats = data['seats'];
    if (seats == -1) {
      _isUnlimited = true;
      _maxParticipants = 0;
    } else {
      _isUnlimited = false;
      _maxParticipants = seats ?? 0;
    }
    _participantsController.text = _maxParticipants.toString();
    
    // 價格設定
    _price = data['price'] ?? 0;
    _priceController.text = _price.toString();
    _isProfitActivity = data['isProfitActivity'] ?? (_price > 0);
    
    // YouTube URL
    if (data['youtubeUrl'] != null && data['youtubeUrl'].isNotEmpty) {
      _youtubeUrlController.text = data['youtubeUrl'];
      _updateYoutubePreview(data['youtubeUrl']);
    }
    
    // 現有圖片 - 檢查多個可能的欄位
    List<String> existingImages = [];
    
    // 檢查 cover 圖片
    if (data['cover'] != null && data['cover'].toString().isNotEmpty) {
      existingImages.add(data['cover'].toString());
    }
    
    // 檢查 files 陣列中的圖片
    if (data['files'] != null && data['files'] is List) {
      for (var file in data['files']) {
        if (file is Map<String, dynamic> && file['url'] != null) {
          final url = file['url'].toString();
          if (url.isNotEmpty && !existingImages.contains(url)) {
            existingImages.add(url);
          }
        }
      }
    }
    
    // 檢查 images 陣列
    if (data['images'] != null && data['images'] is List) {
      for (var image in data['images']) {
        final url = image.toString();
        if (url.isNotEmpty && !existingImages.contains(url)) {
          existingImages.add(url);
        }
      }
    }
    
    _existingPhotoUrls.addAll(existingImages);
    debugPrint('載入現有圖片數量: ${_existingPhotoUrls.length}');
    
    setState(() {});
  }

  /// 將資料庫分類鍵值轉換為顯示名稱
  String? _getCategoryDisplayName(String? categoryKey) {
    switch (categoryKey) {
      case 'EventCategory_language_teaching': return '語言教學';
      case 'EventCategory_skill_experience': return '技能體驗';
      case 'EventCategory_event_support': return '活動支援';
      case 'EventCategory_life_service': return '生活服務';
      default: return null;
    }
  }

  /// 將分類名稱轉換為資料庫鍵值
  String _getCategoryKey(String categoryName) {
    // 直接返回分類名稱，因為現在使用的就是資料庫中的名稱
    return categoryName;
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
  bool _canProceedFromStep1() => _activityType != null;
  bool _canProceedFromStep2() => _hostingMethod != null;
  bool _canProceedFromStep3() {
    return _nameController.text.trim().isNotEmpty &&
           _category != null &&
           _startDate != null &&
           _startTime != null &&
           _endDate != null &&
           _endTime != null &&
           _addressController.text.trim().isNotEmpty;
  }
  bool _canProceedFromStep4() => _introductionController.text.trim().isNotEmpty;
  bool _canProceedFromStep5() => _uploadedPhotos.isNotEmpty || _existingPhotoUrls.isNotEmpty;
  bool _canProceedFromStep6() => true; // 價格設定總是可以繼續

  VoidCallback? _getNextStepAction() {
    switch (_currentStep) {
      case 1: return _canProceedFromStep1() ? _nextStep : () => _showStep1Errors();
      case 2: return _canProceedFromStep2() ? _nextStep : () => _showStep2Errors();
      case 3: return _canProceedFromStep3() ? _nextStep : () => _showStep3Errors();
      case 4: return _canProceedFromStep4() ? _nextStep : () => _showStep4Errors();
      case 5: return _canProceedFromStep5() ? _nextStep : () => _showStep5Errors();
      case 6: return _canProceedFromStep6() ? _nextStep : () => _showStep6Errors();
      case 7: return _updateActivity; // 更新活動
      default: return null;
    }
  }

  /// 顯示各步驟的錯誤提醒
  void _showStep1Errors() {
    CustomSnackBarBuilder.validationError(context, '請選擇發布類型');
  }

  void _showStep2Errors() {
    CustomSnackBarBuilder.validationError(context, '請選擇舉辦方式');
  }

  void _showStep3Errors() {
    setState(() {
      _nameError = _nameController.text.trim().isEmpty ? '請填寫活動名稱' : null;
      _categoryError = _category == null ? '請選擇活動類型' : null;
      _startDateError = _startDate == null ? '請選擇開始日期' : null;
      _startTimeError = _startTime == null ? '請選擇開始時間' : null;
      _endDateError = _endDate == null ? '請選擇結束日期' : null;
      _endTimeError = _endTime == null ? '請選擇結束時間' : null;
      _addressError = _addressController.text.trim().isEmpty ? '請填寫活動地址' : null;
    });
    CustomSnackBarBuilder.validationError(context, '請完成所有必填欄位');
  }

  void _showStep4Errors() {
    CustomSnackBarBuilder.validationError(context, '請填寫活動簡介');
  }

  void _showStep5Errors() {
    CustomSnackBarBuilder.validationError(context, '請至少保留一張活動相片');
  }

  void _showStep6Errors() {
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
        _youtubeUrlError = null;
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
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  String _getNextButtonText() {
    return _currentStep == 7 ? '確認更新' : '下一步';
  }

  bool _getNextButtonEnabled() {
    return true;
  }

  /// 更新活動
  Future<void> _updateActivity() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('=== 開始更新活動 ===');
      debugPrint('活動ID: ${widget.activityId}');
      
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
      if (_uploadedPhotos.isEmpty && _existingPhotoUrls.isEmpty) {
        throw Exception('請至少保留一張活動照片');
      }
      if (_introductionController.text.trim().isEmpty) {
        throw Exception('請填寫活動介紹');
      }

      // 準備更新資料
      final updateData = {
        'name': _nameController.text.trim(),
        'type': _activityType == 'individual' ? 'event' : 'task',
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
        'locationName': _addressController.text.trim(),
        'address': _addressController.text.trim(),
        'isOnline': _hostingMethod == 'online',
        'youtubeUrl': _youtubeUrlController.text.trim().isEmpty 
            ? null 
            : _youtubeUrlController.text.trim(),
        'updatedAt': DateTime.now().toIso8601String(),
        'isProfitActivity': _isProfitActivity,
      };

      debugPrint('活動更新資料準備完成: $updateData');

      // 使用 ActivityService 更新活動
      await _activityService.updateActivity(
        activityId: widget.activityId,
        updateData: updateData,
        newImagePaths: _uploadedPhotos,
        existingImageUrls: _existingPhotoUrls,
      );

      debugPrint('活動更新成功');

      if (mounted) {
        // 觸發相關頁面重整
        MyActivitiesPageController.refreshActivities();
        HomePageController.refreshActivities();
        
        // 顯示成功訊息並直接返回
        CustomSnackBarBuilder.success(context, '活動更新成功');
        Navigator.of(context).pop(); // 直接返回活動詳情頁面
      }
    } catch (e) {
      debugPrint('更新活動失敗詳細錯誤: $e');
      if (mounted) {
        CustomSnackBar.showError(
          context,
          message: '更新失敗: ${e.toString().replaceAll('Exception: ', '')}',
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

  /// 構建步驟頁面列表
  List<Widget> _buildStepPages() {
    return [
      _buildStep1(), // 選擇發布類型
      _buildStep2(), // 選擇舉辦方式
      _buildStep3(), // 填寫基本資料
      _buildStep4(), // 填寫描述內容
      _buildStep5(), // 新增相片
      _buildStep6(), // 設定價格
      _buildStep7(), // 確認更新內容
    ];
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
                child: PageView(
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

  /// 步驟一：選擇發布類型
  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '修改發布類型',
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

  /// 步驟二：選擇舉辦方式
  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '修改舉辦方式',
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

  /// 步驟三：填寫基本資料
  Widget _buildStep3() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '修改基本資料',
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
                    _nameError = null;
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
                        _categoryError = null;
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
                        _startDateError = null;
                        if (_endDate == null || (_endDate != null && date != null && _endDate!.isBefore(date))) {
                          _endDate = date;
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
                        _startTimeError = null;
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
                        _endDateError = null;
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
                        _endTimeError = null;
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
                    _addressError = null;
                  });
                }
              },
            ),
            
            _buildSectionDivider(),
            
            // 6. 名額
            _buildSectionTitle('名額'),
            Container(
              height: 64,
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
                      if (!_isUnlimited && _maxParticipants > 0) {
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
                        color: (!_isUnlimited && _maxParticipants > 0) ? Colors.grey : Colors.grey.shade300,
                      ),
                    ),
                  ),
                  
                  Expanded(
                    child: Container(
                      height: 32,
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
                    FocusScope.of(context).unfocus();
                  } else {
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

  /// 步驟四：填寫描述內容
  Widget _buildStep4() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '修改描述內容',
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

  /// 步驟五：新增相片
  Widget _buildStep5() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '修改活動相片',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 新增相片按鈕
            GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: Colors.black),
                    SizedBox(width: 8),
                    Text(
                      '新增相片',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 顯示所有相片 - 使用新的2x2佈局
            _buildEditPhotoGrid(),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// 步驟六：設定價格
  Widget _buildStep6() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '修改價格設定',
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
                  : '您的身份認證尚未通過，目前只能設定為免費活動。',
              style: TextStyle(
                fontSize: 14,
                color: _canEditPrice ? Colors.black : Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 價格調整器
            Row(
              children: [
                GestureDetector(
                  onTap: _canEditPrice ? () {
                    setState(() {
                      if (_price > 50) {
                        _price = _price - 1;
                        _priceController.text = _price.toString();
                      } else if (_price == 50) {
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
                        _price = 50;
                        _priceController.text = _price.toString();
                      } else {
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
                color: Colors.grey.shade50,
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
                color: Colors.grey.shade50,
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

  /// 步驟七：確認更新內容
  Widget _buildStep7() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '確認更新內容',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              '請確認修改的內容，更新後將保存變更。',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 1. 活動標題
            _buildSectionHeader('活動標題'),
            _buildSectionContent(_nameController.text),
            _buildDivider(),
            
            // 2. 類別
            _buildSectionHeader('類別'),
            _buildSectionContent(_category ?? ''),
            _buildDivider(),
            
            // 3. 日期
            _buildSectionHeader('日期'),
            _buildSectionContent(_startDate != null && _endDate != null 
                ? '${_startDate!.year}/${_startDate!.month}/${_startDate!.day} (${_getWeekday(_startDate!)}) ${_startTime?.format(context)} - ${_endDate!.year}/${_endDate!.month}/${_endDate!.day}(${_getWeekday(_endDate!)}) ${_endTime?.format(context)}'
                : ''),
            _buildDivider(),
            
            // 4. 地點
            _buildSectionHeader('地點'),
            _buildSectionContent(_addressController.text),
            _buildDivider(),
            
            // 5. 人數
            _buildSectionHeader('人數'),
            _buildSectionContent(_isUnlimited ? '共 不限 人' : '共 $_maxParticipants 人'),
            _buildDivider(),
            
            // 6. 報名費用
            _buildSectionHeader('報名費用'),
            _buildSectionContent(_price < 50 ? '免費' : '\$${_price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} TWD'),
            _buildDivider(),
            
            // 7. 活動介紹
            _buildSectionHeader('活動介紹'),
            _buildSectionContent(_introductionController.text),
            
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 24,
                color: isSelected ? Colors.black : Colors.grey,
              ),
              const SizedBox(width: 16),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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
          if (number != null && number >= 0) {
            setState(() {
              _maxParticipants = number;
            });
          }
        },
        onSubmitted: (value) {
          final number = int.tryParse(value);
          if (number != null && number >= 0) {
            setState(() {
              _maxParticipants = number;
            });
          } else {
            setState(() {
              _participantsController.text = _maxParticipants.toString();
            });
          }
          FocusScope.of(context).unfocus();
        },
        onTap: () {
          _participantsController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _participantsController.text.length,
          );
        },
      ),
    );
  }

  /// 構建可編輯的價格輸入框
  Widget _buildEditablePriceInput() {
    // 顯示免費或價格
    if (_price < 50) {
      return GestureDetector(
        onTap: _canEditPrice ? () {
          setState(() {
            _price = 50;
            _priceController.text = _price.toString();
          });
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
          onSubmitted: (value) {
            _updatePriceFromInput();
            FocusScope.of(context).unfocus();
          },
          onEditingComplete: () {
            _updatePriceFromInput();
          },
          onTap: () {
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
        _price = number < 50 ? 0 : number;
        _priceController.text = _price.toString();
      });
    } else {
      setState(() {
        _priceController.text = _price.toString();
      });
    }
  }

  /// 顯示圖片來源選擇對話框
  void _showImageSourceDialog() {
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
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '選擇照片來源',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
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
            
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('從相簿選擇'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('拍照'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  /// 從相簿選擇圖片
  Future<void> _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _uploadedPhotos.add(image.path);
        });
      }
    } catch (e) {
      CustomSnackBar.showError(
        context,
        message: '選擇圖片失敗，請確認已授予相簿權限',
      );
    }
  }

  /// 拍照
  Future<void> _takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _uploadedPhotos.add(image.path);
        });
      }
    } catch (e) {
      CustomSnackBar.showError(
        context,
        message: '拍照失敗，請確認已授予相機權限',
      );
    }
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

  /// 建構編輯頁面的照片網格，使用2x2佈局
  Widget _buildEditPhotoGrid() {
    // 合併所有照片：現有的網路圖片 + 新上傳的本地圖片
    final allPhotos = <Map<String, dynamic>>[];
    
    // 添加現有照片
    for (int i = 0; i < _existingPhotoUrls.length; i++) {
      allPhotos.add({
        'type': 'network',
        'path': _existingPhotoUrls[i],
        'listType': 'existing',
        'listIndex': i,
        'isExisting': true,
      });
    }
    
    // 添加新上傳的照片
    for (int i = 0; i < _uploadedPhotos.length; i++) {
      allPhotos.add({
        'type': 'file',
        'path': _uploadedPhotos[i],
        'listType': 'uploaded',
        'listIndex': i,
        'isExisting': false,
      });
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '活動相片',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        _buildEdit2x2PhotoGrid(allPhotos),
      ],
    );
  }

  /// 建構編輯頁面的2x2照片網格
  Widget _buildEdit2x2PhotoGrid(List<Map<String, dynamic>> allPhotos) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 4 / 3, // 修改為4:3比例
      ),
      itemCount: 4, // 固定4個位置
      itemBuilder: (context, index) {
        if (index < allPhotos.length) {
          // 顯示已有的照片
          return _buildEditPhotoSlot(allPhotos[index]);
        } else if (index == allPhotos.length && allPhotos.length < 4) {
          // 顯示新增按鈕（虛線方框 + icon）
          return _buildEditAddPhotoSlot();
        } else {
          // 空白位置
          return _buildEditEmptySlot();
        }
      },
    );
  }

  /// 建構編輯頁面的照片槽（2x2網格中的單個照片）
  Widget _buildEditPhotoSlot(Map<String, dynamic> photoData) {
    // 計算這是第幾張照片（在所有照片中的位置）
    final allPhotos = <Map<String, dynamic>>[];
    
    // 重新構建所有照片列表來確定位置
    for (int i = 0; i < _existingPhotoUrls.length; i++) {
      allPhotos.add({
        'type': 'network',
        'path': _existingPhotoUrls[i],
        'listType': 'existing',
        'listIndex': i,
        'isExisting': true,
      });
    }
    
    for (int i = 0; i < _uploadedPhotos.length; i++) {
      allPhotos.add({
        'type': 'file',
        'path': _uploadedPhotos[i],
        'listType': 'uploaded',
        'listIndex': i,
        'isExisting': false,
      });
    }
    
    // 找到當前照片在所有照片中的索引
    final photoIndex = allPhotos.indexWhere((photo) => 
      photo['path'] == photoData['path'] && 
      photo['listType'] == photoData['listType']
    );
    
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: photoData['type'] == 'network'
                ? Image.network(
                    photoData['path'],
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(
                            Icons.error_outline,
                            color: Colors.grey,
                            size: 32,
                          ),
                        ),
                      );
                    },
                  )
                : Image.file(
                    File(photoData['path']),
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        // 刪除按鈕
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (photoData['listType'] == 'existing') {
                  _existingPhotoUrls.removeAt(photoData['listIndex']);
                } else {
                  _uploadedPhotos.removeAt(photoData['listIndex']);
                }
              });
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
        // 封面標籤（只在第一張照片顯示）
        if (photoIndex == 0)
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                '封面',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        // 照片類型標籤（現有照片標籤，顯示在左下角）
        if (photoData['isExisting'])
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '現有',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 建構編輯頁面的新增照片按鈕（虛線方框 + icon）
  Widget _buildEditAddPhotoSlot() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: CustomPaint(
        painter: DashedBorderPainter(
          color: Colors.grey.shade300,
          strokeWidth: 2.0,
          borderRadius: 12.0,
          dashWidth: 8.0,
          dashSpace: 4.0,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.transparent,
          ),
          child: const Center(
            child: Icon(
              Icons.add,
              size: 32,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  /// 建構編輯頁面的空白位置
  Widget _buildEditEmptySlot() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
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