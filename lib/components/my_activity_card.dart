import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'design_system/app_colors.dart';
import 'design_system/activity_status_badge.dart';
import 'design_system/custom_snackbar.dart';

/// 我的活動卡片組件
/// 專門用於顯示用戶報名或發布的活動，包含狀態標籤
class MyActivityCard extends StatelessWidget {
  final String title;
  final String date;
  final String time;
  final String price;
  final String location;
  final String? imageUrl;
  final bool isPro;
  final ActivityStatus status;
  final String activityType; // 'event' 或 'task'
  final VoidCallback? onTap;
  final VoidCallback? onLongPress; // 長按回調
  final bool enableLongPressToHide; // 是否啟用長按隱藏
  
  const MyActivityCard({
    super.key,
    required this.title,
    required this.date,
    required this.time,
    required this.price,
    required this.location,
    required this.status,
    required this.activityType,
    this.imageUrl,
    this.isPro = false,
    this.onTap,
    this.onLongPress,
    this.enableLongPressToHide = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 活動資訊
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 活動標題和活動類型
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: activityType == 'event' 
                                ? AppColors.primary300 
                                : AppColors.secondary300,
                          ),
                        ),
                        child: Text(
                          activityType == 'event' ? '活動' : '任務',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: activityType == 'event' 
                                ? AppColors.primary900 
                                : AppColors.secondary900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // 日期和時間
                  Text(
                    '$date $time',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // 價格、地點和狀態標籤
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          location.isNotEmpty ? '$price｜$location' : price,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isPro) ...[
                        const SizedBox(width: 8),
                        SvgPicture.asset(
                          'assets/images/pro-tag.svg',
                          width: 32,
                          height: 16,
                        ),
                      ],
                      const SizedBox(width: 8),
                      StatusBadgeBuilder.small(status),
                    ],
                  ),
                ],
              ),
            ),
          ],
      ),
    );

    // 返回可點擊和長按的卡片
    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _handleLongPress(context),
      child: cardContent,
    );
  }

  /// 處理長按事件
  void _handleLongPress(BuildContext context) {
    // 觸覺反饋
    HapticFeedback.mediumImpact();
    
    if (enableLongPressToHide) {
      // 可以隱藏的活動，顯示隱藏確認對話框
      _showHideConfirmDialog(context);
    } else {
      // 不能隱藏的活動，顯示提示訊息
      CustomSnackBarBuilder.info(
        context,
        '因活動還在進行中無法刪除',
        duration: const Duration(seconds: 2),
      );
    }
  }

  /// 顯示隱藏確認對話框
  void _showHideConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認刪除'),
        content: Text('確定要刪除「$title」嗎？\n刪除後將不會再顯示此活動。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onLongPress?.call();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error900,
            ),
            child: const Text('確認刪除'),
          ),
        ],
      ),
    );
  }
}

/// 我的活動卡片建構器
class MyActivityCardBuilder {
  /// 獲取實際的報名狀態（考慮活動是否已結束）
  static ActivityStatus? _getActualRegistrationStatus(
    Map<String, dynamic> registration, 
    Map<String, dynamic> activity
  ) {
    final registrationStatus = registration['status'] as String? ?? 'registered';
    final activityStatus = activity['status'] as String?;
    final activityType = activity['type'] as String? ?? 'event';
    final endDateTime = activity['endDateTime'] as String?;
    
    // 首先檢查是否為取消狀態（最高優先級）
    if (registrationStatus == 'cancelled' || activityStatus == 'cancelled') {
      return ActivityStatus.cancelled;
    }
    
    // 如果報名狀態已經是 ended，直接返回
    if (registrationStatus == 'ended') {
      return ActivityStatus.ended;
    }
    
    // 檢查活動是否已結束
    bool isActivityEnded = false;
    
    // 1. 檢查活動狀態是否為 ended
    if (activityStatus == 'ended') {
      isActivityEnded = true;
    }
    
    // 2. 檢查是否超過活動結束時間
    if (!isActivityEnded && endDateTime != null) {
      try {
        final endTime = DateTime.parse(endDateTime);
        final now = DateTime.now();
        isActivityEnded = now.isAfter(endTime);
      } catch (e) {
        debugPrint('解析活動結束時間失敗: $e');
      }
    }
    
    // 如果活動已結束，但報名狀態還是 registered，則顯示為已結束
    if (isActivityEnded && registrationStatus == 'registered') {
      return ActivityStatus.ended;
    }
    
    // 否則使用原始的狀態判斷邏輯
    return ActivityStatusUtils.fromString(registrationStatus, activityType);
  }
  /// 從報名記錄創建活動卡片
  static Widget fromRegistration({
    required Map<String, dynamic> registrationData,
    VoidCallback? onTap,
    VoidCallback? onHide,
  }) {
    debugPrint('=== MyActivityCard: 從報名記錄創建卡片 ===');
    debugPrint('輸入資料: $registrationData');
    
    final registration = registrationData['registration'] as Map<String, dynamic>;
    final activity = registrationData['activity'] as Map<String, dynamic>;
    
    debugPrint('報名資料: $registration');
    debugPrint('活動資料: $activity');
    
    // 解析狀態 - 使用實際狀態判斷邏輯
    final activityType = activity['type'] as String? ?? 'event';
    final status = _getActualRegistrationStatus(registration, activity) 
        ?? ActivityStatus.registrationSuccess;
    
    debugPrint('狀態解析: ${registration['status']} -> ${status.displayName}');
    
    // 解析日期時間 - 優先處理 startDateTime
    String? startDate;
    String? startTime;
    
    // 首先嘗試從 startDateTime 解析（這是主要的儲存格式）
    if (activity['startDateTime'] != null) {
      try {
        final dateTime = DateTime.parse(activity['startDateTime']);
        startDate = dateTime.toIso8601String().split('T')[0];
        startTime = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
        debugPrint('從 startDateTime 解析成功: 日期=$startDate, 時間=$startTime');
      } catch (e) {
        debugPrint('解析 startDateTime 失敗: $e');
      }
    }
    
    // 如果 startDateTime 解析失敗，嘗試其他欄位
    if (startDate == null) {
      startDate = activity['startDate'] as String? ?? 
                 activity['date'] as String?;
    }
    
    if (startTime == null) {
      startTime = activity['startTime'] as String? ?? 
                 activity['time'] as String?;
    }
    
    // 解析地點 - 檢查多種可能的欄位名稱
    String location = activity['location'] as String? ?? 
                     activity['address'] as String? ?? 
                     activity['locationName'] as String? ?? 
                     '';
    
    // 如果是線上活動
    if (activity['isOnline'] == true) {
      location = '線上活動';
    }
    
    debugPrint('解析後的資料:');
    debugPrint('- 標題: ${activity['name']}');
    debugPrint('- 日期: $startDate');
    debugPrint('- 時間: $startTime');
    debugPrint('- 價格: ${activity['price']}');
    debugPrint('- 地點: $location');
    debugPrint('- 圖片: ${activity['cover']}');
    debugPrint('- 類型: $activityType');
    
    // 檢查是否應該啟用長按隱藏（只有已取消和已結束的活動）
    final enableLongPress = status == ActivityStatus.cancelled || status == ActivityStatus.ended;
    
    return MyActivityCard(
      title: activity['name'] as String? ?? '未知活動',
      date: _formatDate(startDate),
      time: _formatTime(startTime),
      price: _formatPrice(activity['price']),
      location: location,
      imageUrl: activity['cover'] as String?,
      isPro: activity['isPro'] as bool? ?? false,
      status: status,
      activityType: activityType,
      onTap: onTap,
      enableLongPressToHide: enableLongPress,
      onLongPress: enableLongPress ? onHide : null,
    );
  }

