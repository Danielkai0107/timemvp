import 'package:flutter/material.dart';

/// TimeApp 設計系統色彩定義
/// 
/// 這個類別包含了應用程式中使用的所有色彩常數。
/// 色彩分為以下類別：
/// - Primary: 主要品牌色彩 (黃色系)
/// - Secondary: 次要色彩 (紫色系) 
/// - Success: 成功狀態色彩 (綠色系)
/// - Error: 錯誤狀態色彩 (紅色系)
/// - Grey: 中性灰色系
/// - Basic: 基礎黑白色
class AppColors {
  AppColors._(); // 私有構造函數，防止實例化

  // ========== Primary Colors (主要色彩 - 黃色系) ==========
  static const Color primary900 = Color(0xFFFFBE0A);
  static const Color primary700 = Color(0xFFFECC42);
  static const Color primary500 = Color(0xFFFEDA7A);
  static const Color primary300 = Color(0xFFFDE8B1);
  static const Color primary100 = Color(0xFFFCF6E9);

  // ========== Secondary Colors (次要色彩 - 紫色系) ==========
  static const Color secondary900 = Color(0xFFAC6DFF);
  static const Color secondary700 = Color(0xFFC293FF);
  static const Color secondary500 = Color(0xFFC293FF);
  static const Color secondary300 = Color(0xFFD7B8FF);
  static const Color secondary100 = Color(0xFFECDEFF);

  // ========== Success Colors (成功狀態色彩 - 綠色系) ==========
  static const Color success900 = Color(0xFF00B383);
  static const Color success700 = Color(0xFF36C6A0);
  static const Color success500 = Color(0xFF6CD9BC);
  static const Color success300 = Color(0xFFA2ECD8);
  static const Color success100 = Color(0xFFDBFFF4);

  // ========== Error Colors (錯誤狀態色彩 - 紅色系) ==========
  static const Color error900 = Color(0xFFEF2562);
  static const Color error700 = Color(0xFFF35987);
  static const Color error500 = Color(0xFFF78EAE);
  static const Color error300 = Color(0xFFFBC2D3);
  static const Color error100 = Color(0xFFFFF6F9);

  // ========== Grey Colors (中性色彩 - 灰色系) ==========
  static const Color grey900 = Color(0xFF222222);
  static const Color grey700 = Color(0xFF6A6A6A);
  static const Color grey500 = Color(0xFF979797);
  static const Color grey300 = Color(0xFFDDDDDD);
  static const Color grey100 = Color(0xFFF2F2F2);

  // ========== Basic Colors (基礎色彩) ==========
  static const Color black = Color(0xFF222222);
  static const Color white = Color(0xFFFFFFFF);

  // ========== 語意化色彩別名 ==========
  /// 主要品牌色 - 用於重要按鈕、強調元素
  static const Color brandPrimary = primary900;
  
  /// 次要品牌色 - 用於輔助元素、裝飾
  static const Color brandSecondary = secondary900;

  /// 文字主色 - 用於標題、重要文字
  static const Color textPrimary = grey900;
  
  /// 文字次要色 - 用於描述文字、輔助資訊
  static const Color textSecondary = grey700;
  
  /// 文字提示色 - 用於佔位符、不重要資訊
  static const Color textHint = grey500;

  /// 背景主色
  static const Color backgroundPrimary = white;
  
  /// 背景次要色
  static const Color backgroundSecondary = grey100;

  /// 分隔線顏色
  static const Color divider = grey300;

  /// 邊框顏色
  static const Color border = grey300;

  /// 成功狀態色
  static const Color statusSuccess = success900;
  
  /// 錯誤狀態色
  static const Color statusError = error900;

  /// 警告狀態色 (使用主色調)
  static const Color statusWarning = primary900;

  // ========== 色彩工具方法 ==========
  
  /// 取得主要色彩的所有色調
  static List<Color> get primaryShades => [
    primary100,
    primary300, 
    primary500,
    primary700,
    primary900,
  ];

  /// 取得次要色彩的所有色調
  static List<Color> get secondaryShades => [
    secondary100,
    secondary300,
    secondary500, 
    secondary700,
    secondary900,
  ];

  /// 取得成功色彩的所有色調
  static List<Color> get successShades => [
    success100,
    success300,
    success500,
    success700,
    success900,
  ];

  /// 取得錯誤色彩的所有色調
  static List<Color> get errorShades => [
    error100,
    error300,
    error500,
    error700,
    error900,
  ];

  /// 取得灰色的所有色調
  static List<Color> get greyShades => [
    grey100,
    grey300,
    grey500,
    grey700,
    grey900,
  ];
}
