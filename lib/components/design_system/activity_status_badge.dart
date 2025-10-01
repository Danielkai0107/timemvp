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
  taskRecruiting('招募中', 'task');

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
    this.fontSize = 12.0,
    this.padding,
    this.borderRadius = 6.0,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getStatusColors(status);
    
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: colors.borderColor,
          width: 1,
        ),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: colors.textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 根據狀態獲取對應的顏色配置
  StatusColors _getStatusColors(ActivityStatus status) {
    switch (status) {
      // 成功狀態 - 綠色系
      case ActivityStatus.registrationSuccess:
      case ActivityStatus.applicationSuccess:
        return StatusColors(
          backgroundColor: AppColors.success100,
          borderColor: AppColors.success300,
          textColor: AppColors.success900,
        );
      
      // 進行中狀態 - 黃色系
      case ActivityStatus.eventPublished:
      case ActivityStatus.taskRecruiting:
        return StatusColors(
          backgroundColor: AppColors.primary100,
          borderColor: AppColors.primary300,
          textColor: AppColors.primary900,
        );
      
      // 等待中狀態 - 紫色系
      case ActivityStatus.applicationPending:
        return StatusColors(
          backgroundColor: AppColors.secondary100,
          borderColor: AppColors.secondary300,
          textColor: AppColors.secondary900,
        );
      
      // 結束狀態 - 灰色系
      case ActivityStatus.ended:
        return StatusColors(
          backgroundColor: AppColors.grey100,
          borderColor: AppColors.grey300,
          textColor: AppColors.grey700,
        );
      
      // 取消狀態 - 紅色系
      case ActivityStatus.cancelled:
        return StatusColors(
          backgroundColor: AppColors.error100,
          borderColor: AppColors.error300,
          textColor: AppColors.error900,
        );
    }
  }
}

/// 狀態顏色配置
class StatusColors {
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  const StatusColors({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });
}

/// 狀態標籤建構器，提供常用的標籤樣式
class StatusBadgeBuilder {
  /// 小尺寸標籤
  static Widget small(ActivityStatus status) {
    return ActivityStatusBadge(
      status: status,
      fontSize: 10.0,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      borderRadius: 4.0,
    );
  }

  /// 中等尺寸標籤
  static Widget medium(ActivityStatus status) {
    return ActivityStatusBadge(
      status: status,
      fontSize: 12.0,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      borderRadius: 6.0,
    );
  }

  /// 大尺寸標籤
  static Widget large(ActivityStatus status) {
    return ActivityStatusBadge(
      status: status,
      fontSize: 14.0,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      borderRadius: 8.0,
    );
  }
}

/// 狀態工具類
class ActivityStatusUtils {
  /// 從字符串轉換為狀態枚舉
  static ActivityStatus? fromString(String statusString, String activityType) {
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

