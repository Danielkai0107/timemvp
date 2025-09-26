import 'package:flutter/material.dart';

/// 自定義按鈕組件，與輸入框保持一致的設計風格
class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.width,
    this.height = 60.0,
    this.borderRadius = 12.0,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.borderWidth,
    this.style = CustomButtonStyle.primary,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
    this.fontSize = 16.0,
    this.fontWeight = FontWeight.w500,
  });

  /// 按鈕點擊回調
  final VoidCallback? onPressed;
  
  /// 按鈕文字
  final String text;
  
  /// 按鈕寬度
  final double? width;
  
  /// 按鈕高度
  final double height;
  
  /// 圓角半徑
  final double borderRadius;
  
  /// 背景色
  final Color? backgroundColor;
  
  /// 文字顏色
  final Color? textColor;
  
  /// 邊框顏色
  final Color? borderColor;
  
  /// 邊框寬度
  final double? borderWidth;
  
  /// 按鈕風格
  final CustomButtonStyle style;
  
  /// 是否顯示載入狀態
  final bool isLoading;
  
  /// 是否啟用
  final bool isEnabled;
  
  /// 圖標
  final Widget? icon;
  
  /// 字體大小
  final double fontSize;
  
  /// 字體粗細
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isEnabled && !isLoading ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _getBackgroundColor(theme),
          foregroundColor: _getTextColor(theme),
          elevation: _getElevation(),
          shadowColor: Colors.transparent,
          side: _getBorderSide(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: EdgeInsets.zero,
        ),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(_getLoadingColor()),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon!,
          if (text.isNotEmpty) ...[
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: fontWeight,
              ),
            ),
          ],
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
    );
  }

  Color _getBackgroundColor(ThemeData theme) {
    if (!isEnabled) {
      return Colors.grey.shade300;
    }

    if (backgroundColor != null) {
      return backgroundColor!;
    }

    switch (style) {
      case CustomButtonStyle.primary:
        return const Color(0xFFFFBE0A);
      case CustomButtonStyle.secondary:
        return const Color(0xFFAC6DFF);
      case CustomButtonStyle.success:
        return const Color(0xFF00B383);
      case CustomButtonStyle.danger:
        return const Color(0xFFEF2562);
      case CustomButtonStyle.info:
        return const Color(0xFFF2F2F2);
      case CustomButtonStyle.outline:
        return Colors.transparent;
      case CustomButtonStyle.text:
        return Colors.transparent;
    }
  }

  Color _getTextColor(ThemeData theme) {
    if (!isEnabled) {
      return Colors.grey.shade600;
    }

    if (textColor != null) {
      return textColor!;
    }

    switch (style) {
      case CustomButtonStyle.primary:
        return Colors.black;
      case CustomButtonStyle.secondary:
        return Colors.white;
      case CustomButtonStyle.success:
        return Colors.white;
      case CustomButtonStyle.danger:
        return Colors.white;
      case CustomButtonStyle.info:
        return Colors.black;
      case CustomButtonStyle.outline:
        return Colors.black;
      case CustomButtonStyle.text:
        return theme.primaryColor;
    }
  }

  BorderSide? _getBorderSide() {
    if (borderColor != null && borderWidth != null) {
      return BorderSide(
        color: borderColor!,
        width: borderWidth!,
      );
    }

    switch (style) {
      case CustomButtonStyle.primary:
      case CustomButtonStyle.secondary:
      case CustomButtonStyle.success:
      case CustomButtonStyle.danger:
      case CustomButtonStyle.info:
        return null;
      case CustomButtonStyle.outline:
        return BorderSide(
          color: Colors.grey.shade300,
          width: 1.0,
        );
      case CustomButtonStyle.text:
        return null;
    }
  }

  double _getElevation() {
    switch (style) {
      case CustomButtonStyle.primary:
      case CustomButtonStyle.secondary:
      case CustomButtonStyle.success:
      case CustomButtonStyle.danger:
      case CustomButtonStyle.info:
      case CustomButtonStyle.outline:
      case CustomButtonStyle.text:
        return 0;
    }
  }

  Color _getLoadingColor() {
    switch (style) {
      case CustomButtonStyle.primary:
      case CustomButtonStyle.info:
      case CustomButtonStyle.outline:
      case CustomButtonStyle.text:
        return Colors.black;
      case CustomButtonStyle.secondary:
      case CustomButtonStyle.success:
      case CustomButtonStyle.danger:
        return Colors.white;
    }
  }
}

