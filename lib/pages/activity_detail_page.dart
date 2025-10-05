import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../components/design_system/app_colors.dart';
import '../components/design_system/custom_button.dart';
import '../components/design_system/success_popup.dart';
import '../components/design_system/custom_snackbar.dart';
import '../components/design_system/activity_status_badge.dart';
import '../components/design_system/registration_status_popup.dart';
import '../services/auth_service.dart';
import '../services/activity_service.dart';
import 'my_activities_page.dart';
import 'home.dart';
import 'edit_activity_page.dart';

class ActivityDetailPage extends StatefulWidget {
  final String activityId;
  final Map<String, dynamic>? activityData; // 可選的預載數據

  const ActivityDetailPage({
    super.key,
    required this.activityId,
    this.activityData,
  });

  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final ActivityService _activityService = ActivityService();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _topBarAnimationController;
  late Animation<Offset> _topBarSlideAnimation;
  
  Map<String, dynamic>? _activity;
  bool _isLoading = true;
  bool _isMyActivity = false;
  bool _isRegistered = false;
  bool _isCheckingRegistration = true;
  AuthUser? _currentUser;
  YoutubePlayerController? _youtubeController;
  bool _isTopBarVisible = true;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.currentUser;
    
    // 初始化動畫控制器
    _topBarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _topBarSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1),
    ).animate(CurvedAnimation(
      parent: _topBarAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // 設置滾動監聽器
    _scrollController.addListener(_onScroll);
    
    // 總是從Firebase獲取最新數據，確保數據準確性
    _loadActivityDetail();
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    _scrollController.dispose();
    _topBarAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadActivityDetail() async {
    try {
      debugPrint('開始載入活動詳情: ${widget.activityId}');
      final activity = await _activityService.getActivityDetail(widget.activityId);
      
      if (mounted) {
        setState(() {
          _activity = activity;
          _checkIfMyActivity();
          _initializeYoutubePlayer();
          _isLoading = false;
        });
        
        // 檢查報名狀態
        await _checkRegistrationStatus();
        
        if (activity != null) {
          debugPrint('活動詳情載入成功: ${activity['name']}');
        } else {
          debugPrint('活動不存在: ${widget.activityId}');
        }
      }
    } catch (e) {
      debugPrint('載入活動詳情失敗: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        CustomSnackBarBuilder.error(context, '載入活動詳情失敗: $e');
      }
    }
  }

  void _checkIfMyActivity() {
    if (_activity != null && _currentUser != null) {
      // 檢查活動是否由當前用戶發布
      final activityUserId = _activity!['userId'];
      final currentUserId = _currentUser!.uid;
      _isMyActivity = activityUserId == currentUserId;
      debugPrint('檢查活動所有者: activityUserId=$activityUserId, currentUserId=$currentUserId, isMyActivity=$_isMyActivity');
    }
  }

  Future<void> _checkRegistrationStatus() async {
    if (_currentUser == null || _isMyActivity) {
      setState(() {
        _isCheckingRegistration = false;
      });
      return;
    }

    try {
      final isRegistered = await _activityService.isUserRegistered(
        userId: _currentUser!.uid,
        activityId: widget.activityId,
      );
      
      if (mounted) {
        setState(() {
          _isRegistered = isRegistered;
          _isCheckingRegistration = false;
        });
      }
    } catch (e) {
      debugPrint('檢查報名狀態失敗: $e');
      if (mounted) {
        setState(() {
          _isCheckingRegistration = false;
        });
      }
    }
  }

  void _onScroll() {
    const threshold = 100.0;
    final offset = _scrollController.offset;
    
    if (offset > threshold && _isTopBarVisible) {
      setState(() {
        _isTopBarVisible = false;
      });
      _topBarAnimationController.forward();
    } else if (offset <= threshold && !_isTopBarVisible) {
      setState(() {
        _isTopBarVisible = true;
      });
      _topBarAnimationController.reverse();
    }
  }

  void _initializeYoutubePlayer() {
    if (_activity != null) {
      final youtubeUrl = _activity!['youtubeUrl'];
      if (youtubeUrl != null && youtubeUrl.toString().isNotEmpty) {
        try {
          final videoId = YoutubePlayer.convertUrlToId(youtubeUrl);
          if (videoId != null) {
            _youtubeController?.dispose(); // 清理之前的控制器
            _youtubeController = YoutubePlayerController(
              initialVideoId: videoId,
              flags: const YoutubePlayerFlags(
                autoPlay: false,
                mute: false,
                enableCaption: true,
                captionLanguage: 'zh-TW',
              ),
            );
            debugPrint('YouTube 播放器初始化成功: $videoId');
          } else {
            debugPrint('無效的 YouTube URL: $youtubeUrl');
          }
        } catch (e) {
          debugPrint('YouTube 播放器初始化失敗: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_activity == null) {
      return Scaffold(
        body: const Center(
          child: Text(
            '活動不存在',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 主要內容區域
          Column(
            children: [
              // 活動詳情內容
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 頂部間距
                      const SizedBox(height: 140),
                      
                      // 活動封面圖片
                      _buildCoverImage(),
                      
                      // 活動內容
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 活動標題
                            _buildTitle(),
                            
                            const SizedBox(height: 24),
                            
                            // 主辦者資訊卡片
                            _buildOrganizerCard(),
                            
                            const SizedBox(height: 24),

                            _buildDivider(),

                            const SizedBox(height: 24),
                            
                            // 日期時間
                            _buildDateTimeInfo(),
                            
                            const SizedBox(height: 24),
                            _buildDivider(),
                            const SizedBox(height: 24),
                            
                            // 報名費用
                            _buildPriceInfo(),
                            
                            const SizedBox(height: 24),
                            _buildDivider(),
                            const SizedBox(height: 24),
                            
                            // 地點資訊
                            _buildLocationInfo(),
                            
                            const SizedBox(height: 24),
                            _buildDivider(),
                            const SizedBox(height: 24),
                            
                            // 人數資訊
                            _buildParticipantsInfo(),
                            
                            const SizedBox(height: 24),
                            _buildDivider(),
                            const SizedBox(height: 24),
                            
                            // 活動介紹
                            _buildDescription(),
                            
                            // 底部按鈕留空間
                            const SizedBox(height: 90),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // 底部按鈕
              _buildBottomBar(),
            ],
          ),
          
          // 頂部操作欄
          _buildTopBar(),
        ],
      ),
    );
  }

  Widget _buildCoverImage() {
    final images = _getActivityImages();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Stack(
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
                child: images.isNotEmpty
                    ? PageView.builder(
                        itemCount: images.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              image: DecorationImage(
                                image: NetworkImage(images[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.image,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          
          // 頁數標籤（如果有多張圖片）
          if (images.length > 1)
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
                  '${_currentImageIndex + 1}/${images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          
          // 分頁指示器（如果有多張圖片）
          if (images.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _buildPageIndicators(images.length),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    final status = _getActivityStatus();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 狀態標籤（如果有的話）
        if (status != null) ...[
          StatusBadgeBuilder.medium(status),
          const SizedBox(height: 24),
        ],
        
        // 活動標題
        Text(
          _activity!['name'] ?? '活動名稱',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.black,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: Colors.grey.shade200,
    );
  }

  Widget _buildDateTimeInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.schedule,
              size: 20,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              '日期',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _formatDateTime(),
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.attach_money,
              size: 20,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              '報名費用',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _formatPrice(_activity!['price']),
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 20,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              '地點',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _getLocationText(),
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantsInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.people_alt_outlined,
              size: 20,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              '人數',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _getParticipantsText(),
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }


  Widget _buildDescription() {
    final introduction = _activity!['introduction'] ?? '暫無活動介紹';
    final youtubeUrl = _activity!['youtubeUrl'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.description_outlined,
              size: 20,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            const Text(
              '活動介紹',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // YouTube 影片（如果有的話）
        if (youtubeUrl != null && youtubeUrl.toString().isNotEmpty && _youtubeController != null) ...[
          Container(
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
                controller: _youtubeController!,
                showVideoProgressIndicator: true,
                progressIndicatorColor: AppColors.primary900,
                progressColors: ProgressBarColors(
                  playedColor: AppColors.primary900,
                  handleColor: AppColors.primary900,
                ),
                onReady: () {
                  debugPrint('YouTube 播放器準備就緒');
                },
                onEnded: (data) {
                  debugPrint('YouTube 影片播放結束');
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
        ] else if (youtubeUrl != null && youtubeUrl.toString().isNotEmpty) ...[
          // YouTube URL 存在但播放器初始化失敗時的備用顯示
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'YouTube 影片載入失敗',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '請檢查網路連線',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // 活動介紹文字
        Text(
          introduction,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
      ],
    );
  }


  Widget _buildOrganizerCard() {
    final user = _activity!['user'];
    final organizerName = user != null ? user['name'] ?? '主辦者' : '主辦者';
    final organizerRating = user != null ? user['rating'] ?? '5.0' : '5.0';
    final avatarUrl = user != null ? user['avatar'] : null;
    final userStatus = user != null ? user['status'] ?? 'pending' : 'pending';
    final kycStatus = user != null ? user['kycStatus'] : null;
    final accountType = user != null ? user['accountType'] : null;
    
    // 調試資訊
    debugPrint('=== 主辦者卡片資訊 ===');
    debugPrint('完整用戶資料: $user');
    debugPrint('活動發布者ID: ${_activity!['userId']}');
    debugPrint('當前用戶ID: ${_currentUser?.uid}');
    debugPrint('是否為我的活動: $_isMyActivity');
    debugPrint('主辦者姓名: $organizerName');
    debugPrint('主辦者評分: $organizerRating');
    debugPrint('頭像URL: $avatarUrl');
    debugPrint('用戶狀態: $userStatus');
    debugPrint('KYC 狀態: $kycStatus');
    debugPrint('帳號類型: $accountType');
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Row(
        children: [
          // 主辦者頭像
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade300,
              border: Border.all(
                color: AppColors.grey100,
                width: 1,
              ),
              image: avatarUrl != null && avatarUrl.toString().isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(avatarUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: avatarUrl == null || avatarUrl.toString().isEmpty
                ? Icon(
                    Icons.person,
                    color: Colors.grey.shade600,
                    size: 28,
                  )
                : null,
          ),
          
          const SizedBox(width: 12),
          
          // 主辦者資訊
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        organizerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 認證標誌（根據 KYC 狀態顯示）
                    _buildVerificationBadge(userStatus, kycStatus),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    ...List.generate(5, (index) {
                      final rating = double.tryParse(organizerRating.toString()) ?? 5.0;
                      return Icon(
                        index < rating.floor() ? Icons.star : Icons.star_border,
                        size: 16,
                        color: Colors.orange.shade400,
                      );
                    }),
                    const SizedBox(width: 8),
                    Text(
                      organizerRating.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
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
    );
  }

  /// 根據 KYC 狀態建立認證標誌
  Widget _buildVerificationBadge(String userStatus, String? kycStatus) {
    final user = _activity!['user'];
    final accountType = user != null ? user['accountType'] : null;
    final isBusinessAccount = accountType == 'business';
    
    if (userStatus == 'approved' && kycStatus == 'approved') {
      // KYC 已通過 - 顯示綠色認證標誌
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isBusinessAccount ? Icons.business : Icons.verified,
              size: 12,
              color: Colors.green.shade600,
            ),
            const SizedBox(width: 2),
            Text(
              isBusinessAccount ? '企業已認證' : '身份已認證',
              style: TextStyle(
                fontSize: 10,
                color: Colors.green.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } else if (kycStatus == 'pending') {
      // KYC 審核中 - 顯示橙色待審核標誌
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.schedule,
              size: 12,
              color: Colors.orange.shade600,
            ),
            const SizedBox(width: 2),
            Text(
              isBusinessAccount ? '企業審核中' : '審核中',
              style: TextStyle(
                fontSize: 10,
                color: Colors.orange.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } else if (kycStatus == 'rejected') {
      // KYC 被拒絕 - 顯示紅色未認證標誌
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 12,
              color: Colors.red.shade600,
            ),
            const SizedBox(width: 2),
            Text(
              isBusinessAccount ? '企業未認證' : '未認證',
              style: TextStyle(
                fontSize: 10,
                color: Colors.red.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } else {
      // 沒有 KYC 資料或其他狀態 - 顯示灰色未認證標誌
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isBusinessAccount ? Icons.business_outlined : Icons.help_outline,
              size: 12,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 2),
            Text(
              isBusinessAccount ? '企業未認證' : '未認證',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildTopBar() {
    return SlideTransition(
      position: _topBarSlideAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 8),
            child: Row(
              children: [
                // 返回按鈕
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.black,
                      size: 20,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                  ),
                ),
                
                const Spacer(),
                
                
                // 取消報名/取消發布按鈕
                if (_currentUser != null)
                  _buildTopBarActionButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBarActionButton() {
    if (_isMyActivity) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 取消發布按鈕
          CustomButton(
            onPressed: () => _showCancelPublishDialog(),
            text: '取消發布',
            width: 120,
            height: 54.0,
            style: CustomButtonStyle.info,
            borderRadius: 40.0,
            fontSize: 16,
          ),
          
          if (_canTogglePublishStatus())
            const SizedBox(width: 12),
          
          // 上架/草稿切換按鈕（只有在沒有報名者時顯示）
          if (_canTogglePublishStatus())
            CustomButton(
              onPressed: () => _togglePublishStatus(),
              text: _isActivityDraft() ? '上架' : '下架編輯',
              width: _isActivityDraft() ? 80: 120,
              height: 52.0,
              style: CustomButtonStyle.outline,
              borderColor: _isActivityDraft() ? AppColors.success700 : AppColors.grey300,
              textColor: _isActivityDraft() ? AppColors.success900 : AppColors.grey500,
              borderWidth: 1.5,
              borderRadius: 40.0,
              fontSize: 16,
            ),
        ],
      );
    } else if (_isRegistered) {
      return CustomButton(
        onPressed: () => _showCancelRegistrationDialog(),
        text: '取消報名',
        width: 120,
        height: 54.0,
        style: CustomButtonStyle.info,
        borderRadius: 40.0,
        fontSize: 16,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 16),
          child: _buildBottomBarContent(),
        ),
      ),
    );
  }

  Widget _buildBottomBarContent() {
    if (_isCheckingRegistration) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_isMyActivity) {
      return _buildMyActivityButton();
    } else if (_isRegistered) {
      return _buildRegisteredButton();
    } else {
      return _buildJoinActivityButton();
    }
  }

  Widget _buildMyActivityButton() {
    // 如果是草稿狀態，顯示編輯按鈕和查看報名狀況按鈕
    if (_isActivityDraft()) {
      return Row(
        children: [
          Expanded(
            child: CustomButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EditActivityPage(
                      activityId: widget.activityId,
                      activityData: _activity!,
                    ),
                  ),
                ).then((_) {
                  // 編輯完成後重新載入活動詳情
                  _loadActivityDetail();
                });
              },
              text: '編輯',
              width: double.infinity,
              height: 52.0,
              style: CustomButtonStyle.outline,
              borderColor: AppColors.success700,
              textColor: AppColors.success900,
              borderWidth: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ButtonBuilder.primary(
              onPressed: () {
                RegistrationStatusPopupBuilder.show(
                  context,
                  activityId: widget.activityId,
                  activityName: _activity!['name'] ?? '活動',
                );
              },
              text: '查看報名狀況',
              width: double.infinity,
              height: 54.0,
            ),
          ),
        ],
      );
    } else {
      // 非草稿狀態，只顯示查看報名狀況按鈕
      return ButtonBuilder.primary(
        onPressed: () {
          RegistrationStatusPopupBuilder.show(
            context,
            activityId: widget.activityId,
            activityName: _activity!['name'] ?? '活動',
          );
        },
        text: '查看報名狀況',
        width: double.infinity,
        height: 54.0,
      );
    }
  }

  Widget _buildRegisteredButton() {
    return ButtonBuilder.primary(
      onPressed: () {
        // TODO: 實現顯示報到條碼功能
        CustomSnackBarBuilder.info(context, '顯示報到條碼功能即將推出');
      },
      text: '顯示報到條碼',
      width: double.infinity,
      height: 54.0,
    );
  }

  Widget _buildJoinActivityButton() {
    final price = _activity!['price'];
    final priceText = _formatPrice(price);
    
    return Container(
      height: 54.0,
      child: Row(
        children: [
          // 價格標籤和價格垂直排列
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '活動報名費用',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                priceText,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  decoration: TextDecoration.underline,
                  decorationThickness: 2,
                ),
              ),
            ],
          ),
          
          const Spacer(),
          
          // 立即報名按鈕
          ButtonBuilder.primary(
            onPressed: () => _handleRegistration(),
            text: '立即報名',
            width: 140,
            height: 54.0,
          ),
        ],
      ),
    );
  }

  List<String> _getActivityImages() {
    List<String> images = [];
    
    // 首先檢查 cover 圖片
    if (_activity!['cover'] != null && _activity!['cover'].toString().isNotEmpty) {
      images.add(_activity!['cover']);
    }
    
    // 檢查 images 字段（編輯活動時使用）
    if (_activity!['images'] != null && _activity!['images'] is List) {
      final imageList = _activity!['images'] as List;
      for (final imageUrl in imageList) {
        if (imageUrl != null && imageUrl.toString().isNotEmpty) {
          final url = imageUrl.toString();
          if (!images.contains(url)) {
            images.add(url);
          }
        }
      }
    }
    
    // 然後檢查 files 中的圖片（創建活動時使用）
    if (_activity!['files'] != null && _activity!['files'] is List) {
      final files = _activity!['files'] as List;
      for (final file in files) {
        if (file is Map<String, dynamic> && file['url'] != null) {
          final url = file['url'].toString();
          if (url.isNotEmpty && !images.contains(url)) {
            images.add(url);
          }
        }
      }
    }
    
    debugPrint('活動圖片載入: 總共找到 ${images.length} 張圖片');
    debugPrint('圖片URLs: $images');
    
    return images;
  }

  List<Widget> _buildPageIndicators(int count) {
    return List.generate(count, (index) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: index == _currentImageIndex ? Colors.white : Colors.white.withValues(alpha: 0.5),
        ),
      );
    });
  }

  String _formatDateTime() {
    final startDateTime = _activity!['startDateTime'];
    final endDateTime = _activity!['endDateTime'];
    
    if (startDateTime == null) return '時間未提供';
    
    try {
      final start = DateTime.parse(startDateTime);
      final weekdays = ['日', '一', '二', '三', '四', '五', '六'];
      final weekday = weekdays[start.weekday % 7];
      
      String dateStr = '${start.year}/${start.month}/${start.day} ($weekday)';
      
      if (endDateTime != null) {
        final end = DateTime.parse(endDateTime);
        String timeStr = '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
        return '$dateStr $timeStr';
      } else {
        String timeStr = '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
        return '$dateStr $timeStr';
      }
    } catch (e) {
      return '時間格式錯誤';
    }
  }

  String _formatPrice(dynamic price) {
    if (price == null || price == 0 || price < 50) {
      return '免費';
    }
    
    if (price is int) {
      return '\$${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} TWD';
    }
    
    return price.toString();
  }

  String _getLocationText() {
    final isOnline = _activity!['isOnline'] ?? false;
    if (isOnline) {
      return '線上活動';
    }
    
    final address = _activity!['address'] ?? '';
    final locationName = _activity!['locationName'] ?? '';
    final city = _activity!['city'] ?? '';
    final area = _activity!['area'] ?? '';
    
    if (locationName.isNotEmpty) {
      return locationName;
    }
    
    if (address.isNotEmpty) {
      if (city.isNotEmpty && area.isNotEmpty) {
        return '$city$area';
      } else {
        return address;
      }
    }
    
    return '地點未提供';
  }

  String _getParticipantsText() {
    final seats = _activity!['seats'];
    
    if (seats == null) {
      return '人數未設定';
    }
    
    if (seats == -1) {
      return '不限人數';
    }
    
    return '共 $seats 人';
  }

  /// 獲取活動狀態
  ActivityStatus? _getActivityStatus() {
    if (_activity == null || _currentUser == null) return null;
    
    // 如果是我的活動
    if (_isMyActivity) {
      final status = _activity!['status'] ?? 'published';
      final activityType = _activity!['type'] ?? 'event';
      final draftReason = _activity!['draftReason'] as String?;
      return ActivityStatusUtils.fromString(status, activityType, draftReason: draftReason);
    }
    
    // 如果已報名
    if (_isRegistered) {
      // 這裡可以根據報名狀態來決定
      // 目前簡單返回報名成功狀態
      return ActivityStatus.registrationSuccess;
    }
    
    // 未報名的活動不顯示狀態標籤
    return null;
  }

  void _showCancelPublishDialog() {
    SuccessPopupBuilder.cancelPublish(
      context,
      onConfirm: () {
        Navigator.of(context).pop();
        _handleCancelPublish();
      },
    );
  }

  void _showCancelRegistrationDialog() {
    SuccessPopupBuilder.cancelRegistration(
      context,
      onConfirm: () {
        Navigator.of(context).pop();
        _handleCancelRegistration();
      },
    );
  }

  Future<void> _handleRegistration() async {
    if (_currentUser == null) {
      CustomSnackBarBuilder.error(context, '請先登入');
      return;
    }

    try {
      debugPrint('=== 開始處理活動報名 ===');
      debugPrint('用戶ID: ${_currentUser!.uid}');
      debugPrint('活動ID: ${widget.activityId}');
      debugPrint('用戶Email: ${_currentUser!.email}');
      
      // 顯示載入狀態
      if (mounted) {
        CustomSnackBarBuilder.info(context, '正在處理報名...');
      }

      await _activityService.registerForActivity(
        activityId: widget.activityId,
        userId: _currentUser!.uid,
      );

      debugPrint('=== 報名處理完成 ===');

      if (mounted) {
        setState(() {
          _isRegistered = true;
        });
        
        // 先清除所有 SnackBar 和 CustomSnackBar
        ScaffoldMessenger.of(context).clearSnackBars();
        CustomSnackBarBuilder.clearAll();
        
        // 顯示報名成功popup（底部彈出）
        SuccessPopupBuilder.activityRegistrationBottom(
          context,
          onConfirm: () {
            Navigator.of(context).pop();
          },
        );
        
        // 觸發我的活動頁面重整
        MyActivitiesPageController.refreshActivities();
        
        // 觸發首頁重整
        HomePageController.refreshActivities();
        
        // 重新檢查報名狀態以確認
        await _checkRegistrationStatus();
      }
    } catch (e) {
      debugPrint('=== 報名處理失敗 ===');
      debugPrint('錯誤詳情: $e');
      debugPrint('錯誤類型: ${e.runtimeType}');
      
      if (mounted) {
        CustomSnackBarBuilder.error(context, '報名失敗: $e');
      }
    }
  }

  Future<void> _handleCancelRegistration() async {
    if (_currentUser == null) return;

    try {
      await _activityService.cancelRegistration(
        userId: _currentUser!.uid,
        activityId: widget.activityId,
      );

      if (mounted) {
        setState(() {
          _isRegistered = false;
        });
        
        CustomSnackBarBuilder.success(context, '已取消報名');
        
        // 觸發我的活動頁面重整
        MyActivitiesPageController.refreshActivities();
        
        // 觸發首頁重整
        HomePageController.refreshActivities();
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBarBuilder.error(context, '取消報名失敗: $e');
      }
    }
  }

  Future<void> _handleCancelPublish() async {
    try {
      await _activityService.updateActivityStatus(
        activityId: widget.activityId,
        status: 'cancelled',
      );

      if (mounted) {
        CustomSnackBarBuilder.success(context, '活動已取消發布');
        
        // 觸發我的活動頁面重整
        MyActivitiesPageController.refreshActivities();
        
        // 觸發首頁重整
        HomePageController.refreshActivities();
        
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBarBuilder.error(context, '取消發布失敗: $e');
      }
    }
  }

  /// 檢查是否可以切換發布狀態
  bool _canTogglePublishStatus() {
    if (_activity == null) return false;
    
    // 只有活動狀態為 active 或 draft 時才能切換
    final status = _activity!['status'] as String?;
    if (status != 'active' && status != 'draft') return false;
    
    // 如果是草稿狀態，需要檢查草稿原因
    if (status == 'draft') {
      final draftReason = _activity!['draftReason'] as String?;
      // KYC 待審核狀態不允許手動切換，需要等待自動上架
      if (draftReason == 'kyc_pending' || draftReason == 'kyc_required') {
        return false;
      }
      return true;
    }
    
    // 已上架的活動需要檢查是否有報名者
    // 目前先允許切換，實際檢查會在切換時進行
    return true;
  }

  /// 檢查活動是否為草稿狀態
  bool _isActivityDraft() {
    if (_activity == null) return false;
    return _activity!['status'] == 'draft';
  }

  /// 切換活動的發布狀態
  Future<void> _togglePublishStatus() async {
    if (_activity == null) return;
    
    try {
      final currentStatus = _activity!['status'] as String?;
      final willPublish = currentStatus == 'draft';
      
      // 如果要下架（從 active 變為 draft），需要檢查是否有報名者
      if (!willPublish && currentStatus == 'active') {
        final registrationCount = await _activityService.getActivityRegistrationCount(widget.activityId);
        if (registrationCount > 0) {
          if (mounted) {
            CustomSnackBarBuilder.error(context, '活動已有 $registrationCount 人報名，無法下架');
          }
          return;
        }
      }
      
      await _activityService.toggleActivityPublishStatus(
        activityId: widget.activityId,
        publish: willPublish,
      );
      
      // 重新載入活動詳情
      await _loadActivityDetail();
      
      if (mounted) {
        CustomSnackBarBuilder.success(
          context, 
          willPublish ? '活動已上架' : '活動已下架為草稿'
        );
        
        // 觸發我的活動頁面重整
        MyActivitiesPageController.refreshActivities();
        
        // 觸發首頁重整
        HomePageController.refreshActivities();
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBarBuilder.error(context, '切換狀態失敗: $e');
      }
    }
  }

}
