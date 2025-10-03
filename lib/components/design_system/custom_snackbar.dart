import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 自定義SnackBar組件
/// 白底黑字，圓角設計，貼齊step_indicator顯示
class CustomSnackBar {
  // 全局追蹤所有活動的 overlay entries
  static final List<OverlayEntry> _activeEntries = [];
  
  /// 清除所有活動的 CustomSnackBar
  static void clearAll() {
    for (final entry in _activeEntries) {
      if (entry.mounted) {
        entry.remove();
      }
    }
    _activeEntries.clear();
  }
  /// 顯示錯誤類型的SnackBar
  static void showError(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showCustomSnackBar(
      context,
      message: message,
      type: _SnackBarType.error,
      duration: duration,
    );
  }

  /// 顯示成功類型的SnackBar
  static void showSuccess(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showCustomSnackBar(
      context,
      message: message,
      type: _SnackBarType.success,
      duration: duration,
    );
  }

  /// 顯示一般信息類型的SnackBar
  static void showInfo(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showCustomSnackBar(
      context,
      message: message,
      type: _SnackBarType.info,
      duration: duration,
    );
  }

  /// 內部方法：顯示自定義SnackBar
  static void _showCustomSnackBar(
    BuildContext context, {
    required String message,
    required _SnackBarType type,
    Duration duration = const Duration(seconds: 3),
  }) {
    // 移除現有的SnackBar
    ScaffoldMessenger.of(context).clearSnackBars();
    // 清除所有現有的 CustomSnackBar
    clearAll();

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _CustomSnackBarWidget(
        message: message,
        type: type,
        onDismiss: () {
          _activeEntries.remove(overlayEntry);
          overlayEntry.remove();
        },
      ),
    );

    // 添加到活動列表
    _activeEntries.add(overlayEntry);
    overlay.insert(overlayEntry);

    // 自動移除
    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        _activeEntries.remove(overlayEntry);
        overlayEntry.remove();
      }
    });
  }
}

/// SnackBar類型枚舉
enum _SnackBarType {
  error,
  success,
  info,
}

/// 自定義SnackBar Widget
class _CustomSnackBarWidget extends StatefulWidget {
  const _CustomSnackBarWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  final String message;
  final _SnackBarType type;
  final VoidCallback onDismiss;

  @override
  _CustomSnackBarWidgetState createState() => _CustomSnackBarWidgetState();
}

class _CustomSnackBarWidgetState extends State<_CustomSnackBarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 獲取圖標
  IconData _getIcon() {
    switch (widget.type) {
      case _SnackBarType.error:
        return Icons.error_outline;
      case _SnackBarType.success:
        return Icons.check_circle_outline;
      case _SnackBarType.info:
        return Icons.info_outline;
    }
  }

  /// 獲取圖標顏色
  Color _getIconColor() {
    switch (widget.type) {
      case _SnackBarType.error:
        return AppColors.error900;
      case _SnackBarType.success:
        return AppColors.success900;
      case _SnackBarType.info:
        return AppColors.primary900;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: MediaQuery.of(context).padding.bottom + 140, // 貼齊step_indicator上方
      child: SlideTransition(
        position: _slideAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // 圖標
                Icon(
                  _getIcon(),
                  size: 20,
                  color: _getIconColor(),
                ),
                
                const SizedBox(width: 12),
                
                // 訊息文字
                Expanded(
                  child: Text(
                    widget.message,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
                
                // 關閉按鈕
                GestureDetector(
                  onTap: () {
                    _animationController.reverse().then((_) {
                      widget.onDismiss();
                    });
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.grey,
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
}

/// 自定義SnackBar建構器
class CustomSnackBarBuilder {
  /// 清除所有活動的 CustomSnackBar
  static void clearAll() {
    CustomSnackBar.clearAll();
  }
  /// 顯示錯誤訊息
  static void error(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    CustomSnackBar.showError(context, message: message, duration: duration);
  }

  /// 顯示成功訊息
  static void success(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    CustomSnackBar.showSuccess(context, message: message, duration: duration);
  }

  /// 顯示一般信息
  static void info(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    CustomSnackBar.showInfo(context, message: message, duration: duration);
  }

  /// 表單驗證錯誤
  static void validationError(
    BuildContext context,
    String message,
  ) {
    CustomSnackBar.showError(
      context,
      message: message,
      duration: const Duration(seconds: 2),
    );
  }

  /// 操作成功提示
  static void operationSuccess(
    BuildContext context,
    String message,
  ) {
    CustomSnackBar.showSuccess(
      context,
      message: message,
      duration: const Duration(seconds: 2),
    );
  }
}
