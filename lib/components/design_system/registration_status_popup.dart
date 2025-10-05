import 'package:flutter/material.dart';
import 'custom_button.dart';
import 'app_colors.dart';
import 'user_profile_popup.dart';
import '../../services/activity_service.dart';

/// 查看報名狀況滿版彈窗組件
class RegistrationStatusPopup extends StatefulWidget {
  const RegistrationStatusPopup({
    super.key,
    required this.activityId,
    required this.activityName,
    this.onClose,
  });

  /// 活動ID
  final String activityId;
  
  /// 活動名稱
  final String activityName;
  
  /// 關閉回調
  final VoidCallback? onClose;

  @override
  State<RegistrationStatusPopup> createState() => _RegistrationStatusPopupState();
}

class _RegistrationStatusPopupState extends State<RegistrationStatusPopup> {
  final ActivityService _activityService = ActivityService();
  List<Map<String, dynamic>> _participants = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final participants = await _activityService.getActivityParticipants(
        activityId: widget.activityId,
      );

      if (mounted) {
        setState(() {
          _participants = participants;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: GestureDetector(
        onTap: () {
          // 點擊空白區域時取消焦點
          FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
              left: 24.0,
              right: 24.0,
              bottom: 40.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 關閉按鈕區域 - 距離上方40px
                const SizedBox(height: 40),
                CustomButton(
                  onPressed: widget.onClose ?? () {
                    // 關閉前確保取消焦點
                    FocusScope.of(context).unfocus();
                    Navigator.of(context).pop();
                  },
                  text: '關閉',
                  width: 80,
                  style: CustomButtonStyle.info,
                  borderRadius: 30.0, // 完全圓角
                ),
                
                const SizedBox(height: 24),
                
                // 標題
                Text(
                  '報名狀況',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // 活動名稱
                Text(
                  widget.activityName,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // 報名人數統計
                _buildParticipantCount(),
                
                const SizedBox(height: 24),
                
                // 內容區域
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParticipantCount() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.people_alt_outlined,
              size: 20,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              '載入中...',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.people_alt_outlined,
            size: 20,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            '總報名人數：${_participants.length} 人',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error900,
            ),
            const SizedBox(height: 16),
            Text(
              '載入失敗',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              onPressed: _loadParticipants,
              text: '重新載入',
              style: CustomButtonStyle.outline,
              borderColor: AppColors.primary900,
              textColor: AppColors.primary900,
            ),
          ],
        ),
      );
    }

    if (_participants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: AppColors.grey500,
            ),
            const SizedBox(height: 16),
            Text(
              '尚無報名者',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '目前還沒有人報名此活動',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadParticipants,
      child: ListView.separated(
        itemCount: _participants.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final participant = _participants[index];
          return _buildParticipantCard(participant);
        },
      ),
    );
  }

  Widget _buildParticipantCard(Map<String, dynamic> participant) {
    final user = participant['user'] as Map<String, dynamic>;
    final registration = participant['registration'] as Map<String, dynamic>;
    
    final name = user['name'] as String? ?? '未提供姓名';
    final avatarUrl = user['avatar'] as String?;
    final isVerified = user['isVerified'] as bool? ?? false;
    final registeredAt = registration['registeredAt'] as String?;
    
    // 格式化報名時間
    String formattedTime = '未知時間';
    if (registeredAt != null) {
      try {
        final dateTime = DateTime.parse(registeredAt);
        formattedTime = '${dateTime.year}/${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        formattedTime = '時間格式錯誤';
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 頭像 - 最左邊（可點擊）
          GestureDetector(
            onTap: () => _showUserProfile(participant),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.grey300,
                border: Border.all(
                  color: AppColors.grey100,
                  width: 1,
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
                      size: 28,
                    )
                  : null,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 右邊資訊區域 - 上下排序
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 上方：姓名和身份認證狀態
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 身份認證狀態
                    if (isVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified,
                              size: 12,
                              color: AppColors.success900,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '已認證',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.success900,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.grey100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '未認證',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.grey700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 6),
                
                // 下方：報名時間
                Text(
                  '報名時間：$formattedTime',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 顯示用戶資料卡片
  void _showUserProfile(Map<String, dynamic> participant) {
    final user = participant['user'] as Map<String, dynamic>;
    final userId = user['id'] ?? user['uid'];
    
    if (userId != null) {
      UserProfilePopupBuilder.show(
        context,
        userId: userId,
        initialUserData: user,
      );
    }
  }
}

/// 查看報名狀況彈窗建構器
class RegistrationStatusPopupBuilder {
  /// 顯示查看報名狀況彈窗
  static Future<void> show(
    BuildContext context, {
    required String activityId,
    required String activityName,
    VoidCallback? onClose,
  }) async {
    // 先取消當前頁面的焦點
    FocusScope.of(context).unfocus();
    
    // 稍微延遲確保焦點狀態清除
    await Future.delayed(const Duration(milliseconds: 100));
    
    // 在 Navigator push 前檢查 context 是否仍然有效
    if (!context.mounted) return;
    
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => RegistrationStatusPopup(
          activityId: activityId,
          activityName: activityName,
          onClose: onClose,
        ),
      ),
    );
    
    // 彈窗關閉後再次確保沒有焦點
    if (context.mounted) {
      FocusScope.of(context).unfocus();
    }
  }
}
