import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 活動狀態枚舉
enum ActivityStatus {
  // 我報名的活動狀態
  registrationSuccess('報名成功', 'event'),
  applicationPending('應徵確認中', 'task'),
  applicationSuccess('應徵成功', 'task'),
  
  // 通用狀態
  ended('已結束', 'common'),
  cancelled('已取消', 'common'),
  
  // 我發布的活動狀態
  eventPublished('活動發布中', 'event'),
  taskRecruiting('招募中', 'task'),
  
  // 草稿狀態（合併，不分活動類型）
  draft('草稿', 'common'),
  
  // KYC 待審核狀態
  kycPending('身份審核中', 'common');

  const ActivityStatus(this.displayName, this.category);
  
  final String displayName;
  final String category; // 'event', 'task', 'common'
}

/// 活動狀態標籤組件
class ActivityStatusBadge extends StatelessWidget {
  final ActivityStatus status;
  final double? fontSize;
  final EdgeInsets? padding;
  final double borderRadius;

  const ActivityStatusBadge({
    super.key,
    required this.status,
    this.fontSize = 13.0,
    this.padding,
    this.borderRadius = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getStatusColors(status);
    
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: colors.borderColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 圓點
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: colors.dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          // 文字
          Text(
            status.displayName,
            style: TextStyle(
              color: colors.textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 根據狀態獲取對應的顏色配置
  StatusColors _getStatusColors(ActivityStatus status) {
    switch (status) {
      // 成功狀態 - 綠色圓點
      case ActivityStatus.registrationSuccess:
      case ActivityStatus.applicationSuccess:
        return const StatusColors(
          backgroundColor: Colors.white,
          borderColor: AppColors.grey300,
          textColor: AppColors.grey700,
          dotColor: AppColors.success900,
        );
      
      // 進行中狀態 - 主色圓點
      case ActivityStatus.eventPublished:
      case ActivityStatus.taskRecruiting:
        return const StatusColors(
          backgroundColor: Colors.white,
          borderColor: AppColors.grey300,
          textColor: AppColors.grey700,
          dotColor: AppColors.primary900,
        );
      
      // 等待中狀態 - 次要色圓點
      case ActivityStatus.applicationPending:
        return const StatusColors(
          backgroundColor: Colors.white,
          borderColor: AppColors.grey300,
          textColor: AppColors.grey700,
          dotColor: AppColors.secondary900,
        );
      
      // 結束狀態 - 灰色圓點
      case ActivityStatus.ended:
        return const StatusColors(
          backgroundColor: Colors.white,
          borderColor: AppColors.grey300,
          textColor: AppColors.grey700,
          dotColor: AppColors.grey500,
        );
      
      // 取消狀態 - 灰色圓點
      case ActivityStatus.cancelled:
        return const StatusColors(
          backgroundColor: Colors.white,
          borderColor: AppColors.grey300,
          textColor: AppColors.grey700,
          dotColor: AppColors.grey500,
        );
      
      // 草稿狀態 - 橙色圓點
      case ActivityStatus.draft:
        return const StatusColors(
          backgroundColor: Colors.white,
          borderColor: AppColors.grey300,
          textColor: AppColors.grey700,
          dotColor: Colors.orange,
        );
      
      // KYC 待審核狀態 - 次要色圓點
      case ActivityStatus.kycPending:
        return const StatusColors(
          backgroundColor: Colors.white,
          borderColor: AppColors.grey300,
          textColor: AppColors.grey700,
          dotColor: AppColors.secondary900,
        );
    }
  }
}

/// 狀態顏色配置
class StatusColors {
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final Color dotColor;

  const StatusColors({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.dotColor,
  });
}

/// 小尺寸狀態標籤組件（無外框）
class _SmallStatusBadge extends StatelessWidget {
  final ActivityStatus status;

  const _SmallStatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getStatusColors(status);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 圓點
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: colors.dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        // 文字
        Text(
          status.displayName,
          style: TextStyle(
            color: colors.textColor,
            fontSize: 13.0,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 根據狀態獲取對應的顏色配置
  StatusColors _getStatusColors(ActivityStatus status) {
    switch (status) {
      // 成功狀態 - 綠色圓點
      case ActivityStatus.registrationSuccess:
      case ActivityStatus.applicationSuccess:
        return const StatusColors(
          backgroundColor: Colors.white,
          borderColor: AppColors.grey300,
          textColor: AppColors.grey700,
          dotColor: AppColors.success900,
        );
      
      // 進行中狀態 - 主色圓點
      case ActivityStatus.eventPublished:
      case ActivityStatus.taskRecruiting:
        return const StatusColors(
          backgroundColor: Colors.white,
          borderColor: AppColors.grey300,
          textColor: AppColors.grey700,
          dotColor: AppColors.primary900,
        );
      
      // 等待中狀態 - 次要色圓點
      case ActivityStatus.applicationPending:
        return const StatusColors(
          backgroundColor: Colors.white,
          borderColor: AppColors.grey300,
          textColor: AppColors.grey700,
          dotColor: AppColors.secondary900,
        );
      
      // 結束狀態 - 灰色圓點
      case ActivityStatus.ended:
        return const StatusColors(
          backgroundColor: Colors.white,
          borderColor: AppColors.grey300,
          textColor: AppColors.grey700,
          dotColor: AppColors.grey500,
        );
      
      // 取消狀態 - 灰色圓點
      case ActivityStatus.cancelled:
        return const StatusColors(
          backgroundColor: Colors.white,
          borderColor: AppColors.grey300,
          textColor: AppColors.grey700,
          dotColor: AppColors.grey500,
        );
      
      // 草稿狀態 - 橙色圓點
      case ActivityStatus.draft:
        return const StatusColors(
          backgroundColor: Colors.white,
          borderColor: AppColors.grey300,
          textColor: AppColors.grey700,
          dotColor: Colors.orange,
        );
      
      // KYC 待審核狀態 - 次要色圓點
      case ActivityStatus.kycPending:
        return const StatusColors(
          backgroundColor: Colors.white,
          borderColor: AppColors.grey300,
          textColor: AppColors.grey700,
          dotColor: AppColors.secondary900,
        );
    }
  }
}

/// 狀態標籤建構器，提供常用的標籤樣式
class StatusBadgeBuilder {
  /// 小尺寸標籤
  static Widget small(ActivityStatus status) {
    return _SmallStatusBadge(status: status);
  }

  /// 中等尺寸標籤
  static Widget medium(ActivityStatus status) {
    return ActivityStatusBadge(
      status: status,
      fontSize: 13.0,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      borderRadius: 24.0,
    );
  }

  /// 大尺寸標籤
  static Widget large(ActivityStatus status) {
    return ActivityStatusBadge(
      status: status,
      fontSize: 14.0,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: 24.0,
    );
  }
}

/// 狀態工具類
class ActivityStatusUtils {
  /// 從字符串轉換為狀態枚舉
  static ActivityStatus? fromString(String statusString, String activityType, {String? draftReason}) {
    switch (statusString.toLowerCase()) {
      case 'registered':
        return ActivityStatus.registrationSuccess;
      case 'application_pending':
        return ActivityStatus.applicationPending;
      case 'application_success':
        return ActivityStatus.applicationSuccess;
      case 'published':
        return activityType == 'event' 
            ? ActivityStatus.eventPublished 
            : ActivityStatus.taskRecruiting;
      case 'draft':
        // 根據草稿原因決定狀態
        if (draftReason == 'kyc_pending' || draftReason == 'kyc_required') {
          return ActivityStatus.kycPending;
        } else {
          return ActivityStatus.draft;
        }
      case 'ended':
        return ActivityStatus.ended;
      case 'cancelled':
        return ActivityStatus.cancelled;
      default:
        return null;
    }
  }

  /// 獲取用戶報名活動的可能狀態
  static List<ActivityStatus> getRegisteredActivityStatuses() {
    return [
      ActivityStatus.registrationSuccess,
      ActivityStatus.applicationPending,
      ActivityStatus.applicationSuccess,
      ActivityStatus.ended,
      ActivityStatus.cancelled,
    ];
  }

  /// 獲取用戶發布活動的可能狀態
  static List<ActivityStatus> getPublishedActivityStatuses() {
    return [
      ActivityStatus.eventPublished,
      ActivityStatus.taskRecruiting,
      ActivityStatus.draft,
      ActivityStatus.kycPending,
      ActivityStatus.ended,
      ActivityStatus.cancelled,
    ];
  }

  /// 檢查狀態是否為活躍狀態
  static bool isActiveStatus(ActivityStatus status) {
    return status != ActivityStatus.ended && status != ActivityStatus.cancelled;
  }

  /// 檢查狀態是否為成功狀態
  static bool isSuccessStatus(ActivityStatus status) {
    return status == ActivityStatus.registrationSuccess || 
           status == ActivityStatus.applicationSuccess;
  }
}

