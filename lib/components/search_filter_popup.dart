import 'package:flutter/material.dart';
import '../components/design_system/app_colors.dart';
import '../components/design_system/date_picker.dart';
import '../components/design_system/time_picker.dart';
import '../components/design_system/custom_dropdown.dart';
import '../components/design_system/custom_text_input.dart';
import '../components/design_system/custom_button.dart';
import '../components/design_system/custom_snackbar.dart';
import '../services/search_filter_service.dart';

class SearchFilterPopup extends StatefulWidget {
  final SearchFilterService searchFilterService;
  final VoidCallback onApplyFilters;

  const SearchFilterPopup({
    super.key,
    required this.searchFilterService,
    required this.onApplyFilters,
  });

  @override
  State<SearchFilterPopup> createState() => _SearchFilterPopupState();
}

class _SearchFilterPopupState extends State<SearchFilterPopup> with WidgetsBindingObserver {
  late TextEditingController _searchController;
  DateTime? _selectedDate; // 改為可空，null表示顯示placeholder
  TimeOfDay? _startTime; // 改為可空，null表示顯示placeholder
  TimeOfDay? _endTime; // 改為可空，null表示顯示placeholder
  String? _selectedCity; // 改為可空，null表示顯示placeholder
  String? _selectedArea; // 改為可空，null表示顯示placeholder
  bool _isOnlineActivity = false;

  // 滾動控制器
  final ScrollController _scrollController = ScrollController();
  
  // 鍵盤狀態追蹤
  double _previousViewInsetsBottom = 0;
  
  // 城市和地區選項
  final Map<String, List<String>> _cityAreaMap = {
    '台北市': ['大安區', '信義區', '中山區', '松山區', '大同區', '中正區', '萬華區', '文山區', '南港區', '內湖區', '士林區', '北投區'],
    '新北市': ['板橋區', '三重區', '中和區', '永和區', '新莊區', '新店區', '樹林區', '鶯歌區', '三峽區', '淡水區', '汐止區', '瑞芳區'],
    '桃園市': ['桃園區', '中壢區', '大溪區', '楊梅區', '蘆竹區', '大園區', '龜山區', '八德區', '龍潭區', '平鎮區', '新屋區', '觀音區'],
    '台中市': ['西屯區', '北屯區', '南屯區', '中區', '東區', '南區', '西區', '北區', '豐原區', '大里區', '太平區', '清水區'],
    '台南市': ['中西區', '東區', '南區', '北區', '安平區', '安南區', '永康區', '歸仁區', '新化區', '左鎮區', '玉井區', '楠西區'],
    '高雄市': ['新興區', '前金區', '苓雅區', '鹽埕區', '鼓山區', '旗津區', '前鎮區', '三民區', '楠梓區', '小港區', '左營區', '仁武區'],
  };

