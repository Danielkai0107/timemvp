import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'app_colors.dart';
import '../../services/activity_service.dart';
import '../../services/user_service.dart';

/// 用戶資料卡片彈窗組件
class UserProfilePopup extends StatefulWidget {
  final String userId;
  final Map<String, dynamic>? initialUserData; // 可選的預載用戶數據

  const UserProfilePopup({
    super.key,
    required this.userId,
    this.initialUserData,
  });

  @override
  State<UserProfilePopup> createState() => _UserProfilePopupState();
}

class _UserProfilePopupState extends State<UserProfilePopup>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  final ActivityService _activityService = ActivityService();
  final UserService _userService = UserService();
  
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _organizerRatings = []; // 作為發布者收到的評分
  List<Map<String, dynamic>> _participantRatings = []; // 作為參與者收到的評分
  bool _isLoading = true;
  bool _isLoadingRatings = false;

  @override
  void initState() {
    super.initState();
    
    // 初始化動畫
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    // 開始動畫
    _animationController.forward();
    
    // 載入用戶資料
    _loadUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // 如果有預載數據，先使用預載數據
      if (widget.initialUserData != null) {
        _userData = widget.initialUserData;
        setState(() {
          _isLoading = false;
        });
      } else {
        // 否則從服務獲取用戶基本資料
        final userData = await _userService.getUserBasicInfo(widget.userId);
        if (mounted) {
          setState(() {
            _userData = userData;
            _isLoading = false;
          });
        }
      }

      // 載入評分數據
      await _loadRatings();
    } catch (e) {
      debugPrint('載入用戶資料失敗: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadRatings() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingRatings = true;
    });

    try {
      // 同時載入兩種評分
      final results = await Future.wait([
        _activityService.getUserReceivedRatings(userId: widget.userId, limit: 5),
        _activityService.getUserParticipantRatings(userId: widget.userId, limit: 5),
      ]);

      if (mounted) {
        setState(() {
          _organizerRatings = results[0];
          _participantRatings = results[1];
          _isLoadingRatings = false;
        });
      }
    } catch (e) {
      debugPrint('載入評分數據失敗: $e');
      if (mounted) {
        setState(() {
          _organizerRatings = [];
          _participantRatings = [];
          _isLoadingRatings = false;
        });
      }
    }
  }

  Future<void> _close() async {
    await _animationController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // 背景遮罩
          FadeTransition(
            opacity: _fadeAnimation,
            child: GestureDetector(
              onTap: _close,
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          ),
          
          // 彈窗內容
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
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
                    // 頂部拖拽指示器和關閉按鈕
                    _buildHeader(),
                    
                    // 內容區域
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 用戶資料卡片
                            _buildUserCard(),
                            
                            const SizedBox(height: 32),
                            
                            // 評分區域
                            _buildRatingsSection(),
                            
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 12, bottom: 8, left: 24, right: 24),
      child: Row(
        children: [
          // 拖拽指示器
          Expanded(
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          
          // 關閉按鈕
          GestureDetector(
            onTap: _close,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.close,
                color: AppColors.grey700,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard() {
    if (_isLoading || _userData == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final name = _userData!['name'] as String? ?? '用戶';
    final avatarUrl = _userData!['avatar'] as String?;
    final userStatus = _userData!['status'] as String? ?? 'pending';
    final kycStatus = _userData!['kycStatus'] as String?;
    final accountType = _userData!['accountType'] as String?;
    final rating = _userData!['rating'] as String? ?? '5.0';
    final participantRating = _userData!['participantRating'] as double? ?? 5.0;
    final participantRatingCount = _userData!['participantRatingCount'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 頭像和基本資訊
          Row(
            children: [
              // 大頭像
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.grey300,
                  border: Border.all(
                    color: AppColors.grey300,
                    width: 2,
                  ),
                  image: avatarUrl != null && avatarUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(avatarUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? Icon(
                        Icons.person,
                        color: AppColors.grey700,
                        size: 40,
                      )
                    : null,
              ),
              
              const SizedBox(width: 20),
              
                // 用戶資訊
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 姓名
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // 認證標誌
                      _buildVerificationBadge(userStatus, kycStatus, accountType),
                      
                      const SizedBox(height: 12),
                      
                      // 評分統計
                      _buildRatingStats(rating, participantRating, participantRatingCount),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationBadge(String userStatus, String? kycStatus, String? accountType) {
    final isBusinessAccount = accountType == 'business';
    
    String svgPath;
    String text;
    
    if (userStatus == 'approved' && kycStatus == 'approved') {
      // KYC 已通過
      svgPath = 'assets/images/kyc_success.svg';
      text = isBusinessAccount ? '企業已認證' : '身份已認證';
    } else if (kycStatus == 'pending') {
      // KYC 審核中
      svgPath = 'assets/images/kyc_pending.svg';
      text = isBusinessAccount ? '企業審核中' : '審核中';
    } else if (kycStatus == 'rejected') {
      // KYC 被拒絕
      svgPath = 'assets/images/kyc_error.svg';
      text = isBusinessAccount ? '企業未認證' : '未認證';
    } else {
      // 沒有 KYC 資料或其他狀態
      svgPath = 'assets/images/kyc_error.svg';
      text = isBusinessAccount ? '企業未認證' : '未認證';
    }
    
    return Row(
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
            color: Colors.grey,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingStats(String rating, double participantRating, int participantRatingCount) {
    // 計算發布者平均評分
    final organizerAverageRating = _calculateOrganizerAverageRating();
    final organizerRatingCount = _organizerRatings.length;
    
    // 計算參與者平均評分
    final participantAverageRating = _calculateParticipantAverageRating();
    final actualParticipantRatingCount = _participantRatings.length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 作為發布者的評分
        Row(
          children: [
            Icon(
              Icons.star,
              size: 18,
              color: Colors.orange.shade400,
            ),
            const SizedBox(width: 6),
            Text(
              organizerRatingCount > 0 
                  ? '發布者評分：${organizerAverageRating.toStringAsFixed(1)} ($organizerRatingCount)'
                  : '發布者評分：無',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.grey700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 6),
        
        // 作為參與者的評分
        Row(
          children: [
            Icon(
              Icons.star_outline,
              size: 18,
              color: Colors.orange.shade400,
            ),
            const SizedBox(width: 6),
            Text(
              actualParticipantRatingCount > 0
                  ? '參與者評分：${participantAverageRating.toStringAsFixed(1)} ($actualParticipantRatingCount)'
                  : '參與者評分：無',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.grey700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 計算發布者平均評分（從實際評分記錄計算）
  double _calculateOrganizerAverageRating() {
    if (_organizerRatings.isEmpty) {
      return 0.0;
    }

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
      return 0.0;
    }

    return totalRating / ratingCount;
  }

  /// 計算參與者平均評分（從實際評分記錄計算）
  double _calculateParticipantAverageRating() {
    if (_participantRatings.isEmpty) {
      return 0.0;
    }

    double totalRating = 0.0;
    int ratingCount = 0;

    for (final rating in _participantRatings) {
      final userRating = rating['userRating'] as int?;
      if (userRating != null) {
        totalRating += userRating.toDouble();
        ratingCount++;
      }
    }

    if (ratingCount == 0) {
      return 0.0;
    }

    return totalRating / ratingCount;
  }


  Widget _buildRatingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '用戶評價',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        
        const SizedBox(height: 16),
        
        if (_isLoadingRatings)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_organizerRatings.isEmpty && _participantRatings.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.star_outline,
                    size: 48,
                    color: AppColors.grey500,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '暫無評價',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.grey700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          // 作為發布者的評價
          if (_organizerRatings.isNotEmpty) ...[
            _buildRatingCategory('作為發布者的評價', _organizerRatings, true),
            const SizedBox(height: 24),
          ],
          
          // 作為參與者的評價
          if (_participantRatings.isNotEmpty) ...[
            _buildRatingCategory('作為參與者的評價', _participantRatings, false),
          ],
        ],
      ],
    );
  }

  Widget _buildRatingCategory(String title, List<Map<String, dynamic>> ratings, bool isOrganizerRating) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.grey900,
          ),
        ),
        
        const SizedBox(height: 12),
        
        SizedBox(
          height: 200, // 增加高度以容納更多文字
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 0),
            itemCount: ratings.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  right: index == ratings.length - 1 ? 0 : 12,
                ),
                child: _buildRatingCard(ratings[index], isOrganizerRating),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRatingCard(Map<String, dynamic> rating, bool isOrganizerRating) {
    final rater = isOrganizerRating 
        ? rating['rater'] as Map<String, dynamic>?
        : rating['organizer'] as Map<String, dynamic>?;
    final raterName = rater?['name'] as String? ?? '匿名用戶';
    final raterAvatar = rater?['avatar'] as String?;
    final comment = rating['comment'] as String?;
    final userRating = rating['userRating'] as int? ?? 5;
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
      width: 240, // 增加寬度以容納更多文字
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 評價者頭像和姓名
          Row(
            children: [
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
              
              Expanded(
                child: Text(
                  raterName,
                  style: const TextStyle(
                    fontSize: 14,
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
                  fontSize: 14,
                  color: AppColors.grey700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // 評論內容
          Flexible(
            child: Text(
              comment?.isNotEmpty == true 
                  ? comment! 
                  : '很棒很活潑很開心良好的體驗',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.grey700,
                height: 1.3,
                fontStyle: comment?.isNotEmpty == true 
                    ? FontStyle.normal 
                    : FontStyle.italic,
              ),
              // 移除 maxLines 和 overflow 限制，讓文字完整顯示
            ),
          ),
          
          // 日期
          if (formattedDate.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              formattedDate,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.grey500,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 用戶資料卡片彈窗建構器
class UserProfilePopupBuilder {
  /// 顯示用戶資料卡片彈窗
  static Future<void> show(
    BuildContext context, {
    required String userId,
    Map<String, dynamic>? initialUserData,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (context) => UserProfilePopup(
        userId: userId,
        initialUserData: initialUserData,
      ),
    );
  }
}
