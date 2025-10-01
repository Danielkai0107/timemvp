import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 自定義時間選擇器組件
/// 提供小時和分鐘的滾動選擇
class CustomTimePicker extends StatefulWidget {
  const CustomTimePicker({
    super.key,
    required this.label,
    this.value,
    this.onChanged,
    this.isEnabled = true,
    this.errorText,
    this.height = 60.0,
    this.borderRadius = 12.0,
    this.dialogTitle,
  });

  /// 標籤文字
  final String label;
  
  /// 當前選中的時間
  final TimeOfDay? value;
  
  /// 時間變化回調
  final ValueChanged<TimeOfDay?>? onChanged;
  
  /// 是否啟用
  final bool isEnabled;
  
  /// 錯誤文字
  final String? errorText;
  
  /// 選擇器高度
  final double height;
  
  /// 邊框圓角
  final double borderRadius;

  /// 對話框標題
  final String? dialogTitle;

  @override
  CustomTimePickerState createState() => CustomTimePickerState();
}

class CustomTimePickerState extends State<CustomTimePicker> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  /// 判斷標籤是否應該浮動到頂部
  bool get _shouldFloatLabel {
    return widget.value != null || _isFocused;
  }

  /// 獲取顯示文字
  String get _displayText {
    if (widget.value == null) return '';
    return '${widget.value!.hour.toString().padLeft(2, '0')}:${widget.value!.minute.toString().padLeft(2, '0')}';
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

  /// 顯示時間選擇對話框
  void _showTimePickerDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return TimePickerDialog(
          title: widget.dialogTitle ?? widget.label,
          selectedTime: widget.value,
          onTimeSelected: (time) {
            Navigator.of(context).pop();
            if (widget.onChanged != null) {
              widget.onChanged!(time);
            }
          },
        );
      },
    );
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
              _showTimePickerDialog();
            }
          },
          child: Container(
            height: widget.height,
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
                // 顯示選中的時間
                Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: _shouldFloatLabel ? 26 : 20,
                    bottom: 8,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _displayText,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                
                // 下拉箭頭
                const Positioned(
                  right: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.grey500,
                      size: 24,
                    ),
                  ),
                ),
                
                // 浮動標籤
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  left: 16,
                  top: _shouldFloatLabel ? 8 : 18,
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
              ],
            ),
          ),
        ),
        
        // 錯誤文字區域
        const SizedBox(height: 4),
        Container(
          height: 16,
          alignment: Alignment.centerLeft,
          child: widget.errorText != null 
            ? Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  widget.errorText!,
                  style: const TextStyle(
                    color: AppColors.error900,
                    fontSize: 12,
                  ),
                ),
              )
            : null,
        ),
      ],
    );
  }
}

/// 時間選擇對話框
class TimePickerDialog extends StatefulWidget {
  const TimePickerDialog({
    super.key,
    required this.title,
    this.selectedTime,
    required this.onTimeSelected,
  });

  final String title;
  final TimeOfDay? selectedTime;
  final ValueChanged<TimeOfDay> onTimeSelected;

  @override
  TimePickerDialogState createState() => TimePickerDialogState();
}

class TimePickerDialogState extends State<TimePickerDialog> {
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  
  late int _selectedHour;
  late int _selectedMinute;

  @override
  void initState() {
    super.initState();
    
    final now = TimeOfDay.now();
    _selectedHour = widget.selectedTime?.hour ?? now.hour;
    _selectedMinute = widget.selectedTime?.minute ?? now.minute;
    
    _hourController = FixedExtentScrollController(initialItem: _selectedHour);
    _minuteController = FixedExtentScrollController(initialItem: _selectedMinute);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // 頂部拖拽指示器
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // 標題列和關閉按鈕
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.grey100,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 32),
                Expanded(
                  child: Center(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 20,
                      color: AppColors.grey500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 時間滾動選擇器
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 小時選擇器
                Expanded(
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          '小時',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListWheelScrollView.useDelegate(
                          controller: _hourController,
                          itemExtent: 50,
                          perspective: 0.005,
                          diameterRatio: 1.2,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (index) {
                            setState(() {
                              _selectedHour = index;
                            });
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: 24,
                            builder: (context, index) {
                              final isSelected = index == _selectedHour;
                              return Container(
                                alignment: Alignment.center,
                                child: Text(
                                  index.toString().padLeft(2, '0'),
                                  style: TextStyle(
                                    fontSize: isSelected ? 24 : 18,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? AppColors.primary900 : AppColors.textSecondary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 分隔符（垂直居中對齊）
                Container(
                  padding: const EdgeInsets.only(top: 50), // 調整位置使其與數字對齊
                  child: const Text(
                    ':',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                
                // 分鐘選擇器
                Expanded(
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          '分鐘',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListWheelScrollView.useDelegate(
                          controller: _minuteController,
                          itemExtent: 50,
                          perspective: 0.005,
                          diameterRatio: 1.2,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (index) {
                            setState(() {
                              _selectedMinute = index;
                            });
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: 60,
                            builder: (context, index) {
                              final isSelected = index == _selectedMinute;
                              return Container(
                                alignment: Alignment.center,
                                child: Text(
                                  index.toString().padLeft(2, '0'),
                                  style: TextStyle(
                                    fontSize: isSelected ? 24 : 18,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? AppColors.primary900 : AppColors.textSecondary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // 確認按鈕
          Container(
            padding: EdgeInsets.fromLTRB(
              20, 
              20, 
              20, 
              MediaQuery.of(context).padding.bottom + 20,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  final selectedTime = TimeOfDay(
                    hour: _selectedHour,
                    minute: _selectedMinute,
                  );
                  widget.onTimeSelected(selectedTime);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary900,
                  foregroundColor: AppColors.textPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '確認',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 時間選擇器建構器
class TimePickerBuilder {
  /// 標準時間選擇器
  static Widget standard({
    required String label,
    TimeOfDay? value,
    ValueChanged<TimeOfDay?>? onChanged,
    String? errorText,
    bool isEnabled = true,
    String? dialogTitle,
  }) {
    return CustomTimePicker(
      label: label,
      value: value,
      onChanged: onChanged,
      errorText: errorText,
      isEnabled: isEnabled,
      dialogTitle: dialogTitle,
    );
  }
}
