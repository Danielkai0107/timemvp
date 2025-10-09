import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../components/design_system/app_colors.dart';
import '../components/design_system/custom_button.dart';
import '../components/design_system/success_popup.dart';
import '../components/design_system/custom_snackbar.dart';
import '../components/design_system/activity_status_badge.dart';
import '../components/design_system/registration_status_popup.dart';
import '../components/design_system/activity_rating_popup.dart';
import '../components/design_system/organizer_rating_popup.dart';
import '../components/design_system/skeleton_loader.dart';
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
  String? _registrationStatus; // 詳細的報名狀態
  AuthUser? _currentUser;
  YoutubePlayerController? _youtubeController;
  bool _isTopBarVisible = true;
  int _currentImageIndex = 0;
  List<Map<String, dynamic>> _activityRatings = [];
  bool _isLoadingRatings = false;
  List<Map<String, dynamic>> _organizerRatings = [];
  bool _isLoadingOrganizerRatings = false;
  bool _allDataLoaded = false; // 追蹤所有數據是否載入完成

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
    
    // 檢查是否需要顯示評分彈窗
    _checkAndShowRatingPopup();
    
    // 檢查是否需要顯示發布者評分參與者彈窗
    _checkAndShowOrganizerRatingPopup();
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
        
        // 載入評分數據
        await _loadActivityRatings();
        
        // 載入發布者評分數據
        await _loadOrganizerRatings();
        
        // 所有數據載入完成
        setState(() {
          _allDataLoaded = true;
        });
        
        
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
          _allDataLoaded = true; // 即使失敗也設為true，避免一直顯示骨架
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

  /// 載入活動評分數據
  Future<void> _loadActivityRatings() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingRatings = true;
    });

    try {
      final ratings = await _activityService.getActivityRatings(
        activityId: widget.activityId,
        limit: 10,
      );

      if (mounted) {
        setState(() {
          _activityRatings = ratings;
          _isLoadingRatings = false;
        });
      }
    } catch (e) {
      debugPrint('載入活動評分失敗: $e');
      if (mounted) {
        setState(() {
          _activityRatings = [];
          _isLoadingRatings = false;
        });
      }
    }
  }

  /// 載入發布者評分數據
  Future<void> _loadOrganizerRatings() async {
    if (!mounted || _activity == null) return;
    
    final organizerId = _activity!['userId'] as String?;
    if (organizerId == null) return;
    
    setState(() {
      _isLoadingOrganizerRatings = true;
    });

    try {
      final ratings = await _activityService.getUserReceivedRatings(
        userId: organizerId,
        limit: 5, // 只顯示最近5個評分
      );

      if (mounted) {
        setState(() {
          _organizerRatings = ratings;
          _isLoadingOrganizerRatings = false;
        });
      }
    } catch (e) {
      debugPrint('載入發布者評分失敗: $e');
      if (mounted) {
        setState(() {
          _organizerRatings = [];
          _isLoadingOrganizerRatings = false;
        });
      }
    }
  }

  /// 計算發布者的平均評分
  double _calculateOrganizerAverageRating() {
    if (_organizerRatings.isEmpty) {
      // 如果沒有評分記錄，使用用戶資料中的評分
      final user = _activity!['user'];
      if (user != null && user['rating'] != null) {
        return double.tryParse(user['rating'].toString()) ?? 5.0;
      }
      return 5.0;
    }

    // 從評分記錄計算平均評分
    double totalRating = 0.0;
    int ratingCount = 0;

    for (final rating in _organizerRatings) {
      final userRating = rating['userRating'] as int?;
      if (userRating != null) {
        totalRating += userRating.toDouble();
        ratingCount++;
      }
    }

    if (ratingCount == 0) {
      return 5.0;
    }

    return totalRating / ratingCount;
  }

  Future<void> _checkRegistrationStatus() async {
    if (_currentUser == null || _isMyActivity) {
      setState(() {
        _isCheckingRegistration = false;
      });
      return;
    }

    try {
      // 獲取詳細的報名狀態
      final registrationData = await _activityService.getUserRegistrationStatus(
        userId: _currentUser!.uid,
        activityId: widget.activityId,
      );
      
      if (mounted) {
        if (registrationData != null) {
          final status = registrationData['status'] as String?;
          
          setState(() {
            _isRegistered = true;
            _registrationStatus = status;
            _isCheckingRegistration = false;
          });
          
          debugPrint('報名狀態詳情: $_registrationStatus');
        } else {
          setState(() {
            _isRegistered = false;
            _registrationStatus = null;
            _isCheckingRegistration = false;
          });
        }
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
    // 顯示骨架UI直到所有數據載入完成
    if (_isLoading || !_allDataLoaded) {
      return const ActivityDetailSkeleton();
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
                            
                            // 過去評價區塊
                            if (_activityRatings.isNotEmpty) ...[
                              const SizedBox(height: 32),
                              _buildDivider(),
                              const SizedBox(height: 32),
                              _buildPastRatingsSection(),
                            ],
                            
                            // 發布者過去評價區塊
                            if (_organizerRatings.isNotEmpty) ...[
                              const SizedBox(height: 32),
                              _buildDivider(),
                              const SizedBox(height: 32),
                              _buildOrganizerPastRatingsSection(),
                            ],
                            
                            // 提前結束按鈕（只有活動主辦者且活動進行中時顯示）
                            if (_shouldShowEarlyEndButton()) ...[
                              const SizedBox(height: 32),
                              _buildDivider(),
                              const SizedBox(height: 32),
                              _buildEarlyEndButton(),
                            ],
                            
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
    // 使用計算出的平均評分，而不是用戶資料中的評分
    final organizerRating = _calculateOrganizerAverageRating();
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
    debugPrint('主辦者評分: ${organizerRating.toStringAsFixed(1)} (計算自 ${_organizerRatings.length} 個評分)');
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
                      return Icon(
                        index < organizerRating.floor() ? Icons.star : Icons.star_border,
                        size: 16,
                        color: Colors.orange.shade400,
                      );
                    }),
                    const SizedBox(width: 8),
                    Text(
                      organizerRating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${_organizerRatings.length})',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w400,
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
                
                // 臨時調試按鈕 - 手動觸發評分彈窗檢查
                if (_currentUser != null && !_isMyActivity)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.star_outline,
                          color: Colors.orange.shade700,
                          size: 20,
                        ),
                        onPressed: () {
                          debugPrint('🔧 手動觸發評分彈窗檢查');
                          _debugActivityAndRegistrationStatus();
                          _checkAndShowRatingPopup();
                        },
                        padding: EdgeInsets.zero,
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

  Widget _buildTopBarActionButton() {
    // 如果活動已結束或已取消，不顯示任何操作按鈕
    if (_isActivityEndedOrCancelled()) {
      return const SizedBox.shrink();
    }

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
              textColor: _isActivityDraft() ? AppColors.success900 : AppColors.grey700,
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
    // 如果活動已結束或已取消，直接隱藏整個底部bar
    if (_isActivityEndedOrCancelled()) {
      return const SizedBox.shrink();
    }

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
      // 非草稿狀態，檢查活動是否已結束以決定顯示什麼按鈕
      if (_isActivityEndedOrCancelled()) {
        // 活動已結束，顯示評分參與者按鈕
        return Row(
          children: [
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
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                onPressed: () => _showOrganizerRatingPopup(),
                text: '評分參與者',
                width: double.infinity,
                height: 54.0,
                style: CustomButtonStyle.outline,
                borderColor: AppColors.primary900,
                textColor: AppColors.primary900,
                borderWidth: 1.5,
                icon: const Icon(Icons.star_outline),
              ),
            ),
          ],
        );
      } else {
        // 活動進行中，只顯示查看報名狀況按鈕
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
    
    // 如果已報名，需要考慮活動和報名狀態
    if (_isRegistered && _registrationStatus != null) {
      final activityType = _activity!['type'] ?? 'event';
      final activityStatus = _activity!['status'] as String?;
      final endDateTime = _activity!['endDateTime'] as String?;
      
      // 首先檢查是否為取消狀態
      if (_registrationStatus == 'cancelled' || activityStatus == 'cancelled') {
        return ActivityStatus.cancelled;
      }
      
      // 檢查活動是否已結束
      bool isActivityEnded = false;
      
      // 1. 檢查活動狀態是否為 ended
      if (activityStatus == 'ended') {
        isActivityEnded = true;
      }
      
      // 2. 檢查報名狀態是否為 ended
      if (_registrationStatus == 'ended') {
        isActivityEnded = true;
      }
      
      // 3. 檢查是否超過活動結束時間
      if (!isActivityEnded && endDateTime != null) {
        try {
          final endTime = DateTime.parse(endDateTime);
          final now = DateTime.now();
          isActivityEnded = now.isAfter(endTime);
        } catch (e) {
          debugPrint('解析活動結束時間失敗: $e');
        }
      }
      
      // 如果活動已結束，顯示已結束狀態
      if (isActivityEnded) {
        return ActivityStatus.ended;
      }
      
      // 否則根據報名狀態決定
      return ActivityStatusUtils.fromString(_registrationStatus!, activityType);
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
      // 顯示載入狀態
      if (mounted) {
        CustomSnackBarBuilder.info(context, '正在取消活動並通知報名者...');
      }

      // 使用新的取消活動方法，會同時更新活動和報名者狀態
      await _activityService.cancelActivity(
        activityId: widget.activityId,
      );

      if (mounted) {
        CustomSnackBarBuilder.success(context, '活動已取消發布，所有報名者已收到通知');
        
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

  /// 檢查活動是否已結束或已取消
  bool _isActivityEndedOrCancelled() {
    if (_activity == null) return false;
    
    final status = _activity!['status'] as String?;
    
    // 檢查活動狀態
    if (status == 'ended' || status == 'cancelled') {
      return true;
    }
    
    // 檢查是否超過活動結束時間
    final endDateTime = _activity!['endDateTime'] as String?;
    if (endDateTime != null) {
      try {
        final endTime = DateTime.parse(endDateTime);
        final now = DateTime.now();
        if (now.isAfter(endTime)) {
          return true;
        }
      } catch (e) {
        debugPrint('解析活動結束時間失敗: $e');
      }
    }
    
    return false;
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

  /// 檢查並顯示評分彈窗
  Future<void> _checkAndShowRatingPopup() async {
    if (_currentUser == null) {
      debugPrint('❌ 評分彈窗檢查：用戶未登入');
      return;
    }
    
    try {
      debugPrint('=== 開始檢查評分彈窗顯示條件 ===');
      debugPrint('當前用戶: ${_currentUser!.uid}');
      debugPrint('活動ID: ${widget.activityId}');
      debugPrint('是否為我的活動: $_isMyActivity');
      debugPrint('是否已報名: $_isRegistered');
      debugPrint('報名狀態: $_registrationStatus');
      
      // 如果是自己的活動，不需要評分
      if (_isMyActivity) {
        debugPrint('❌ 評分彈窗檢查：這是用戶自己發布的活動，不需要評分');
        return;
      }
      
      // 延遲一點時間，確保頁面已經完全載入
      debugPrint('⏳ 延遲1.5秒後檢查評分條件...');
      await Future.delayed(const Duration(milliseconds: 1500));
      
      if (!mounted) {
        debugPrint('❌ 評分彈窗檢查：頁面已卸載');
        return;
      }
      
      debugPrint('🔍 調用 shouldShowRatingPopup 檢查...');
      final shouldShow = await _activityService.shouldShowRatingPopup(
        userId: _currentUser!.uid,
        activityId: widget.activityId,
      );
      
      debugPrint('📋 shouldShowRatingPopup 結果: $shouldShow');
      
      if (shouldShow && mounted) {
        debugPrint('✅ 符合條件，準備顯示評分彈窗');
        _showRatingPopup();
      } else {
        debugPrint('❌ 不符合條件或頁面已卸載，不顯示評分彈窗');
        debugPrint('   - shouldShow: $shouldShow');
        debugPrint('   - mounted: $mounted');
      }
    } catch (e) {
      debugPrint('❌ 檢查評分彈窗失敗: $e');
      debugPrint('錯誤堆疊: ${e.toString()}');
    }
  }

  /// 顯示評分彈窗
  void _showRatingPopup() {
    debugPrint('=== 準備顯示評分彈窗 ===');
    
    if (_activity == null) {
      debugPrint('❌ 活動數據為空，無法顯示評分彈窗');
      return;
    }
    
    debugPrint('活動名稱: ${_activity!['name']}');
    debugPrint('活動發布者ID: ${_activity!['userId']}');
    
    // 準備主辦方列表
    final organizers = <Map<String, dynamic>>[];
    
    // 添加活動發布者
    final user = _activity!['user'];
    debugPrint('活動發布者資料: $user');
    
    if (user != null) {
      final organizerData = {
        'userId': _activity!['userId'],
        'name': user['name'] ?? '主辦者',
        'avatar': user['avatar'],
      };
      organizers.add(organizerData);
      debugPrint('添加主辦方: $organizerData');
    }
    
    // 如果沒有主辦方資訊，不顯示評分彈窗
    if (organizers.isEmpty) {
      debugPrint('❌ 沒有主辦方資訊，無法顯示評分彈窗');
      return;
    }
    
    debugPrint('✅ 準備顯示評分彈窗，主辦方數量: ${organizers.length}');
    
    try {
      ActivityRatingPopupBuilder.show(
        context,
        activityId: widget.activityId,
        activityName: _activity!['name'] ?? '活動',
        organizers: organizers,
        onSubmit: _handleRatingSubmit,
        onSkip: () {
          debugPrint('用戶跳過評分');
        },
      );
      debugPrint('✅ 評分彈窗已成功調用顯示');
    } catch (e) {
      debugPrint('❌ 顯示評分彈窗失敗: $e');
    }
  }

  /// 處理評分提交
  Future<void> _handleRatingSubmit(Map<String, dynamic> ratings, String? comment) async {
    if (_currentUser == null) return;
    
    try {
      await _activityService.submitActivityRating(
        activityId: widget.activityId,
        raterId: _currentUser!.uid,
        ratings: ratings,
        comment: comment,
      );
      
      if (mounted) {
        Navigator.of(context).pop(); // 關閉評分彈窗
        CustomSnackBarBuilder.success(context, '評分提交成功，謝謝您的回饋！');
        
        // 重新載入評分數據
        await _loadActivityRatings();
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // 關閉評分彈窗
        CustomSnackBarBuilder.error(context, '評分提交失敗: $e');
      }
    }
  }

  /// 建構過去評價區塊
  Widget _buildPastRatingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 標題
        Row(
          children: [
            Icon(
              Icons.star_outline,
              size: 20,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            const Text(
              '過去評價',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${_activityRatings.length} 則評價',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // 評價列表
        if (_isLoadingRatings)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          )
        else
          Column(
            children: _activityRatings.map((rating) => _buildRatingItem(rating)).toList(),
          ),
      ],
    );
  }

  /// 建構單個評價項目
  Widget _buildRatingItem(Map<String, dynamic> rating) {
    final rater = rating['rater'] as Map<String, dynamic>?;
    final raterName = rater?['name'] as String? ?? '匿名用戶';
    final raterAvatar = rater?['avatar'] as String?;
    final comment = rating['comment'] as String?;
    final ratings = rating['ratings'] as Map<String, dynamic>? ?? {};
    final createdAt = rating['createdAt'] as String?;
    
    // 計算平均評分
    double averageRating = 0.0;
    if (ratings.isNotEmpty) {
      final totalRating = ratings.values.fold<double>(0.0, (sum, rating) => sum + (rating as num).toDouble());
      averageRating = totalRating / ratings.length;
    }
    
    // 格式化日期
    String formattedDate = '';
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt);
        formattedDate = '${date.year}/${date.month}/${date.day}';
      } catch (e) {
        formattedDate = '';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 評價者資訊和評分
          Row(
            children: [
              // 頭像
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.grey300,
                  image: raterAvatar != null && raterAvatar.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(raterAvatar),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: raterAvatar == null || raterAvatar.isEmpty
                    ? Icon(
                        Icons.person,
                        color: AppColors.grey700,
                        size: 24,
                      )
                    : null,
              ),
              
              const SizedBox(width: 12),
              
              // 姓名和評分
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      raterName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // 星星評分
                        ...List.generate(5, (index) {
                          return Icon(
                            index < averageRating.floor() ? Icons.star : Icons.star_border,
                            size: 14,
                            color: Colors.orange.shade400,
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          averageRating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // 日期
              if (formattedDate.isNotEmpty)
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
            ],
          ),
          
          // 評論內容
          if (comment != null && comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              comment,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 建構發布者過去評價區塊
  Widget _buildOrganizerPastRatingsSection() {
    final user = _activity!['user'];
    final organizerName = user != null ? user['name'] ?? '主辦者' : '主辦者';
    
    // 從實際評分記錄計算平均評分
    final averageRating = _calculateOrganizerAverageRating();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 標題
        Row(
          children: [
            Icon(
              Icons.verified_user_outlined,
              size: 20,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              '$organizerName 的過去評價',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            // 總體評分（從實際評分記錄計算）
            Row(
              children: [
                Icon(
                  Icons.star,
                  size: 16,
                  color: Colors.orange.shade400,
                ),
                const SizedBox(width: 4),
                Text(
                  averageRating.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${_organizerRatings.length})',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // 評價列表 - 改為水平滑動
        if (_isLoadingOrganizerRatings)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_organizerRatings.isNotEmpty)
          SizedBox(
            height: 200, // 增加高度
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 0),
              itemCount: _organizerRatings.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(
                    right: index == _organizerRatings.length - 1 ? 0 : 12,
                  ),
                  child: _buildOrganizerRatingItem(_organizerRatings[index]),
                );
              },
            ),
          ),
      ],
    );
  }

  /// 建構發布者評價項目
  Widget _buildOrganizerRatingItem(Map<String, dynamic> rating) {
    final rater = rating['rater'] as Map<String, dynamic>?;
    final raterName = rater?['name'] as String? ?? '匿名用戶';
    final raterAvatar = rater?['avatar'] as String?;
    final comment = rating['comment'] as String?;
    final userRating = rating['userRating'] as int? ?? 5;
    // final activity = rating['activity'] as Map<String, dynamic>?;
    // final activityName = activity?['name'] as String? ?? '活動';
    final createdAt = rating['createdAt'] as String?;
    
    // 格式化日期
    String formattedDate = '';
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt);
        formattedDate = '${date.month}/${date.day}';
      } catch (e) {
        formattedDate = '';
      }
    }

    return Container(
      width: 240, // 增加寬度到160px
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, // 白色背景
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.grey300), // 灰框
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 評價者頭像和姓名
          Row(
            children: [
              // 頭像
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.grey300,
                  image: raterAvatar != null && raterAvatar.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(raterAvatar),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: raterAvatar == null || raterAvatar.isEmpty
                    ? Icon(
                        Icons.person,
                        color: AppColors.grey700,
                        size: 20,
                      )
                    : null,
              ),
              
              const SizedBox(width: 8),
              
              // 姓名
              Expanded(
                child: Text(
                  raterName,
                  style: const TextStyle(
                    fontSize: 14, // 統一字體14px
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // 星星評分
          Row(
            children: [
              ...List.generate(5, (index) {
                return Icon(
                  index < userRating ? Icons.star : Icons.star_border,
                  size: 14,
                  color: Colors.orange.shade400,
                );
              }),
              const SizedBox(width: 6),
              Text(
                userRating.toString(),
                style: TextStyle(
                  fontSize: 14, // 統一字體14px
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // 評論內容
          if (comment != null && comment.isNotEmpty)
            Expanded(
              child: Text(
                comment,
                style: TextStyle(
                  fontSize: 14, // 統一字體14px
                  color: Colors.grey.shade700,
                  height: 1.3,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            Expanded(
              child: Text(
                '很棒很活潑很開心良好的體驗',
                style: TextStyle(
                  fontSize: 14, // 統一字體14px
                  color: Colors.grey.shade500,
                  height: 1.3,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          
          const SizedBox(height: 8),
          
          // 日期
          if (formattedDate.isNotEmpty)
            Text(
              formattedDate,
              style: TextStyle(
                fontSize: 14, // 統一字體14px
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
    );
  }

  /// 檢查是否應顯示提前結束按鈕
  bool _shouldShowEarlyEndButton() {
    // 必須是活動主辦者
    if (!_isMyActivity) return false;
    
    // 活動必須存在
    if (_activity == null) return false;
    
    // 活動狀態必須是 active（已上架）
    final status = _activity!['status'] as String?;
    if (status != 'active') return false;
    
    // 檢查活動是否還在進行中（未到結束時間）
    final endDateTime = _activity!['endDateTime'] as String?;
    if (endDateTime == null) return false;
    
    try {
      final endTime = DateTime.parse(endDateTime);
      final now = DateTime.now();
      
      // 只有在活動還未結束時才顯示提前結束按鈕
      return now.isBefore(endTime);
    } catch (e) {
      debugPrint('解析活動結束時間失敗: $e');
      return false;
    }
  }

  /// 建構提前結束按鈕
  Widget _buildEarlyEndButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 標題
        Row(
          children: [
            Icon(
              Icons.stop_circle_outlined,
              size: 20,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            const Text(
              '活動管理',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // 說明文字
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.grey300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '提前結束活動',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '如果活動需要提前結束，點擊下方按鈕。活動結束後，參與者將可以進行評分。',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // 提前結束按鈕
        SizedBox(
          width: double.infinity,
          child: CustomButton(
            onPressed: _showEarlyEndConfirmDialog,
            text: '提前結束活動',
            style: CustomButtonStyle.outline,
            borderColor: AppColors.error900,
            textColor: AppColors.error900,
            height: 52,
            borderWidth: 1.5,
            icon: const Icon(Icons.stop_circle_outlined),
          ),
        ),
      ],
    );
  }

  /// 顯示提前結束確認對話框
  void _showEarlyEndConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認提前結束活動'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('您確定要提前結束這個活動嗎？'),
            const SizedBox(height: 12),
            Text(
              '• 活動狀態將變更為「已結束」\n• 參與者將收到評分邀請\n• 此操作無法撤銷',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
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
              Navigator.of(context).pop();
              _handleEarlyEndActivity();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error900,
            ),
            child: const Text('確認結束'),
          ),
        ],
      ),
    );
  }

  /// 處理提前結束活動
  Future<void> _handleEarlyEndActivity() async {
    try {
      debugPrint('=== 開始提前結束活動 ===');
      debugPrint('活動ID: ${widget.activityId}');
      
      // 顯示載入狀態
      if (mounted) {
        CustomSnackBarBuilder.info(context, '正在結束活動並更新報名者狀態...');
      }

      // 使用新的提前結束方法，會同時更新活動和報名者狀態
      await _activityService.endActivityEarly(
        activityId: widget.activityId,
      );

      debugPrint('活動和報名者狀態已全部更新為已結束');

      if (mounted) {
        // 重新載入活動詳情
        await _loadActivityDetail();
        
        CustomSnackBarBuilder.success(context, '活動已提前結束，所有報名者狀態已更新');
        
        // 觸發我的活動頁面重整
        MyActivitiesPageController.refreshActivities();
        
        // 觸發首頁重整
        HomePageController.refreshActivities();
        
        // 延遲一下後檢查是否需要顯示評分彈窗給參與者
        // 注意：這裡不會顯示給主辦者，因為主辦者不會評分自己的活動
        debugPrint('活動提前結束完成，參與者稍後可以進行評分');
      }
    } catch (e) {
      debugPrint('提前結束活動失敗: $e');
      if (mounted) {
        CustomSnackBarBuilder.error(context, '提前結束活動失敗: $e');
      }
    }
  }

  /// 檢查並顯示發布者評分參與者彈窗
  Future<void> _checkAndShowOrganizerRatingPopup() async {
    if (_currentUser == null) return;
    
    try {
      // 延遲一點時間，確保頁面已經完全載入，並且在參與者評分彈窗之後
      await Future.delayed(const Duration(milliseconds: 2500));
      
      if (!mounted) return;
      
      final shouldShow = await _activityService.shouldShowOrganizerRatingPopup(
        organizerId: _currentUser!.uid,
        activityId: widget.activityId,
      );
      
      if (shouldShow && mounted) {
        _showOrganizerRatingPopup();
      }
    } catch (e) {
      debugPrint('檢查發布者評分彈窗失敗: $e');
    }
  }

  /// 顯示發布者評分參與者彈窗
  void _showOrganizerRatingPopup() async {
    if (_activity == null || _currentUser == null) return;
    
    try {
      // 獲取活動參與者列表
      final participants = await _activityService.getActivityParticipants(
        activityId: widget.activityId,
      );
      
      if (participants.isEmpty) {
        if (mounted) {
          CustomSnackBarBuilder.info(context, '此活動沒有參與者');
        }
        return;
      }
      
      if (mounted) {
        OrganizerRatingPopupBuilder.show(
          context,
          activityId: widget.activityId,
          activityName: _activity!['name'] ?? '活動',
          participants: participants,
          onSubmit: _handleOrganizerRatingSubmit,
          onSkip: () {
            debugPrint('發布者跳過評分參與者');
          },
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBarBuilder.error(context, '載入參與者列表失敗: $e');
      }
    }
  }

  /// 處理發布者評分提交
  Future<void> _handleOrganizerRatingSubmit(Map<String, dynamic> ratings, String? comment) async {
    if (_currentUser == null) return;
    
    try {
      await _activityService.submitOrganizerRating(
        activityId: widget.activityId,
        organizerId: _currentUser!.uid,
        ratings: ratings,
        comment: comment,
      );
      
      if (mounted) {
        Navigator.of(context).pop(); // 關閉評分彈窗
        CustomSnackBarBuilder.success(context, '評分提交成功，謝謝您的回饋！');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // 關閉評分彈窗
        CustomSnackBarBuilder.error(context, '評分提交失敗: $e');
      }
    }
  }

  /// 調試方法：檢查當前活動和報名狀態
  void _debugActivityAndRegistrationStatus() async {
    if (_currentUser == null || _activity == null) return;
    
    debugPrint('=== 調試：當前活動和報名狀態 ===');
    debugPrint('活動ID: ${widget.activityId}');
    debugPrint('當前用戶: ${_currentUser!.uid}');
    debugPrint('活動狀態: ${_activity!['status']}');
    debugPrint('活動結束時間: ${_activity!['endDateTime']}');
    debugPrint('是否為我的活動: $_isMyActivity');
    debugPrint('是否已報名: $_isRegistered');
    debugPrint('報名狀態: $_registrationStatus');
    
    // 檢查實際的報名記錄
    try {
      final registrationData = await _activityService.getUserRegistrationStatus(
        userId: _currentUser!.uid,
        activityId: widget.activityId,
      );
      debugPrint('實際報名記錄: $registrationData');
    } catch (e) {
      debugPrint('獲取報名記錄失敗: $e');
    }
    
    // 檢查是否已評分
    try {
      final hasRated = await _activityService.hasUserRatedActivity(
        userId: _currentUser!.uid,
        activityId: widget.activityId,
      );
      debugPrint('是否已評分: $hasRated');
    } catch (e) {
      debugPrint('檢查評分狀態失敗: $e');
    }
  }


}
