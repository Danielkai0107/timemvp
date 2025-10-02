import 'package:flutter/material.dart';
import '../components/design_system/app_colors.dart';
import '../components/design_system/custom_dropdown.dart';
import '../components/design_system/activity_status_badge.dart';
import '../components/design_system/custom_snackbar.dart';
import '../components/my_activity_card.dart';
import '../services/activity_service.dart';
import '../services/auth_service.dart';
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
    
    _loadActivities();
  }

  @override
  void dispose() {
    // 從全域控制器註銷
    MyActivitiesPageController._unregister();
    _tabController.dispose();
    super.dispose();
  }

  /// 載入活動數據
  Future<void> _loadActivities() async {
    if (_isLoading) return;
    
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

      setState(() {
        _registeredActivities = results[0];
        _publishedActivities = results[1];
        _isLoading = false;
      });
      
      debugPrint('狀態更新完成，開始應用篩選...');
      
      // 應用篩選
      _applyFilters();
      
      debugPrint('=== 活動數據載入完成 ===');
    } catch (e) {
      debugPrint('=== 載入活動數據失敗 ===');
      debugPrint('錯誤: $e');
      
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

  /// 應用篩選
  void _applyFilters() {
    // 篩選報名活動
    _filteredRegisteredActivities = _registeredActivities.where((activityData) {
      final registration = activityData['registration'] as Map<String, dynamic>;
      final activity = activityData['activity'] as Map<String, dynamic>;
      
      // 狀態篩選
      if (_selectedRegisteredStatus != null) {
        final statusString = registration['status'] as String? ?? 'registered';
        final activityType = activity['type'] as String? ?? 'event';
        final status = ActivityStatusUtils.fromString(statusString, activityType);
        
        if (status?.name != _selectedRegisteredStatus) {
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
      final statusStringA = registrationA['status'] as String? ?? 'registered';
      final activityTypeA = activityA['type'] as String? ?? 'event';
      final statusA = ActivityStatusUtils.fromString(statusStringA, activityTypeA);
      
      final registrationB = b['registration'] as Map<String, dynamic>;
      final activityB = b['activity'] as Map<String, dynamic>;
      final statusStringB = registrationB['status'] as String? ?? 'registered';
      final activityTypeB = activityB['type'] as String? ?? 'event';
      final statusB = ActivityStatusUtils.fromString(statusStringB, activityTypeB);
      
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
    
    setState(() {});
  }

  /// 重置篩選
  void _resetFilters() {
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
    return const [
      DropdownItem(value: 'EventCategory_language_teaching', label: '語言教學'),
      DropdownItem(value: 'EventCategory_skill_experience', label: '技能體驗'),
      DropdownItem(value: 'EventCategory_event_support', label: '活動支援'),
      DropdownItem(value: 'EventCategory_life_service', label: '生活服務'),
    ];
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
            ),
          );
        },
      ),
    );
  }
}
