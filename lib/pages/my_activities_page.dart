import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/design_system/app_colors.dart';
import '../components/design_system/custom_dropdown.dart';
import '../components/design_system/activity_status_badge.dart';
import '../components/design_system/custom_snackbar.dart';
import '../components/design_system/success_popup.dart';
import '../components/my_activity_card.dart';
import '../services/activity_service.dart';
import '../services/auth_service.dart';
import '../services/category_service.dart';
import 'activity_detail_page.dart';

class MyActivitiesPage extends StatefulWidget {
  const MyActivitiesPage({super.key});

  @override
  State<MyActivitiesPage> createState() => _MyActivitiesPageState();
}

/// 全域的 MyActivitiesPage 狀態控制器
class MyActivitiesPageController {
  static _MyActivitiesPageState? _currentState;
  
  static void _register(_MyActivitiesPageState state) {
    _currentState = state;
  }
  
  static void _unregister() {
    _currentState = null;
  }
  
  /// 觸發重新載入活動數據
  static void refreshActivities() {
    _currentState?._refreshFromExternal();
  }
}

class _MyActivitiesPageState extends State<MyActivitiesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ActivityService _activityService = ActivityService();
  final AuthService _authService = AuthService();
  final CategoryService _categoryService = CategoryService();
  
  bool _isLoading = false;
  List<Map<String, dynamic>> _registeredActivities = [];
  List<Map<String, dynamic>> _publishedActivities = [];
  List<Map<String, dynamic>> _filteredRegisteredActivities = [];
  List<Map<String, dynamic>> _filteredPublishedActivities = [];
  String? _error;
  
  // 篩選狀態
  String? _selectedRegisteredStatus;
  String? _selectedPublishedStatus;
  String? _selectedCategory;
  
  // 分類相關
  List<Category> _allCategories = [];
  bool _isLoadingCategories = false;
  
  // 隱藏的活動列表
  Set<String> _hiddenActivities = {};

  @override
  void initState() {
    super.initState();
    
    // 註冊到全域控制器
    MyActivitiesPageController._register(this);
    
    _tabController = TabController(length: 2, vsync: this);
    
    // 監聽分頁切換，重新構建篩選區域並重新整理數據
    _tabController.addListener(() {
      if (mounted && _tabController.indexIsChanging) {
        setState(() {});
        // 分頁切換時自動重新整理
        _loadActivities();
      }
    });
    
    _loadHiddenActivities();
    _loadActivities();
    _loadCategories();
  }

  @override
  void dispose() {
    // 從全域控制器註銷
    MyActivitiesPageController._unregister();
    _tabController.dispose();
    super.dispose();
  }

  /// 載入分類數據
  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      debugPrint('載入所有分類數據...');
      final categories = await _categoryService.getAllCategories();
      
      if (mounted) {
        setState(() {
          _allCategories = categories;
          _isLoadingCategories = false;
        });
      }
      
      debugPrint('從 Firebase 載入了 ${categories.length} 個分類');
    } catch (e) {
      debugPrint('從 Firebase 載入分類失敗: $e');
      
      // 只有在 Firebase 完全失敗時才使用備用數據
      try {
        final fallbackCategories = await _categoryService.getCategoriesWithFallback();
        
        if (mounted) {
          setState(() {
            _allCategories = fallbackCategories;
            _isLoadingCategories = false;
          });
        }
        
        debugPrint('使用備用分類數據，載入了 ${fallbackCategories.length} 個分類');
      } catch (fallbackError) {
        debugPrint('備用分類數據也載入失敗: $fallbackError');
        if (mounted) {
          setState(() {
            _isLoadingCategories = false;
            _allCategories = [];
          });
        }
      }
    }
  }


  /// 載入活動數據
  Future<void> _loadActivities() async {
    if (_isLoading) return;
    
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint('=== MyActivitiesPage: 開始載入活動數據 ===');
      
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('用戶未登入');
      }

      debugPrint('當前用戶: ${currentUser.uid}');

      // 並行載入報名活動和發布活動
      debugPrint('開始並行載入報名活動和發布活動...');
      final results = await Future.wait([
        _activityService.getUserRegisteredActivities(userId: currentUser.uid),
        _activityService.getUserPublishedActivities(userId: currentUser.uid),
      ]);

      debugPrint('載入完成:');
      debugPrint('- 報名活動數量: ${results[0].length}');
      debugPrint('- 發布活動數量: ${results[1].length}');

      if (!mounted) return;
      setState(() {
        _registeredActivities = results[0];
        _publishedActivities = results[1];
        _isLoading = false;
      });
      
      debugPrint('狀態更新完成，開始應用篩選...');
      
      // 應用篩選
      _applyFilters();
      
      // 檢查是否有被取消的活動通知
      _checkCancelledActivityNotifications(currentUser.uid);
      
      debugPrint('=== 活動數據載入完成 ===');
    } catch (e) {
      debugPrint('=== 載入活動數據失敗 ===');
      debugPrint('錯誤: $e');
      
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// 刷新數據
  Future<void> _refreshActivities() async {
    await _loadActivities();
  }

  /// 從外部觸發的重整方法
  Future<void> _refreshFromExternal() async {
    debugPrint('=== 從外部觸發重整 ===');
    await _refreshActivities();
  }

  /// 載入隱藏的活動列表
  Future<void> _loadHiddenActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final hiddenList = prefs.getStringList('hidden_activities_${currentUser.uid}') ?? [];
        setState(() {
          _hiddenActivities = hiddenList.toSet();
        });
        debugPrint('載入隱藏活動列表: ${_hiddenActivities.length} 個');
      }
    } catch (e) {
      debugPrint('載入隱藏活動列表失敗: $e');
    }
  }

  /// 保存隱藏的活動列表
  Future<void> _saveHiddenActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        await prefs.setStringList('hidden_activities_${currentUser.uid}', _hiddenActivities.toList());
        debugPrint('保存隱藏活動列表: ${_hiddenActivities.length} 個');
      }
    } catch (e) {
      debugPrint('保存隱藏活動列表失敗: $e');
    }
  }

  /// 隱藏活動
  Future<void> _hideActivity(String activityId, String activityTitle) async {
    setState(() {
      _hiddenActivities.add(activityId);
    });
    
    await _saveHiddenActivities();
    
    // 重新應用篩選以移除隱藏的活動
    _applyFilters();
    
    // 顯示成功提示
    CustomSnackBarBuilder.success(
      context,
      '已刪除「$activityTitle」',
      duration: const Duration(seconds: 2),
    );
  }

  /// 檢查被取消的活動通知
  Future<void> _checkCancelledActivityNotifications(String userId) async {
    try {
      debugPrint('=== 檢查被取消活動通知 ===');
      
      final cancelledActivities = await _activityService.getNewCancelledActivitiesForUser(
        userId: userId,
      );

      if (cancelledActivities.isEmpty) {
        debugPrint('沒有新的被取消活動通知');
        return;
      }

      debugPrint('發現 ${cancelledActivities.length} 個新的被取消活動通知');

      if (!mounted) return;

      // 延遲一下確保頁面已經完全載入
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // 逐個顯示取消通知（使用底部彈窗）
      _showCancelledNotificationsSequentially(cancelledActivities, 0);

    } catch (e) {
      debugPrint('檢查被取消活動通知失敗: $e');
    }
  }


  /// 逐個顯示取消通知（使用底部彈窗）
  void _showCancelledNotificationsSequentially(List<Map<String, dynamic>> activities, int currentIndex) {
    if (currentIndex >= activities.length || !mounted) {
      // 所有通知都已顯示完畢，重新載入活動數據
      _loadActivities();
      return;
    }

    final activity = activities[currentIndex];
    final activityTitle = activity['activityTitle'] as String;
    final registrationId = activity['registrationId'] as String;

    SuccessPopupBuilder.activityCancelledBottom(
      context,
      activityTitle: activityTitle,
      onConfirm: () async {
        Navigator.of(context).pop();
        
        // 標記當前活動為已通知
        try {
          await _activityService.markCancelledActivitiesAsNotified(
            registrationIds: [registrationId],
          );
          debugPrint('活動 $activityTitle 已標記為已通知');
        } catch (e) {
          debugPrint('標記通知為已讀失敗: $e');
        }
        
        // 延遲一下後顯示下一個通知
        await Future.delayed(const Duration(milliseconds: 300));
        
        if (mounted) {
          _showCancelledNotificationsSequentially(activities, currentIndex + 1);
        }
      },
    );
  }

  /// 獲取實際的報名狀態（考慮活動是否已結束）
  ActivityStatus? _getActualRegistrationStatus(
    Map<String, dynamic> registration, 
    Map<String, dynamic> activity
  ) {
    final registrationStatus = registration['status'] as String? ?? 'registered';
    final activityStatus = activity['status'] as String?;
    final activityType = activity['type'] as String? ?? 'event';
    final endDateTime = activity['endDateTime'] as String?;
    
    // 如果報名狀態已經是 ended 或 cancelled，直接返回
    if (registrationStatus == 'ended') {
      return ActivityStatus.ended;
    }
    if (registrationStatus == 'cancelled') {
      return ActivityStatus.cancelled;
    }
    
    // 檢查活動是否已結束
    bool isActivityEnded = false;
    
    // 1. 檢查活動狀態是否為 ended
    if (activityStatus == 'ended') {
      isActivityEnded = true;
    }
    
    // 2. 檢查是否超過活動結束時間
    if (!isActivityEnded && endDateTime != null) {
      try {
        final endTime = DateTime.parse(endDateTime);
        final now = DateTime.now();
        isActivityEnded = now.isAfter(endTime);
      } catch (e) {
        debugPrint('解析活動結束時間失敗: $e');
      }
    }
    
    // 如果活動已結束，但報名狀態還是 registered，則顯示為已結束
    if (isActivityEnded && registrationStatus == 'registered') {
      return ActivityStatus.ended;
    }
    
    // 否則使用原始的狀態判斷邏輯
    return ActivityStatusUtils.fromString(registrationStatus, activityType);
  }

  /// 應用篩選
  void _applyFilters() {
    // 篩選報名活動
    _filteredRegisteredActivities = _registeredActivities.where((activityData) {
      final registration = activityData['registration'] as Map<String, dynamic>;
      final activity = activityData['activity'] as Map<String, dynamic>;
      final activityId = activity['id'] as String?;
      
      // 過濾隱藏的活動
      if (activityId != null && _hiddenActivities.contains(activityId)) {
        return false;
      }
      
      // 狀態篩選
      if (_selectedRegisteredStatus != null) {
        final actualStatus = _getActualRegistrationStatus(registration, activity);
        
        if (actualStatus?.name != _selectedRegisteredStatus) {
          return false;
        }
      }
      
      // 類別篩選
      if (_selectedCategory != null) {
        final category = activity['category'] as String?;
        if (category != _selectedCategory) {
          return false;
        }
      }
      
      return true;
    }).toList();

    // 排序報名活動：已取消和已結束排在最後
    _filteredRegisteredActivities.sort((a, b) {
      final registrationA = a['registration'] as Map<String, dynamic>;
      final activityA = a['activity'] as Map<String, dynamic>;
      final statusA = _getActualRegistrationStatus(registrationA, activityA);
      
      final registrationB = b['registration'] as Map<String, dynamic>;
      final activityB = b['activity'] as Map<String, dynamic>;
      final statusB = _getActualRegistrationStatus(registrationB, activityB);
      
      // 檢查是否為已取消或已結束狀態
      final isInactiveA = statusA == ActivityStatus.cancelled || statusA == ActivityStatus.ended;
      final isInactiveB = statusB == ActivityStatus.cancelled || statusB == ActivityStatus.ended;
      
      // 如果一個是非活躍狀態，另一個是活躍狀態，非活躍的排在後面
      if (isInactiveA && !isInactiveB) return 1;
      if (!isInactiveA && isInactiveB) return -1;
      
      // 如果都是活躍或都是非活躍，保持原順序
      return 0;
    });

    // 篩選發布活動
    _filteredPublishedActivities = _publishedActivities.where((activityData) {
      final activityId = activityData['id'] as String?;
      
      // 過濾隱藏的活動
      if (activityId != null && _hiddenActivities.contains(activityId)) {
        return false;
      }
      
      // 狀態篩選
      if (_selectedPublishedStatus != null) {
        final statusString = activityData['displayStatus'] as String? ?? 'published';
        final activityType = activityData['type'] as String? ?? 'event';
        final draftReason = activityData['draftReason'] as String?;
        final status = ActivityStatusUtils.fromString(statusString, activityType, draftReason: draftReason);
        
        if (status?.name != _selectedPublishedStatus) {
          return false;
        }
      }
      
      // 類別篩選
      if (_selectedCategory != null) {
        final category = activityData['category'] as String?;
        if (category != _selectedCategory) {
          return false;
        }
      }
      
      return true;
    }).toList();

    // 排序發布活動：已取消和已結束排在最後
    _filteredPublishedActivities.sort((a, b) {
      final statusStringA = a['displayStatus'] as String? ?? 'published';
      final activityTypeA = a['type'] as String? ?? 'event';
      final draftReasonA = a['draftReason'] as String?;
      final statusA = ActivityStatusUtils.fromString(statusStringA, activityTypeA, draftReason: draftReasonA);
      
      final statusStringB = b['displayStatus'] as String? ?? 'published';
      final activityTypeB = b['type'] as String? ?? 'event';
      final draftReasonB = b['draftReason'] as String?;
      final statusB = ActivityStatusUtils.fromString(statusStringB, activityTypeB, draftReason: draftReasonB);
      
      // 檢查是否為已取消或已結束狀態
      final isInactiveA = statusA == ActivityStatus.cancelled || statusA == ActivityStatus.ended;
      final isInactiveB = statusB == ActivityStatus.cancelled || statusB == ActivityStatus.ended;
      
      // 如果一個是非活躍狀態，另一個是活躍狀態，非活躍的排在後面
      if (isInactiveA && !isInactiveB) return 1;
      if (!isInactiveA && isInactiveB) return -1;
      
      // 如果都是活躍或都是非活躍，保持原順序
      return 0;
    });
    
    if (mounted) {
      setState(() {});
    }
  }

  /// 重置篩選
  void _resetFilters() {
    if (!mounted) return;
    setState(() {
      _selectedRegisteredStatus = null;
      _selectedPublishedStatus = null;
      _selectedCategory = null;
    });
    _applyFilters();
  }

  /// 獲取狀態篩選選項（報名活動）
  List<DropdownItem<String>> _getRegisteredStatusOptions() {
    return ActivityStatusUtils.getRegisteredActivityStatuses()
        .map((status) => DropdownItem(
              value: status.name,
              label: status.displayName,
            ))
        .toList();
  }

  /// 獲取狀態篩選選項（發布活動）
  List<DropdownItem<String>> _getPublishedStatusOptions() {
    return ActivityStatusUtils.getPublishedActivityStatuses()
        .map((status) => DropdownItem(
              value: status.name,
              label: status.displayName,
            ))
        .toList();
  }

  /// 獲取類別篩選選項
  List<DropdownItem<String>> _getCategoryOptions() {
    if (_isLoadingCategories || _allCategories.isEmpty) {
      // 載入中或沒有分類時，返回預設選項
      return const [
        DropdownItem(value: 'EventCategory_language_teaching', label: '活動 - 語言教學'),
        DropdownItem(value: 'EventCategory_skill_experience', label: '活動 - 技能體驗'),
        DropdownItem(value: 'EventCategory_event_support', label: '活動 - 活動支援'),
        DropdownItem(value: 'EventCategory_life_service', label: '活動 - 生活服務'),
        DropdownItem(value: 'TaskCategory_event_support', label: '任務 - 活動支援'),
        DropdownItem(value: 'TaskCategory_life_service', label: '任務 - 生活服務'),
        DropdownItem(value: 'TaskCategory_skill_sharing', label: '任務 - 技能分享'),
        DropdownItem(value: 'TaskCategory_creative_work', label: '任務 - 創意工作'),
      ];
    }

    // 使用動態載入的分類
    return _allCategories.map((category) {
      final typeLabel = category.type == 'event' ? '活動' : '任務';
      return DropdownItem(
        value: category.name,
        label: '$typeLabel - ${category.displayName}',
      );
    }).toList();
  }

  /// 處理活動卡片點擊
  void _onActivityTap(Map<String, dynamic> activityData, bool isRegistered) {
    // 獲取活動ID和數據
    String? activityId;
    Map<String, dynamic>? activity;
    
    if (isRegistered) {
      // 報名的活動：從 registration 數據中獲取
      activityId = activityData['activity']?['id'] as String?;
      activity = activityData['activity'] as Map<String, dynamic>?;
    } else {
      // 發布的活動：直接從活動數據獲取
      activityId = activityData['id'] as String?;
      activity = activityData;
    }
    
    if (activityId != null) {
      debugPrint('導航到活動詳情: $activityId');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ActivityDetailPage(
            activityId: activityId!,
            activityData: activity,
          ),
        ),
      );
    } else {
      debugPrint('無法獲取活動ID: $activityData');
      CustomSnackBar.showError(
        context,
        message: '無法打開活動詳情',
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Column(
          children: [
          // 分頁導航
          Container(
            padding: const EdgeInsets.only(top: 20),
            color: AppColors.backgroundPrimary,
            child: Column(
              children: [
                // 標題列和重新整理按鈕
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  child: Row(
                    children: [
                      const Text(
                        '我的活動',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 24),

                // 分頁標籤
                TabBar(
                  controller: _tabController,
                  splashFactory: NoSplash.splashFactory,
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  padding: EdgeInsets.zero,
                  labelPadding: EdgeInsets.zero,
                  dividerColor: AppColors.grey100,
                  indicator: UnderlineTabIndicator(
                    borderSide: BorderSide(
                      color: AppColors.black,
                      width: 2.0,
                    ),
                    insets: EdgeInsets.zero,
                  ),
                  labelColor: AppColors.black,
                  unselectedLabelColor: AppColors.grey500,
                  labelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                  ),
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_available, size: 18),
                          SizedBox(width: 8),
                          Text('我報名的'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.publish, size: 18),
                          SizedBox(width: 8),
                          Text('我發布的'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          // 篩選區域
          _buildFilterSection(),

          // 分頁內容
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 我報名的活動
                _buildRegisteredActivitiesTab(),
                // 我發布的活動
                _buildPublishedActivitiesTab(),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  /// 建立篩選區域
  Widget _buildFilterSection() {
    return Container(
      color: AppColors.backgroundPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: Row(
        children: [
          // 左側狀態篩選
          Expanded(
            child: _buildStatusDropdown(),
          ),
          
          const SizedBox(width: 12),
          
          // 右側類別篩選
          Expanded(
            child: _buildCategoryDropdown(),
          ),
        ],
      ),
    );
  }

  /// 建立狀態下拉選單
  Widget _buildStatusDropdown() {
    final isRegisteredTab = _tabController.index == 0;
    final currentValue = isRegisteredTab ? _selectedRegisteredStatus : _selectedPublishedStatus;
    final statusOptions = isRegisteredTab 
        ? _getRegisteredStatusOptions() 
        : _getPublishedStatusOptions();

    return CustomDropdown<String>(
      label: '', // 無標籤
      showAsDialog: true,
      dialogTitle: '選擇狀態',
      items: [
        const DropdownItem(value: 'all', label: '全部'),
        ...statusOptions,
      ],
      value: currentValue ?? 'all',
      onChanged: (value) {
        if (!mounted) return;
        setState(() {
          if (isRegisteredTab) {
            _selectedRegisteredStatus = value == 'all' ? null : value;
          } else {
            _selectedPublishedStatus = value == 'all' ? null : value;
          }
        });
        _applyFilters();
      },
    );
  }

  /// 建立類別下拉選單
  Widget _buildCategoryDropdown() {
    return CustomDropdown<String>(
      label: '', // 無標籤
      showAsDialog: true,
      dialogTitle: '選擇類別',
      items: [
        const DropdownItem(value: 'all', label: '全部類別'),
        ..._getCategoryOptions(),
      ],
      value: _selectedCategory ?? 'all',
      onChanged: (value) {
        if (!mounted) return;
        setState(() {
          _selectedCategory = value == 'all' ? null : value;
        });
        _applyFilters();
      },
    );
  }

  /// 建立我報名的活動分頁
  Widget _buildRegisteredActivitiesTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary900,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error900,
            ),
            const SizedBox(height: 16),
            Text(
              '載入失敗',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshActivities,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary900,
                foregroundColor: AppColors.black,
              ),
              child: const Text('重試'),
            ),
          ],
        ),
      );
    }

    if (_filteredRegisteredActivities.isEmpty) {
      final hasFilters = _selectedRegisteredStatus != null || _selectedCategory != null;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilters ? Icons.search_off : Icons.event_busy,
              size: 64,
              color: AppColors.grey500,
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters ? '沒有符合條件的活動' : '尚未報名任何活動',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters ? '試試調整篩選條件' : '快去首頁探索有趣的活動吧！',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            if (hasFilters) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _resetFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary900,
                  foregroundColor: AppColors.black,
                ),
                child: const Text('清除篩選'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshActivities,
      color: AppColors.primary900, 
      child: ListView.separated(
        padding: const EdgeInsets.only(top: 0, left: 0, right: 0, bottom: 90),
        itemCount: _filteredRegisteredActivities.length,
        separatorBuilder: (context, index) => Column(
          children: [
            const SizedBox(height: 24),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 1,
              color: AppColors.grey100,
            ),
            const SizedBox(height: 24),
          ],
        ),
        itemBuilder: (context, index) {
          final activityData = _filteredRegisteredActivities[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: MyActivityCardBuilder.fromRegistration(
              registrationData: activityData,
              onTap: () => _onActivityTap(activityData, true),
              onHide: () => _handleRegisteredActivityHidden(activityData, index),
            ),
          );
        },
      ),
    );
  }

  /// 建立我發布的活動分頁
  Widget _buildPublishedActivitiesTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary900,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error900,
            ),
            const SizedBox(height: 16),
            const Text(
              '載入失敗',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshActivities,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary900,
                foregroundColor: AppColors.black,
              ),
              child: const Text('重試'),
            ),
          ],
        ),
      );
    }

    if (_filteredPublishedActivities.isEmpty) {
      final hasFilters = _selectedPublishedStatus != null || _selectedCategory != null;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilters ? Icons.search_off : Icons.add_circle_outline,
              size: 64,
              color: AppColors.grey500,
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters ? '沒有符合條件的活動' : '尚未發布任何活動',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters ? '試試調整篩選條件' : '點擊右下角的加號開始發布活動',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            if (hasFilters) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _resetFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary900,
                  foregroundColor: AppColors.black,
                ),
                child: const Text('清除篩選'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshActivities,
      color: AppColors.primary900,
      child: ListView.separated(
        padding: const EdgeInsets.only(top: 0, left: 0, right: 0, bottom: 90),
        itemCount: _filteredPublishedActivities.length,
        separatorBuilder: (context, index) => Column(
          children: [
            const SizedBox(height: 24),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 1,
              color: AppColors.grey100,
            ),
            const SizedBox(height: 24),
          ],
        ),
        itemBuilder: (context, index) {
          final activityData = _filteredPublishedActivities[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: MyActivityCardBuilder.fromPublishedActivity(
              activityData: activityData,
              onTap: () => _onActivityTap(activityData, false),
              onHide: () => _handlePublishedActivityHidden(activityData, index),
            ),
          );
        },
      ),
    );
  }

  /// 處理報名活動的長按隱藏
  void _handleRegisteredActivityHidden(Map<String, dynamic> activityData, int index) {
    debugPrint('=== 處理報名活動長按隱藏 ===');
    
    final activity = activityData['activity'] as Map<String, dynamic>;
    final activityTitle = activity['name'] as String? ?? '未知活動';
    final activityId = activity['id'] as String? ?? '';
    
    if (activityId.isNotEmpty) {
      _hideActivity(activityId, activityTitle);
    }
  }

  /// 處理發布活動的長按隱藏
  void _handlePublishedActivityHidden(Map<String, dynamic> activityData, int index) {
    debugPrint('=== 處理發布活動長按隱藏 ===');
    
    final activityTitle = activityData['name'] as String? ?? '未知活動';
    final activityId = activityData['id'] as String? ?? '';
    
    if (activityId.isNotEmpty) {
      _hideActivity(activityId, activityTitle);
    }
  }
}
