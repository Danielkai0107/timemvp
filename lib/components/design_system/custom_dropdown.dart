import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 自定義下拉選單組件，與 CustomTextInput 保持一致的設計風格
/// 支援傳統下拉選單和彈窗式選擇器兩種模式
class CustomDropdown<T> extends StatefulWidget {
  const CustomDropdown({
    super.key,
    required this.label,
    required this.items,
    this.value,
    this.onChanged,
    this.isEnabled = true,
    this.errorText,
    this.height = 60.0,
    this.borderRadius = 12.0,
    this.showAsDialog = false,
    this.dialogTitle,
    this.multiSelect = false,
    this.selectedValues,
    this.onMultiSelectChanged,
  });

  /// 標籤文字（浮動標籤）
  final String label;
  
  /// 下拉選項列表
  final List<DropdownItem<T>> items;
  
  /// 當前選中值（單選模式）
  final T? value;
  
  /// 值變化回調（單選模式）
  final ValueChanged<T?>? onChanged;
  
  /// 是否啟用
  final bool isEnabled;
  
  /// 錯誤文字
  final String? errorText;
  
  /// 下拉框高度
  final double height;
  
  /// 邊框圓角
  final double borderRadius;

  /// 是否以對話框形式顯示
  final bool showAsDialog;

  /// 對話框標題
  final String? dialogTitle;

  /// 是否支援多選
  final bool multiSelect;

  /// 當前選中的多個值
  final List<T>? selectedValues;

  /// 多選值變化回調
  final ValueChanged<List<T>>? onMultiSelectChanged;

  @override
  CustomDropdownState<T> createState() => CustomDropdownState<T>();
}