  // 錯誤狀態
  String? _searchError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeValues();
  }

  void _initializeValues() {
    // 從 SearchFilterService 讀取當前的篩選條件
    final service = widget.searchFilterService;
    
    // 搜尋關鍵字
    _searchController = TextEditingController(text: service.searchKeyword);
    
    // 日期
    _selectedDate = service.selectedDate;
    
    // 時間 - 只有在非預設值時才顯示
    final defaultStartTime = const TimeOfDay(hour: 0, minute: 0);
    final defaultEndTime = const TimeOfDay(hour: 23, minute: 0);
    _startTime = (service.startTime == defaultStartTime) ? null : service.startTime;
    _endTime = (service.endTime == defaultEndTime) ? null : service.endTime;
    
    // 位置 - 只有在非「全部」模式時才顯示
    if (service.currentCity.isNotEmpty && service.currentArea.isNotEmpty) {
      _selectedCity = service.currentCity;
      _selectedArea = service.currentArea;
    } else {
      _selectedCity = null;
      _selectedArea = null;
    }
    
    // 線上活動篩選
    _isOnlineActivity = service.isOnlineOnly;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    
    final currentViewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    
    // 檢查鍵盤是否從顯示變為隱藏
    if (_previousViewInsetsBottom > 0 && currentViewInsetsBottom == 0) {
      // 鍵盤隱藏時強制取消所有焦點
      _clearAllFocus();
    }
    
    _previousViewInsetsBottom = currentViewInsetsBottom;
  }

  /// 強制清除所有焦點
  void _clearAllFocus() {
    // 立即取消焦點
    FocusScope.of(context).unfocus();
    
    // 延遲再次確保焦點被清除
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        FocusScope.of(context).unfocus();
        // 強制將焦點移到一個不可見的節點
        FocusScope.of(context).requestFocus(FocusNode());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 獲取鍵盤高度
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Container(
      // 保持固定高度，不因鍵盤改變
      height: screenHeight * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // 頂部標題欄
          _buildHeader(),
          
          // 內容區域
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(
                24, 
                24, 
                24, 
                // 當鍵盤出現時，增加底部padding讓滾動區域加長
                24 + keyboardHeight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 日期時間區域
                  _buildDateTimeSection(),
                  
                  const SizedBox(height: 24),
                  _buildDivider(),
                  const SizedBox(height: 24),
                  
                  // 類型區域
                  _buildTypeSection(),
                  
                  const SizedBox(height: 24),
                  _buildDivider(),
                  const SizedBox(height: 24),
                  
                  // 地區區域 - 只有在非線上活動時顯示
                  if (!_isOnlineActivity) ...[
                    _buildLocationSection(),
                    
                    const SizedBox(height: 24),
                    _buildDivider(),
                    const SizedBox(height: 24),
                  ],
                  
                  // 關鍵字搜尋區域
                  _buildKeywordSection(),
                  
                  // 固定底部空間
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          
          // 底部按鈕 - 當鍵盤出現時隱藏，避免佈局問題
          if (keyboardHeight == 0) _buildBottomButtons(),
          
          // 當鍵盤出現時，顯示浮動的應用按鈕
          if (keyboardHeight > 0) _buildFloatingApplyButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '篩選條件',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close,
              color: Colors.black,
              size: 24,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '日期時間',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        
        // 日期選擇
        DatePickerBuilder.standard(
          label: '日期',
          value: _selectedDate, // 綁定用戶選擇的值
          onChanged: (date) {
            setState(() {
              _selectedDate = date;
            });
          },
          dialogTitle: '選擇日期',
        ),
        
        const SizedBox(height: 16),
        
        // 時間選擇
        Row(
          children: [
            Expanded(
              child: TimePickerBuilder.standard(
                label: '開始時間',
                value: _startTime, // 綁定用戶選擇的值
                onChanged: (time) {
                  setState(() {
                    _startTime = time;
                  });
                },
                dialogTitle: '選擇開始時間',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TimePickerBuilder.standard(
                label: '結束時間',
                value: _endTime, // 綁定用戶選擇的值
                onChanged: (time) {
                  setState(() {
                    _endTime = time;
                  });
                },
                dialogTitle: '選擇結束時間',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '類型',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '預設為實體活動。',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        
        // 線上活動切換
        Container(
          padding: const EdgeInsets.only(left: 16, right: 12, top: 12, bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.grey300,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '線上活動 / 任務',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              Switch(
                value: _isOnlineActivity,
                onChanged: (value) {
                  setState(() {
                    _isOnlineActivity = value;
                  });
                },
                activeThumbColor: AppColors.primary900,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '地區',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '預設顯示全部地區的活動。',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: DropdownBuilder.dialog<String>(
                label: '城市',
                dialogTitle: '選擇城市',
                value: _selectedCity, // 綁定用戶選擇的值
                onChanged: (value) {
                  setState(() {
                    _selectedCity = value;
                    // 重置地區選擇為空，讓用戶重新選擇
                    _selectedArea = null;
                  });
                },
                items: _cityAreaMap.keys.map((city) => 
                  DropdownItem(value: city, label: city)
                ).toList(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownBuilder.dialog<String>(
                label: '地區',
                dialogTitle: '選擇地區',
                value: _selectedArea, // 綁定用戶選擇的值
                onChanged: (value) {
                  setState(() {
                    _selectedArea = value;
                  });
                },
                items: _selectedCity != null 
                    ? (_cityAreaMap[_selectedCity!] ?? []).map((area) => 
                        DropdownItem(value: area, label: area)
                      ).toList()
                    : [], // 城市未選擇時，地區選項為空
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeywordSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '關鍵字搜尋',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        
        Focus(
          onFocusChange: (hasFocus) {
            if (hasFocus) {
              // 當搜尋框獲得焦點時，延遲滾動到底部確保搜尋框可見
              Future.delayed(const Duration(milliseconds: 300), () {
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              });
            }
          },
          child: CustomTextInput(
            label: '搜尋',
            controller: _searchController,
            errorText: _searchError,
            onChanged: (value) {
              setState(() {
                _searchError = null; // 清除錯誤當用戶輸入時
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: Colors.grey.shade200,
    );
  }

  Widget _buildFloatingApplyButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 16),
          child: ButtonBuilder.primary(
            onPressed: _applyFilters,
            text: '開始搜尋',
            width: double.infinity,
            height: 54.0,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 16),
          child: SizedBox(
            height: 54.0,
            child: Row(
              children: [
                // 清除全部 - 使用價格顯示樣式
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _clearAllFilters,
                      child: const Text(
                        '清除全部',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                          decoration: TextDecoration.underline,
                          decorationThickness: 2,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const Spacer(),
                
                // 開始搜尋按鈕 - 使用立即報名按鈕樣式
                ButtonBuilder.primary(
                  onPressed: _applyFilters,
                  text: '開始搜尋',
                  width: 140,
                  height: 54.0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  // 清除所有篩選條件
  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _selectedDate = null; // 重置為null，顯示placeholder
      _startTime = null; // 重置為null，顯示placeholder
      _endTime = null; // 重置為null，顯示placeholder
      _selectedCity = null; // 重置為null，顯示placeholder
      _selectedArea = null; // 重置為null，顯示placeholder
      _isOnlineActivity = false;
    });
    
    // 顯示清除成功提示
    CustomSnackBarBuilder.success(context, '已成功清除');
  }

  // 應用篩選條件
  void _applyFilters() {
    // 更新搜尋篩選服務
    widget.searchFilterService.updateSearchKeyword(_searchController.text);
    
    // 日期：如果用戶沒有選擇日期，傳遞null表示整個月份
    widget.searchFilterService.updateSelectedDate(_selectedDate);
    
    // 時間：如果用戶沒選擇，使用預設的00:00-23:00
    final startTimeToApply = _startTime ?? const TimeOfDay(hour: 0, minute: 0);
    final endTimeToApply = _endTime ?? const TimeOfDay(hour: 23, minute: 0);
    widget.searchFilterService.updateStartTime(startTimeToApply);
    widget.searchFilterService.updateEndTime(endTimeToApply);
    
    // 位置：只有在用戶選擇了具體位置時才設定，否則重置為「全部」
    if (_selectedCity != null && _selectedArea != null) {
      widget.searchFilterService.updateLocation(_selectedCity!, _selectedArea!);
    } else {
      // 重置為「全部」模式
      widget.searchFilterService.resetToAllLocations();
    }
    
    widget.searchFilterService.updateOnlineOnly(_isOnlineActivity);
    
    // 觸發篩選應用
    widget.onApplyFilters();
    
    // 關閉彈窗
    Navigator.of(context).pop();
  }
}
