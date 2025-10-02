import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
import '../services/activity_service.dart';
import 'main_navigation.dart';

/// 發布活動頁面
class CreateActivityPage extends StatefulWidget {
  const CreateActivityPage({super.key});

  @override
  CreateActivityPageState createState() => CreateActivityPageState();
}

class CreateActivityPageState extends State<CreateActivityPage> with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  int _currentStep = 1;
  final int _totalSteps = 8;
  double _previousViewInsetsBottom = 0;
  
  // 服務實例
  final ActivityService _activityService = ActivityService();
  
  // 步驟一：營利活動確認
  bool? _isProfitActivity;
  
  // 步驟二：發布類型
  String? _activityType;
  
  // 步驟三：舉辦方式
  String? _hostingMethod;
  
  // 步驟四：基本資料
  final TextEditingController _nameController = TextEditingController();
  String? _category;
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  final TextEditingController _locationController = TextEditingController();
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
  bool _canProceedFromStep1() => _isProfitActivity != null;
  bool _canProceedFromStep2() => _activityType != null;
  bool _canProceedFromStep3() => _hostingMethod != null;
  bool _canProceedFromStep4() {
    return _nameController.text.trim().isNotEmpty &&
           _category != null &&
           _startDate != null &&
           _startTime != null &&
           _endDate != null &&
           _endTime != null &&
           _addressController.text.trim().isNotEmpty;
  }
  bool _canProceedFromStep5() => _introductionController.text.trim().isNotEmpty;
  bool _canProceedFromStep6() => _uploadedPhotos.isNotEmpty;
  bool _canProceedFromStep7() => true; // 價格設定總是可以繼續

  VoidCallback? _getNextStepAction() {
    switch (_currentStep) {
      case 1: return _canProceedFromStep1() ? _nextStep : () => _showStep1Errors();
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
    });

      // 顯示錯誤提示
      CustomSnackBarBuilder.validationError(context, '請完成所有必填欄位');
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

      // 準備活動資料
      final activityData = {
        'name': _nameController.text.trim(),
        'type': _activityType == 'individual' ? 'event' : 'task',
        'status': 'active',
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



  /// 將分類顯示名稱轉換為資料庫鍵值
  String _getCategoryKey(String displayName) {
    switch (displayName) {
      case '語言教學': return 'EventCategory_language_teaching';
      case '技能體驗': return 'EventCategory_skill_experience';
      case '活動支援': return 'EventCategory_event_support';
      case '生活服務': return 'EventCategory_life_service';
      default: return 'EventCategory_other';
    }
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
                  children: [
                    _buildStep1(), // 營利活動確認
                    _buildStep2(), // 選擇發布類型
                    _buildStep3(), // 選擇舉辦方式
                    _buildStep4(), // 填寫基本資料
                    _buildStep5(), // 填寫描述內容
                    _buildStep6(), // 新增相片
                    _buildStep7(), // 設定價格
                    _buildStep8(), // 確認發布內容
                  ],
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
              title: '單辦活動 / 開課程',
              icon: Icons.person,
              isSelected: _activityType == 'individual',
              onTap: () {
                setState(() {
                  _activityType = 'individual';
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            _buildOptionCard(
              title: '找幫手 / 任務委託',
              icon: Icons.people,
              isSelected: _activityType == 'group',
              onTap: () {
                setState(() {
                  _activityType = 'group';
                });
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
            DropdownBuilder.dialog<String>(
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
              items: const [
                DropdownItem(value: '語言教學', label: '語言教學'),
                DropdownItem(value: '技能體驗', label: '技能體驗'),
                DropdownItem(value: '活動支援', label: '活動支援'),
                DropdownItem(value: '生活服務', label: '生活服務'),
              ],
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
              '新增幾張相片',
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
            
            // 顯示已上傳的相片
            if (_uploadedPhotos.isNotEmpty) ...[
              const Text(
                '已上傳的相片',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _uploadedPhotos.length,
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(7), // 稍微小一點以適應外框
                          child: Image.file(
                            File(_uploadedPhotos[index]),
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _uploadedPhotos.removeAt(index);
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
                      ],
                    ),
                  );
                },
              ),
            ],
            
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
            
            const Text(
              '請輸入每人報名費用，盈利最低金額 50 TWD。',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 價格調整器（移除外框和高度限制）
            Row(
              children: [
                GestureDetector(
                  onTap: () {
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
                  },
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
                        color: _price >= 50 ? Colors.grey : Colors.grey.shade300,
                      ),
                  ),
                ),
                
                Expanded(
                  child: Center(
                    child: _buildEditablePriceInput(),
                  ),
                ),
                
                GestureDetector(
                  onTap: () {
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
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Icon(
                      Icons.add, 
                      size: 24,
                      color: Colors.grey,
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
            
            // 1. 照片水平滑動預覽
            if (_uploadedPhotos.isNotEmpty) ...[
              SizedBox(
                height: 200,
                child: PageView.builder(
                  controller: PageController(viewportFraction: 0.85), // 讓下一張圖片露出部分
                  itemCount: _uploadedPhotos.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11), // 稍微小一點以適應外框
                        child: Image.file(
                          File(_uploadedPhotos[index]),
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // 2. 活動標題
            _buildSectionHeader('活動標題'),
            _buildSectionContent(_nameController.text),
            _buildDivider(),
            
            // 3. 類別
            _buildSectionHeader('類別'),
            _buildSectionContent(_category ?? ''),
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
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
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
        onTap: () {
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
        },
        child: const Text(
          '免費',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.black,
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
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.black,
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

  /// 處理價格輸入，自動調整到最近的50級距
  int _adjustPriceToStep(int inputPrice) {
    if (inputPrice <= 50) {
      return 0; // 0-50顯示為免費
    }
    
    if (inputPrice > 30000) {
      return 30000; // 最高30000
    }
    
    // 調整到最近的50級距
    return ((inputPrice + 25) ~/ 50) * 50;
  }

  /// 獲取價格顯示文字
  String _getPriceDisplayText() {
    if (_price == 0) {
      return '免費';
    }
    return '\$${_price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  /// 更新價格並同步控制器
  void _updatePrice(int newPrice) {
    setState(() {
      _price = _adjustPriceToStep(newPrice);
      _priceController.text = _price.toString();
    });
  }

  /// 顯示價格編輯對話框
  void _showPriceEditDialog() {
    final TextEditingController tempController = TextEditingController(
      text: _price.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('設定價格'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tempController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '金額 (TWD)',
                border: OutlineInputBorder(),
                helperText: '輸入 0-50 顯示免費，690 會調整為 700',
              ),
              onChanged: (value) {
                // 即時預覽調整後的價格
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final number = int.tryParse(tempController.text);
              if (number != null && number >= 0) {
                _updatePrice(number);
              }
              Navigator.of(context).pop();
            },
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  /// 處理價格輸入，自動調整到最近的50級距
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
