import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// 搜尋篩選服務
class SearchFilterService extends ChangeNotifier {
  // 服務狀態
  bool _disposed = false;
  
  // 位置相關
  String _currentCity = '台北市';
  String _currentArea = '大安區';
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  
  // 日期時間相關
  DateTime? _selectedDate; // 改為可空，null表示整個月份
  TimeOfDay _startTime = const TimeOfDay(hour: 0, minute: 0); // 00:00
  TimeOfDay _endTime = const TimeOfDay(hour: 23, minute: 0); // 23:00
  
  // 搜尋關鍵字
  String _searchKeyword = '';
  
  // 活動類型篩選
  bool _isOnlineOnly = false;
  
  // Getters
  String get currentCity => _currentCity;
  String get currentArea => _currentArea;
  String get locationText {
    if (_isOnlineOnly) {
      return '線上活動';
    }
    
    // 如果沒有獲取到具體位置，顯示「全部」
    if (_currentPosition == null) {
      return '全部';
    }
    
    return '$_currentCity，$_currentArea';
  }
  Position? get currentPosition => _currentPosition;
  bool get isLoadingLocation => _isLoadingLocation;
  
  DateTime? get selectedDate => _selectedDate;
  TimeOfDay get startTime => _startTime;
  TimeOfDay get endTime => _endTime;
  String get searchKeyword => _searchKeyword;
  bool get isOnlineOnly => _isOnlineOnly;
  
  String get dateText {
    if (_selectedDate == null) {
      // 沒有選擇具體日期，顯示當前月份
      final now = DateTime.now();
      return '${now.month}月';
    }
    return '${_selectedDate!.month}/${_selectedDate!.day}';
  }
  
  String get timeText {
    final startHour = _startTime.hour.toString().padLeft(2, '0');
    final startMinute = _startTime.minute.toString().padLeft(2, '0');
    final endHour = _endTime.hour.toString().padLeft(2, '0');
    final endMinute = _endTime.minute.toString().padLeft(2, '0');
    return '$startHour:$startMinute - $endHour:$endMinute';
  }
  
  /// 初始化服務
  Future<void> initialize() async {
    await _getCurrentLocation();
    _initializeDefaultTime();
  }
  
  /// 獲取當前位置
  Future<void> _getCurrentLocation() async {
    if (_disposed) return;
    _isLoadingLocation = true;
    notifyListeners();
    
    try {
      // 檢查位置服務是否啟用
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('位置服務未啟用');
        _isLoadingLocation = false;
        if (!_disposed) notifyListeners();
        return;
      }
      
      // 檢查位置權限
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('位置權限被拒絕');
          _isLoadingLocation = false;
          if (!_disposed) notifyListeners();
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        debugPrint('位置權限被永久拒絕');
        _isLoadingLocation = false;
        if (!_disposed) notifyListeners();
        return;
      }
      
      // 獲取當前位置
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      _currentPosition = position;
      
