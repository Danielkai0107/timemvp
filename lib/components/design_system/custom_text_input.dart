import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Airbnb 風格的可重複使用文字輸入組件
/// 具有浮動標籤、聚焦動畫和現代化設計
class CustomTextInput extends StatefulWidget {
  const CustomTextInput({
    super.key,
    required this.label,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.isEnabled = true,
    this.errorText,
    this.suffixIcon,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.done,
    this.maxLines = 1,
    this.height = 60.0,
    this.borderRadius = 12.0,
  });

  /// 標籤文字（浮動標籤）
  final String label;
  
  /// 文字控制器
  final TextEditingController? controller;
  
  /// 文字變化回調
  final ValueChanged<String>? onChanged;
  
  /// 提交回調
  final ValueChanged<String>? onSubmitted;
  
  /// 是否啟用
  final bool isEnabled;
  
  /// 錯誤文字
  final String? errorText;
  
  /// 後置圖標
  final Widget? suffixIcon;
  
  /// 前置圖標
  final Widget? prefixIcon;
  
  /// 是否隱藏文字（密碼輸入）
  final bool obscureText;
  
  /// 鍵盤類型
  final TextInputType keyboardType;
  
  /// 文字輸入動作
  final TextInputAction textInputAction;
  
  /// 最大行數
  final int maxLines;
  
  /// 輸入框高度
  final double height;
  
  /// 邊框圓角
  final double borderRadius;

  @override
  CustomTextInputState createState() => CustomTextInputState();
}

class CustomTextInputState extends State<CustomTextInput> {
  late FocusNode _focusNode;
  late TextEditingController _controller;
  bool _isFocused = false;
  
  // 監聽器函數，用於在 dispose 時移除
  late VoidCallback _focusListener;
  late VoidCallback _textListener;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = widget.controller ?? TextEditingController();
    
    // 創建監聽器函數
    _focusListener = () {
      if (mounted) {
        setState(() {
          _isFocused = _focusNode.hasFocus;
        });
      }
    };
    
    _textListener = () {
      if (mounted) {
        setState(() {});
      }
    };
    
    // 添加監聽器
    _focusNode.addListener(_focusListener);
    _controller.addListener(_textListener);
  }

  @override
  void dispose() {
    // 移除監聽器
    _focusNode.removeListener(_focusListener);
    _controller.removeListener(_textListener);
    
    // 釋放資源
    _focusNode.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  /// 判斷標籤是否應該浮動到頂部
  bool get _shouldFloatLabel {
    return _controller.text.isNotEmpty || _isFocused;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            if (widget.isEnabled) {
              _focusNode.requestFocus();
            }
          },
          child: Container(
            height: widget.maxLines == 1 ? widget.height : null,
            constraints: widget.maxLines > 1 
              ? BoxConstraints(minHeight: widget.height)
              : null,
            decoration: BoxDecoration(
              border: Border.all(
                color: _getBorderColor(),
                width: _getBorderWidth(),
              ),
              borderRadius: BorderRadius.circular(widget.borderRadius),
              color: widget.isEnabled ? AppColors.white : AppColors.grey100,
            ),
            child: Stack(
            children: [
              // 文字輸入框
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: widget.isEnabled,
                autofocus: false,
                obscureText: widget.obscureText,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction,
                maxLines: widget.obscureText ? 1 : widget.maxLines,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(
                    left: widget.prefixIcon != null ? 48 : 16,
                    right: widget.suffixIcon != null ? 48 : 16,
                    top: _shouldFloatLabel ? 28 : (widget.maxLines == 1 ? 20 : 16),
                    bottom: widget.maxLines == 1 ? 8 : 16,
                  ),
                ),
              ),
              
              // 浮動標籤
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                left: widget.prefixIcon != null ? 48 : 16,
                top: _shouldFloatLabel ? 8 : (widget.maxLines == 1 ? 18 : 16),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  style: TextStyle(
                    color: _getLabelColor(),
                    fontSize: _shouldFloatLabel ? 12 : 16,
                    fontWeight: _shouldFloatLabel ? FontWeight.w500 : FontWeight.normal,
                  ),
                  child: Text(widget.label),
                ),
              ),
              
              // 前置圖標
              if (widget.prefixIcon != null)
                Positioned(
                  left: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(child: widget.prefixIcon!),
                ),
              
              // 後置圖標
              if (widget.suffixIcon != null)
                Positioned(
                  right: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(child: widget.suffixIcon!),
                ),
            ],
          ),
          ),
        ),
        
        // 錯誤文字區域（始終預留空間）
        const SizedBox(height: 4),
        Container(
          height:16, // 固定高度，相當於12px字體 + 4px行間距
          alignment: Alignment.centerLeft,
          child: widget.errorText != null 
            ? Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  widget.errorText!,
                  style: const TextStyle(
                    color: AppColors.error900,
                    fontSize: 12,
                  ),
                ),
              )
            : null, // 沒有錯誤時顯示空白，但保持高度
        ),
      ],
    );
  }

  /// 獲取邊框顏色
  Color _getBorderColor() {
    if (!widget.isEnabled) {
      return AppColors.grey300;
    }
    
    if (widget.errorText != null) {
      return AppColors.error900;
    }
    
    if (_isFocused) {
      return AppColors.black;
    }
    
    return AppColors.border;
  }

  /// 獲取邊框寬度
  double _getBorderWidth() {
    if (widget.errorText != null || _isFocused) {
      return 2.0;
    }
    return 1.0;
  }

  /// 獲取標籤顏色
  Color _getLabelColor() {
    if (!widget.isEnabled) {
      return AppColors.grey500;
    }
    
    if (widget.errorText != null) {
      return AppColors.error900;
    }
    
    if (_isFocused) {
      return AppColors.black;
    }
    
    return AppColors.textSecondary;
  }
}

/// 便捷的建構函式，用於建立常見類型的輸入框
class TextInputBuilder {
  /// 建立電子信箱輸入框
  static Widget email({
    String label = '電子信箱',
    TextEditingController? controller,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    String? errorText,
    bool isEnabled = true,
  }) {
    return CustomTextInput(
      label: label,
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      errorText: errorText,
      isEnabled: isEnabled,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
    );
  }

  /// 建立密碼輸入框
  static Widget password({
    String label = '密碼',
    TextEditingController? controller,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    String? errorText,
    bool isEnabled = true,
    Widget? suffixIcon,
  }) {
    return CustomTextInput(
      label: label,
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      errorText: errorText,
      isEnabled: isEnabled,
      obscureText: true,
      suffixIcon: suffixIcon,
      textInputAction: TextInputAction.done,
    );
  }

  /// 建立多行文字輸入框
  static Widget multiline({
    required String label,
    TextEditingController? controller,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    String? errorText,
    bool isEnabled = true,
    int maxLines = 4,
    double height = 100,
  }) {
    return CustomTextInput(
      label: label,
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      errorText: errorText,
      isEnabled: isEnabled,
      maxLines: maxLines,
      height: height,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
    );
  }

  /// 建立數字輸入框
  static Widget number({
    required String label,
    TextEditingController? controller,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    String? errorText,
    bool isEnabled = true,
  }) {
    return CustomTextInput(
      label: label,
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      errorText: errorText,
      isEnabled: isEnabled,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
    );
  }
}