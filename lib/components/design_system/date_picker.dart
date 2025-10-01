import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 自定義日期選擇器組件
/// 提供年、月、日三層選擇界面
class CustomDatePicker extends StatefulWidget {
  const CustomDatePicker({
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
  
  /// 當前選中的日期
  final DateTime? value;
  
  /// 日期變化回調
  final ValueChanged<DateTime?>? onChanged;
  
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
  CustomDatePickerState createState() => CustomDatePickerState();
}

class CustomDatePickerState extends State<CustomDatePicker> {
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
    return '${widget.value!.month}/${widget.value!.day}';
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

  /// 顯示日期選擇對話框
  void _showDatePickerDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DatePickerDialog(
          title: widget.dialogTitle ?? widget.label,
          selectedDate: widget.value,
          onDateSelected: (date) {
            Navigator.of(context).pop();
            if (widget.onChanged != null) {
              widget.onChanged!(date);
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
              _showDatePickerDialog();
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
                // 顯示選中的日期
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

/// 日期選擇對話框
class DatePickerDialog extends StatefulWidget {
  const DatePickerDialog({
    super.key,
    required this.title,
    this.selectedDate,
    required this.onDateSelected,
  });

  final String title;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  DatePickerDialogState createState() => DatePickerDialogState();
}

class DatePickerDialogState extends State<DatePickerDialog> {
  late ScrollController _scrollController;
  DateTime? _selectedDate;
  DateTime? _tempSelectedDate; // 臨時選中的日期，用於確認前的預覽
  
  // 生成從當前月份開始的24個月（未來2年）
  late List<DateTime> _monthsList;
  bool _hasScrolledToInitial = false; // 標記是否已經執行過初始滾動

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = widget.selectedDate;
    _tempSelectedDate = widget.selectedDate; // 初始化臨時選中日期
    
    // 生成月份列表（從當月開始，包含未來24個月）
    _monthsList = List.generate(24, (index) {
      return DateTime(now.year, now.month + index, 1);
    });
    
    _scrollController = ScrollController();
    
    // 如果有選中的日期，滾動到該月份（只執行一次）
    if (widget.selectedDate != null && !_hasScrolledToInitial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelectedMonth();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 滾動到選中日期的月份（只執行一次）
  void _scrollToSelectedMonth() {
    if (_selectedDate == null || _hasScrolledToInitial) return;
    
    final selectedMonthIndex = _monthsList.indexWhere((month) => 
        month.year == _selectedDate!.year && month.month == _selectedDate!.month);
    
    if (selectedMonthIndex != -1 && _scrollController.hasClients) {
      // 每個月曆的實際高度：
      // 月份標題: 18px(字體) + 16px(bottom padding) = 34px
      // 網格: 6行 * 40px(childAspectRatio=1的實際高度) + 5行間距 * 4px = 240px + 20px = 260px  
      // 底部間距: 24px
      // 總計: 34 + 260 + 24 = 318px
      final itemHeight = 318.0;
      final scrollOffset = selectedMonthIndex * itemHeight;
      
      // 確保不會滾動超出範圍
      final maxScrollOffset = (_monthsList.length - 1) * itemHeight;
      final targetOffset = scrollOffset.clamp(0.0, maxScrollOffset);
      
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      _hasScrolledToInitial = true; // 標記已執行過初始滾動
    }
  }

  /// 確認選擇日期
  void _confirmSelection() {
    if (_tempSelectedDate != null) {
      widget.onDateSelected(_tempSelectedDate!);
    }
  }

  /// 獲取指定年月的天數
  int _getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  /// 獲取月份第一天是星期幾（0=星期日）
  int _getFirstDayOfWeek(DateTime date) {
    return DateTime(date.year, date.month, 1).weekday % 7;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
        minHeight: 500,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          
          // 星期標題（固定）
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['日', '一', '二', '三', '四', '五', '六']
                  .map((day) => Text(
                        day,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ))
                  .toList(),
            ),
          ),
          
          // 月曆內容（垂直滾動）
          Flexible(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shrinkWrap: true,
              itemCount: _monthsList.length,
              itemBuilder: (context, index) {
                final monthDate = _monthsList[index];
                return _buildMonthView(monthDate);
              },
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
                onPressed: _tempSelectedDate != null ? _confirmSelection : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _tempSelectedDate != null 
                      ? AppColors.primary900 
                      : AppColors.grey300,
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

  /// 構建月份視圖
  Widget _buildMonthView(DateTime monthDate) {
    final daysInMonth = _getDaysInMonth(monthDate);
    final firstDayOfWeek = _getFirstDayOfWeek(monthDate);
    final daysInPrevMonth = _getDaysInMonth(DateTime(monthDate.year, monthDate.month - 1, 1));
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 月份標題
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              '${monthDate.year}年${monthDate.month}月',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          
          // 日期網格
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(), // 禁用內部滾動
            shrinkWrap: true, // 讓GridView適應內容高度
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: 42, // 6週 x 7天
            itemBuilder: (context, index) {
              final dayIndex = index - firstDayOfWeek + 1;
              
              if (dayIndex < 1) {
                // 上個月的日期
                final prevMonthDay = daysInPrevMonth + dayIndex;
                return Center(
                  child: Text(
                    '$prevMonthDay',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.grey300,
                    ),
                  ),
                );
              } else if (dayIndex > daysInMonth) {
                // 下個月的日期
                final nextMonthDay = dayIndex - daysInMonth;
                return Center(
                  child: Text(
                    '$nextMonthDay',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.grey300,
                    ),
                  ),
                );
              }
              
              // 當月日期
              final currentDate = DateTime(monthDate.year, monthDate.month, dayIndex);
              final isSelected = _tempSelectedDate != null &&
                  _tempSelectedDate!.year == currentDate.year &&
                  _tempSelectedDate!.month == currentDate.month &&
                  _tempSelectedDate!.day == currentDate.day;
              final isToday = _isToday(currentDate);
              final isPastDate = currentDate.isBefore(todayDateOnly); // 檢查是否為過去日期
              
              return GestureDetector(
                onTap: isPastDate ? null : () {
                  setState(() {
                    _tempSelectedDate = currentDate;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Colors.black
                        : isToday 
                            ? AppColors.primary900.withValues(alpha: 0.2)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      '$dayIndex',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected || isToday ? FontWeight.w600 : FontWeight.normal,
                        color: isPastDate
                            ? AppColors.grey300 // 過去日期顯示為灰色
                            : isSelected 
                                ? Colors.white
                                : isToday
                                    ? AppColors.primary900
                                    : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}

/// 日期選擇器建構器
class DatePickerBuilder {
  /// 標準日期選擇器
  static Widget standard({
    required String label,
    DateTime? value,
    ValueChanged<DateTime?>? onChanged,
    String? errorText,
    bool isEnabled = true,
    String? dialogTitle,
  }) {
    return CustomDatePicker(
      label: label,
      value: value,
      onChanged: onChanged,
      errorText: errorText,
      isEnabled: isEnabled,
      dialogTitle: dialogTitle,
    );
  }
}
