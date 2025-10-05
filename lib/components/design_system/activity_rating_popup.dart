import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'custom_button.dart';

/// 活動評分彈窗組件
class ActivityRatingPopup extends StatefulWidget {
  final String activityId;
  final String activityName;
  final List<Map<String, dynamic>> organizers; // 主辦方列表
  final Function(Map<String, dynamic> ratings, String? comment) onSubmit;
  final VoidCallback? onSkip;

  const ActivityRatingPopup({
    super.key,
    required this.activityId,
    required this.activityName,
    required this.organizers,
    required this.onSubmit,
    this.onSkip,
  });

  @override
  State<ActivityRatingPopup> createState() => _ActivityRatingPopupState();
}

class _ActivityRatingPopupState extends State<ActivityRatingPopup>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  final PageController _pageController = PageController();
  final TextEditingController _commentController = TextEditingController();
  
  Map<String, int> _ratings = {}; // 存儲每個主辦方的評分
  int _currentPage = 0;
  bool _isSubmitting = false;

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
    
    // 初始化評分
    for (final organizer in widget.organizers) {
      _ratings[organizer['userId']] = 0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    await _animationController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _handleSubmit() {
    if (_isSubmitting) return;
    
    // 檢查是否有評分
    final hasRatings = _ratings.values.any((rating) => rating > 0);
    
    if (!hasRatings) {
      // 沒有評分，直接關閉
      _close();
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    // 準備評分數據
    final ratingsData = <String, dynamic>{};
    for (final entry in _ratings.entries) {
      if (entry.value > 0) {
        ratingsData[entry.key] = entry.value;
      }
    }
    
    widget.onSubmit(ratingsData, _commentController.text.trim().isEmpty ? null : _commentController.text.trim());
  }

  void _handleSkip() {
    widget.onSkip?.call();
    _close();
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
                            // 標題
                            _buildTitle(),
                            
                            const SizedBox(height: 24),
                            
                            // 主辦方評分區域
                            _buildOrganizersRating(),
                            
                            const SizedBox(height: 32),
                            
                            // 評論區域
                            _buildCommentSection(),
                            
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                    
                    // 底部按鈕
                    _buildBottomButtons(),
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

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '請為本次活動評分',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event,
                size: 16,
                color: AppColors.grey700,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.activityName,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.grey700,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${widget.organizers.length > 1 ? '為對方評分' : '為對方評分'}',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.grey700,
          ),
        ),
      ],
    );
  }

  Widget _buildOrganizersRating() {
    if (widget.organizers.length == 1) {
      return _buildSingleOrganizerRating(widget.organizers.first);
    } else {
      return _buildMultipleOrganizersRating();
    }
  }

  Widget _buildSingleOrganizerRating(Map<String, dynamic> organizer) {
    final userId = organizer['userId'] as String;
    final name = organizer['name'] as String? ?? '主辦者';
    final avatar = organizer['avatar'] as String?;
    final currentRating = _ratings[userId] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Column(
        children: [
          // 主辦者資訊
          Row(
            children: [
              // 頭像
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.grey300,
                  image: avatar != null && avatar.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(avatar),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: avatar == null || avatar.isEmpty
                    ? Icon(
                        Icons.person,
                        color: AppColors.grey700,
                        size: 28,
                      )
                    : null,
              ),
              
              const SizedBox(width: 16),
              
              // 姓名
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 評分星星
          _buildStarRating(userId, currentRating),
          
          const SizedBox(height: 12),
          
          // 評分說明
          Text(
            _getRatingDescription(currentRating),
            style: TextStyle(
              fontSize: 14,
              color: AppColors.grey700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultipleOrganizersRating() {
    return Column(
      children: [
        // 頁面指示器
        if (widget.organizers.length > 1)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.organizers.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == _currentPage
                        ? AppColors.primary900
                        : AppColors.grey300,
                  ),
                ),
              ),
            ),
          ),
        
        // 主辦方列表
        SizedBox(
          height: 280,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: widget.organizers.length,
            itemBuilder: (context, index) {
              final organizer = widget.organizers[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _buildSingleOrganizerRating(organizer),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStarRating(String userId, int currentRating) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final isSelected = starIndex <= currentRating;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _ratings[userId] = starIndex;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              isSelected ? Icons.star : Icons.star_border,
              size: 36,
              color: isSelected ? Colors.orange.shade400 : AppColors.grey500,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '有話想說...',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        
        const SizedBox(height: 12),
        
        Container(
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.grey300),
          ),
          child: TextField(
            controller: _commentController,
            maxLines: 4,
            maxLength: 300,
            decoration: InputDecoration(
              hintText: '很棒很活潑很開心良好的體驗',
              hintStyle: TextStyle(
                color: AppColors.grey700,
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              counterStyle: TextStyle(
                color: AppColors.grey700,
                fontSize: 12,
              ),
            ),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.grey300,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // 取消按鈕
            Expanded(
              child: CustomButton(
                onPressed: _isSubmitting ? null : _handleSkip,
                text: '取消',
                style: CustomButtonStyle.outline,
                borderColor: AppColors.grey300,
                textColor: AppColors.grey700,
                height: 52,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // 確認按鈕
            Expanded(
              child: CustomButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                text: _isSubmitting ? '提交中...' : '確認',
                style: CustomButtonStyle.primary,
                height: 52,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingDescription(int rating) {
    switch (rating) {
      case 1:
        return '很不滿意';
      case 2:
        return '不滿意';
      case 3:
        return '普通';
      case 4:
        return '滿意';
      case 5:
        return '非常滿意';
      default:
        return '給個五星好評吧！';
    }
  }
}

/// 活動評分彈窗建構器
class ActivityRatingPopupBuilder {
  /// 顯示活動評分彈窗
  static Future<void> show(
    BuildContext context, {
    required String activityId,
    required String activityName,
    required List<Map<String, dynamic>> organizers,
    required Function(Map<String, dynamic> ratings, String? comment) onSubmit,
    VoidCallback? onSkip,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) => ActivityRatingPopup(
        activityId: activityId,
        activityName: activityName,
        organizers: organizers,
        onSubmit: onSubmit,
        onSkip: onSkip,
      ),
    );
  }
}