      // 這裡可以使用反向地理編碼來獲取實際的城市和區域
      // 暫時使用預設值
      await _updateLocationFromCoordinates(position);
      
    } catch (e) {
      debugPrint('獲取位置失敗: $e');
    } finally {
      _isLoadingLocation = false;
      if (!_disposed) notifyListeners();
    }
  }
  
  /// 從座標更新位置信息（簡化版本）
  Future<void> _updateLocationFromCoordinates(Position position) async {
    // 這裡應該使用反向地理編碼API來獲取實際地址
    // 暫時根據座標範圍來判斷大致區域
    
    // 台北市大致範圍
    if (position.latitude >= 24.9 && position.latitude <= 25.3 &&
        position.longitude >= 121.4 && position.longitude <= 121.7) {
      _currentCity = '台北市';
      
      // 簡單的區域判斷
      if (position.latitude >= 25.0 && position.latitude <= 25.1) {
        _currentArea = '大安區';
      } else if (position.latitude >= 25.1 && position.latitude <= 25.2) {
        _currentArea = '中山區';
      } else {
        _currentArea = '信義區';
      }
    } else {
      // 其他城市的簡單判斷
      _currentCity = '新北市';
      _currentArea = '板橋區';
    }
  }
  
  /// 初始化預設時間
  void _initializeDefaultTime() {
    // 設定為全天時間範圍
    _startTime = const TimeOfDay(hour: 0, minute: 0);  // 00:00
    _endTime = const TimeOfDay(hour: 23, minute: 0);   // 23:00
  }
  
  /// 更新搜尋關鍵字
  void updateSearchKeyword(String keyword) {
    if (_disposed) return;
    _searchKeyword = keyword;
    notifyListeners();
  }
  
  /// 更新選中的日期
  void updateSelectedDate(DateTime? date) {
    if (_disposed) return;
    _selectedDate = date;
    notifyListeners();
  }
  
  /// 更新開始時間
  void updateStartTime(TimeOfDay time) {
    if (_disposed) return;
    _startTime = time;
    notifyListeners();
  }
  
  /// 更新結束時間
  void updateEndTime(TimeOfDay time) {
    if (_disposed) return;
    _endTime = time;
    notifyListeners();
  }
  
  /// 手動設定位置
  void updateLocation(String city, String area) {
    if (_disposed) return;
    _currentCity = city;
    _currentArea = area;
    notifyListeners();
  }
  
  /// 更新線上活動篩選
  void updateOnlineOnly(bool isOnlineOnly) {
    if (_disposed) return;
    _isOnlineOnly = isOnlineOnly;
    notifyListeners();
  }
  
  /// 重新獲取位置
  Future<void> refreshLocation() async {
    await _getCurrentLocation();
  }
  
  /// 重置篩選條件
  void resetFilters() {
    if (_disposed) return;
    _selectedDate = null; // 重置為null，顯示整個月份
    _initializeDefaultTime();
    _searchKeyword = '';
    _isOnlineOnly = false;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
  
  /// 檢查活動是否符合篩選條件
  bool matchesFilters(Map<String, dynamic> activity) {
    // 關鍵字篩選
    if (_searchKeyword.isNotEmpty) {
      final name = activity['name']?.toString().toLowerCase() ?? '';
      final description = activity['description']?.toString().toLowerCase() ?? '';
      final keyword = _searchKeyword.toLowerCase();
      
      if (!name.contains(keyword) && !description.contains(keyword)) {
        return false;
      }
    }
    
    // 日期篩選
    if (_selectedDate != null && activity['startDateTime'] != null) {
      try {
        final activityDate = DateTime.parse(activity['startDateTime']);
        final selectedDateStart = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
        final selectedDateEnd = selectedDateStart.add(const Duration(days: 1));
        
        if (activityDate.isBefore(selectedDateStart) || activityDate.isAfter(selectedDateEnd)) {
          return false;
        }
      } catch (e) {
        debugPrint('日期解析失敗: $e');
      }
    } else if (_selectedDate == null && activity['startDateTime'] != null) {
      // 如果沒有選擇具體日期，只篩選當前月份的活動
      try {
        final activityDate = DateTime.parse(activity['startDateTime']);
        final now = DateTime.now();
        
        if (activityDate.year != now.year || activityDate.month != now.month) {
          return false;
        }
      } catch (e) {
        debugPrint('月份篩選日期解析失敗: $e');
      }
    }
    
    // 時間篩選
    if (activity['startDateTime'] != null && activity['endDateTime'] != null) {
      try {
        final activityStart = DateTime.parse(activity['startDateTime']);
        final activityEnd = DateTime.parse(activity['endDateTime']);
        
        final filterStartMinutes = _startTime.hour * 60 + _startTime.minute;
        final filterEndMinutes = _endTime.hour * 60 + _endTime.minute;
        final activityStartMinutes = activityStart.hour * 60 + activityStart.minute;
        final activityEndMinutes = activityEnd.hour * 60 + activityEnd.minute;
        
        // 檢查時間範圍是否有重疊
        if (activityEndMinutes <= filterStartMinutes || activityStartMinutes >= filterEndMinutes) {
          return false;
        }
      } catch (e) {
        debugPrint('時間解析失敗: $e');
      }
    }
    
    // 活動類型篩選（線上/實體）
    final isOnline = activity['isOnline'] ?? false;
    if (_isOnlineOnly && !isOnline) {
      return false; // 只顯示線上活動，但這是實體活動
    }
    
    // 位置篩選（如果活動有位置信息且不是線上活動）
    if (!isOnline && !_isOnlineOnly) {
      // 如果顯示「全部」（沒有獲取到具體位置），則不進行位置篩選
      if (_currentPosition == null) {
        // 全部模式，不篩選位置，顯示所有地區的活動
        return true;
      }
      
      // 如果有具體位置，則進行位置篩選
      final activityCity = activity['city']?.toString() ?? '';
      if (activityCity.isNotEmpty && activityCity != _currentCity) {
        return false; // 篩選掉不同城市的活動
      }
    }
    
    return true;
  }
}