class CustomDropdownState<T> extends State<CustomDropdown<T>> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  List<T> _selectedValues = [];

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    
    // 初始化多選值
    if (widget.multiSelect && widget.selectedValues != null) {
      _selectedValues = List.from(widget.selectedValues!);
    }
    
    // 監聽聚焦變化
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void didUpdateWidget(CustomDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 更新多選值
    if (widget.multiSelect && widget.selectedValues != null) {
      _selectedValues = List.from(widget.selectedValues!);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  /// 判斷標籤是否應該浮動到頂部
  bool get _shouldFloatLabel {
    if (widget.multiSelect) {
      return _selectedValues.isNotEmpty || _isFocused;
    }
    return widget.value != null || _isFocused;
  }

  /// 獲取顯示文字
  String get _displayText {
    if (widget.multiSelect) {
      if (_selectedValues.isEmpty) return '';
      if (_selectedValues.length == 1) {
        final item = widget.items.firstWhere((item) => item.value == _selectedValues.first);
        return item.label;
      }
      return '已選擇 ${_selectedValues.length} 項';
    } else {
      if (widget.value == null) return '';
      final item = widget.items.firstWhere((item) => item.value == widget.value);
      return item.label;
    }
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

  /// 顯示底部選擇器
  void _showSelectionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return SelectionDialog<T>(
          title: widget.dialogTitle ?? widget.label,
          items: widget.items,
          selectedValue: widget.value,
          selectedValues: _selectedValues,
          multiSelect: widget.multiSelect,
          onSingleSelect: (value) {
            Navigator.of(context).pop();
            if (widget.onChanged != null) {
              widget.onChanged!(value);
            }
          },
          onMultiSelect: (values) {
            Navigator.of(context).pop();
            setState(() {
              _selectedValues = values;
            });
            if (widget.onMultiSelectChanged != null) {
              widget.onMultiSelectChanged!(values);
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
              if (widget.showAsDialog) {
                _showSelectionDialog();
              } else {
                _focusNode.requestFocus();
              }
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
                // 傳統下拉選單或顯示文字
                if (widget.showAsDialog)
                  // 對話框模式 - 顯示選中的值
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
                  )
                else
                  // 傳統下拉選單模式
                  Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: _shouldFloatLabel ? 26 : 20,
                      bottom: 8,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<T>(
                        focusNode: _focusNode,
                        value: widget.value,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: AppColors.grey500,
                          size: 24,
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                        onChanged: widget.isEnabled ? widget.onChanged : null,
                        items: widget.items.map((item) {
                          return DropdownMenuItem<T>(
                            value: item.value,
                            child: Text(
                              item.label,
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                
                // 下拉箭頭（對話框模式）
                if (widget.showAsDialog)
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
        
        // 錯誤文字區域（始終預留空間）
        const SizedBox(height: 4),
        Container(
          height: 16, // 固定高度，相當於12px字體 + 4px行間距
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
            : null, // 沒有錯誤時顯示空白，但保持高度
        ),
      ],
    );
  }
}

/// 下拉選項資料結構
class DropdownItem<T> {
  const DropdownItem({
    required this.value,
    required this.label,
  });

  /// 選項值
  final T value;
  
  /// 顯示標籤
  final String label;
}

/// 下拉選單建構器
class DropdownBuilder {
  /// 性別下拉選單
  static Widget gender({
    String? value,
    ValueChanged<String?>? onChanged,
    String? errorText,
    bool isEnabled = true,
  }) {
    return CustomDropdown<String>(
      label: '性別',
      value: value,
      onChanged: onChanged,
      errorText: errorText,
      isEnabled: isEnabled,
      items: const [
        DropdownItem(value: 'male', label: '男性'),
        DropdownItem(value: 'female', label: '女性'),
        DropdownItem(value: 'other', label: '其他'),
        DropdownItem(value: 'prefer_not_to_say', label: '不願透露'),
      ],
    );
  }

  /// 年齡下拉選單（18-65）
  static Widget age({
    int? value,
    ValueChanged<int?>? onChanged,
    String? errorText,
    bool isEnabled = true,
    int minAge = 18,
    int maxAge = 65,
  }) {
    final ageItems = List.generate(
      maxAge - minAge + 1,
      (index) => DropdownItem<int>(
        value: minAge + index,
        label: '${minAge + index} 歲',
      ),
    );

    return CustomDropdown<int>(
      label: '年齡',
      value: value,
      onChanged: onChanged,
      errorText: errorText,
      isEnabled: isEnabled,
      items: ageItems,
    );
  }

  /// 自定義下拉選單
  static Widget custom<T>({
    required String label,
    required List<DropdownItem<T>> items,
    T? value,
    ValueChanged<T?>? onChanged,
    String? errorText,
    bool isEnabled = true,
  }) {
    return CustomDropdown<T>(
      label: label,
      items: items,
      value: value,
      onChanged: onChanged,
      errorText: errorText,
      isEnabled: isEnabled,
    );
  }

  /// 對話框樣式的下拉選單
  static Widget dialog<T>({
    required String label,
    required List<DropdownItem<T>> items,
    T? value,
    ValueChanged<T?>? onChanged,
    String? errorText,
    bool isEnabled = true,
    String? dialogTitle,
    bool multiSelect = false,
    List<T>? selectedValues,
    ValueChanged<List<T>>? onMultiSelectChanged,
  }) {
    return CustomDropdown<T>(
      label: label,
      items: items,
      value: value,
      onChanged: onChanged,
      errorText: errorText,
      isEnabled: isEnabled,
      showAsDialog: true,
      dialogTitle: dialogTitle,
      multiSelect: multiSelect,
      selectedValues: selectedValues,
      onMultiSelectChanged: onMultiSelectChanged,
    );
  }
}

/// 選擇對話框
class SelectionDialog<T> extends StatefulWidget {
  const SelectionDialog({
    super.key,
    required this.title,
    required this.items,
    this.selectedValue,
    this.selectedValues = const [],
    this.multiSelect = false,
    this.onSingleSelect,
    this.onMultiSelect,
  });

  final String title;
  final List<DropdownItem<T>> items;
  final T? selectedValue;
  final List<T> selectedValues;
  final bool multiSelect;
  final ValueChanged<T?>? onSingleSelect;
  final ValueChanged<List<T>>? onMultiSelect;

  @override
  SelectionDialogState<T> createState() => SelectionDialogState<T>();
}

class SelectionDialogState<T> extends State<SelectionDialog<T>> {
  late List<T> _selectedValues;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedValues = List.from(widget.selectedValues);
    
    // 在 widget 建立後滾動到選中項目
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedItem();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedItem() {
    if (!widget.multiSelect && widget.selectedValue != null) {
      final selectedIndex = widget.items.indexWhere(
        (item) => item.value == widget.selectedValue,
      );
      
      if (selectedIndex != -1 && _scrollController.hasClients) {
        final itemHeight = 64.0; // ListTile 高度 (16*2 padding + 32 content)
        final scrollPosition = selectedIndex * itemHeight;
        final maxScroll = _scrollController.position.maxScrollExtent;
        final viewportHeight = _scrollController.position.viewportDimension;
        
        // 計算最佳滾動位置，讓選中項目在螢幕中央
        final targetPosition = (scrollPosition - viewportHeight / 2 + itemHeight / 2)
            .clamp(0.0, maxScroll);
        
        _scrollController.animateTo(
          targetPosition,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _toggleSelection(T value) {
    setState(() {
      if (_selectedValues.contains(value)) {
        _selectedValues.remove(value);
      } else {
        _selectedValues.add(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
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
                  color: Color(0xFFF0F0F0),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // 左側空白區域（與關閉按鈕寬度相同，保持標題居中）
                const SizedBox(width: 32),
                // 置中的標題
                Expanded(
                  child: Center(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                // 右側的關閉按鈕
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 選項列表
          Flexible(
            child: ListView.builder(
              controller: _scrollController,
              shrinkWrap: true,
              padding: const EdgeInsets.all(0),
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final isSelected = widget.multiSelect
                    ? _selectedValues.contains(item.value)
                    : widget.selectedValue == item.value;

                return Container(
                  decoration: BoxDecoration(
                    border: index < widget.items.length - 1
                        ? const Border(
                            bottom: BorderSide(
                              color: Color(0xFFF8F8F8),
                              width: 1,
                            ),
                          )
                        : null,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    title: Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    trailing: widget.multiSelect
                        ? Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected 
                                    ? Colors.black 
                                    : Colors.grey.shade300,
                                width: 2,
                              ),
                              color: isSelected ? Colors.black : Colors.transparent,
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: AppColors.white,
                                  )
                                : null,
                          )
                        : Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected 
                                    ? AppColors.primary900  // 黃色邊框
                                    : Colors.grey.shade300,
                                width: isSelected ? 6 : 2,  // 已選取時較粗的邊框形成圓環
                              ),
                              color: Colors.transparent,
                            ),
                          ),
                    onTap: () {
                      if (widget.multiSelect) {
                        _toggleSelection(item.value);
                      } else {
                        if (widget.onSingleSelect != null) {
                          widget.onSingleSelect!(item.value);
                        }
                      }
                    },
                  ),
                );
              },
            ),
          ),
          
          // 確認按鈕（僅多選模式）
          if (widget.multiSelect) ...[
            Container(
              padding: EdgeInsets.fromLTRB(
                20, 
                20, 
                20, 
                MediaQuery.of(context).padding.bottom + 20,
              ),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Color(0xFFF0F0F0),
                    width: 1,
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    if (widget.onMultiSelect != null) {
                      widget.onMultiSelect!(_selectedValues);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.black,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '確認',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            // 添加底部安全區域間距（單選模式）
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ],
      ),
    );
  }
}