/// 按鈕風格枚举
enum CustomButtonStyle {
  /// 主要按鈕（黃色背景）
  primary,
  /// 次要按鈕（紫色背景）
  secondary,
  /// 成功按鈕（綠色背景）
  success,
  /// 危險按鈕（紅色背景）
  danger,
  /// 資訊按鈕（淺灰色背景）
  info,
  /// 外框按鈕（透明背景，有邊框）
  outline,
  /// 文字按鈕（透明背景，無邊框）
  text,
}

/// 按鈕建構器，提供常用的按鈕樣式
class ButtonBuilder {
  /// 主要按鈕（登入、提交等）
  static Widget primary({
    required VoidCallback? onPressed,
    required String text,
    double? width,
    double height = 60.0,
    bool isLoading = false,
    bool isEnabled = true,
  }) {
    return CustomButton(
      onPressed: onPressed,
      text: text,
      width: width,
      height: height,
      style: CustomButtonStyle.primary,
      isLoading: isLoading,
      isEnabled: isEnabled,
      fontWeight: FontWeight.bold,
    );
  }

  /// 次要按鈕
  static Widget secondary({
    required VoidCallback? onPressed,
    required String text,
    double? width,
    double height = 60.0,
    bool isLoading = false,
    bool isEnabled = true,
  }) {
    return CustomButton(
      onPressed: onPressed,
      text: text,
      width: width,
      height: height,
      style: CustomButtonStyle.secondary,
      isLoading: isLoading,
      isEnabled: isEnabled,
    );
  }

  /// 成功按鈕
  static Widget success({
    required VoidCallback? onPressed,
    required String text,
    double? width,
    double height = 60.0,
    bool isLoading = false,
    bool isEnabled = true,
  }) {
    return CustomButton(
      onPressed: onPressed,
      text: text,
      width: width,
      height: height,
      style: CustomButtonStyle.success,
      isLoading: isLoading,
      isEnabled: isEnabled,
    );
  }

  /// 危險按鈕
  static Widget danger({
    required VoidCallback? onPressed,
    required String text,
    double? width,
    double height = 60.0,
    bool isLoading = false,
    bool isEnabled = true,
  }) {
    return CustomButton(
      onPressed: onPressed,
      text: text,
      width: width,
      height: height,
      style: CustomButtonStyle.danger,
      isLoading: isLoading,
      isEnabled: isEnabled,
    );
  }

  /// 資訊按鈕
  static Widget info({
    required VoidCallback? onPressed,
    required String text,
    double? width,
    double height = 60.0,
    bool isLoading = false,
    bool isEnabled = true,
  }) {
    return CustomButton(
      onPressed: onPressed,
      text: text,
      width: width,
      height: height,
      style: CustomButtonStyle.info,
      isLoading: isLoading,
      isEnabled: isEnabled,
    );
  }

  /// 外框按鈕（社交登入等）
  static Widget outline({
    required VoidCallback? onPressed,
    String text = '',
    Widget? icon,
    double? width,
    double height = 60.0,
    bool isLoading = false,
    bool isEnabled = true,
  }) {
    return CustomButton(
      onPressed: onPressed,
      text: text,
      icon: icon,
      width: width,
      height: height,
      style: CustomButtonStyle.outline,
      isLoading: isLoading,
      isEnabled: isEnabled,
    );
  }

  /// 文字按鈕（忘記密碼、創建帳戶等）
  static Widget text({
    required VoidCallback? onPressed,
    required String text,
    Color? textColor,
    double fontSize = 14.0,
    FontWeight fontWeight = FontWeight.normal,
    bool isEnabled = true,
  }) {
    return CustomButton(
      onPressed: onPressed,
      text: text,
      textColor: textColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: 40.0,
      style: CustomButtonStyle.text,
      isEnabled: isEnabled,
    );
  }

  /// Google 登入按鈕
  static Widget googleSignIn({
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool isEnabled = true,
  }) {
    return ButtonBuilder.outline(
      onPressed: onPressed,
      icon: Image.asset(
        'assets/images/google-icon.png',
        height: 24,
        width: 24,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.g_mobiledata,
            color: Colors.red,
            size: 24,
          );
        },
      ),
      isLoading: isLoading,
      isEnabled: isEnabled,
    );
  }

  /// Apple 登入按鈕
  static Widget appleSignIn({
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool isEnabled = true,
  }) {
    return ButtonBuilder.outline(
      onPressed: onPressed,
      icon: Image.asset(
        'assets/images/apple-icon.png',
        height: 24,
        width: 24,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.apple,
            color: Colors.black,
            size: 24,
          );
        },
      ),
      isLoading: isLoading,
      isEnabled: isEnabled,
    );
  }
}