  /// 從發布活動創建活動卡片
  static Widget fromPublishedActivity({
    required Map<String, dynamic> activityData,
    VoidCallback? onTap,
    VoidCallback? onHide,
  }) {
    // 解析狀態
    final statusString = activityData['displayStatus'] as String? ?? 'published';
    final activityType = activityData['type'] as String? ?? 'event';
    final draftReason = activityData['draftReason'] as String?;
    final status = ActivityStatusUtils.fromString(statusString, activityType, draftReason: draftReason) 
        ?? (activityType == 'event' ? ActivityStatus.eventPublished : ActivityStatus.taskRecruiting);
    
    // 解析日期時間 - 優先處理 startDateTime
    String? startDate;
    String? startTime;
    
    // 首先嘗試從 startDateTime 解析（這是主要的儲存格式）
    if (activityData['startDateTime'] != null) {
      try {
        final dateTime = DateTime.parse(activityData['startDateTime']);
        startDate = dateTime.toIso8601String().split('T')[0];
        startTime = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
        debugPrint('發布活動從 startDateTime 解析成功: 日期=$startDate, 時間=$startTime');
      } catch (e) {
        debugPrint('發布活動解析 startDateTime 失敗: $e');
      }
    }
    
    // 如果 startDateTime 解析失敗，嘗試其他欄位
    if (startDate == null) {
      startDate = activityData['startDate'] as String? ?? 
                 activityData['date'] as String?;
    }
    
    if (startTime == null) {
      startTime = activityData['startTime'] as String? ?? 
                 activityData['time'] as String?;
    }
    
    // 檢查是否應該啟用長按隱藏（只有已取消和已結束的活動）
    final enableLongPress = status == ActivityStatus.cancelled || status == ActivityStatus.ended;
    
    return MyActivityCard(
      title: activityData['name'] as String? ?? '未知活動',
      date: _formatDate(startDate),
      time: _formatTime(startTime),
      price: _formatPrice(activityData['price']),
      location: activityData['location'] as String? ?? '',
      imageUrl: activityData['cover'] as String?,
      isPro: activityData['isPro'] as bool? ?? false,
      status: status,
      activityType: activityType,
      onTap: onTap,
      enableLongPressToHide: enableLongPress,
      onLongPress: enableLongPress ? onHide : null,
    );
  }

  /// 格式化日期
  static String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '待定';
    
    try {
      final date = DateTime.parse(dateString);
      final weekdays = ['日', '一', '二', '三', '四', '五', '六'];
      final weekday = weekdays[date.weekday % 7];
      final formattedDate = '${date.month}/${date.day} ($weekday)';
      debugPrint('日期格式化: $dateString -> $formattedDate');
      return formattedDate;
    } catch (e) {
      debugPrint('日期格式化失敗: $dateString, 錯誤: $e');
      return dateString;
    }
  }

  /// 格式化時間
  static String _formatTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return '';
    
    // 如果已經是格式化的時間，直接返回
    if (timeString.contains(':')) {
      return timeString;
    }
    
    return timeString;
  }

  /// 格式化價格
  static String _formatPrice(dynamic price) {
    if (price == null) return '免費';
    
    if (price is String) {
      if (price.isEmpty || price == '0' || price.toLowerCase() == 'free') {
        return '免費';
      }
      return price;
    }
    
    if (price is num) {
      if (price == 0) return '免費';
      return 'NT\$ ${price.toInt()}';
    }
    
    return '免費';
  }
}
