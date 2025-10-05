import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// 分類數據模型
class Category {
  final String id;
  final String name;
  final String displayName;
  final String type; // 'event' 或 'task'
  final int sortOrder;
  final bool isActive;

  const Category({
    required this.id,
    required this.name,
    required this.displayName,
    required this.type,
    required this.sortOrder,
    required this.isActive,
  });

  factory Category.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Category(
      id: doc.id,
      name: data['name'] ?? doc.id, // 如果沒有 name 欄位，使用文檔 ID
      displayName: data['displayName'] ?? '',
      type: data['type'] ?? 'event',
      sortOrder: data['sortOrder'] ?? 0,
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'displayName': displayName,
      'type': type,
      'sortOrder': sortOrder,
      'isActive': isActive,
    };
  }
}

/// 分類服務類
/// 處理分類相關的 Firebase 操作
class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // 緩存分類數據
  List<Category>? _cachedCategories;
  DateTime? _lastFetchTime;
  static const Duration _cacheExpiry = Duration(minutes: 30);

  /// 獲取所有活躍的分類（優先使用 Firebase 數據）
  Future<List<Category>> getAllCategories({bool forceRefresh = false}) async {
    try {
      // 檢查緩存是否有效
      if (!forceRefresh && 
          _cachedCategories != null && 
          _lastFetchTime != null &&
          DateTime.now().difference(_lastFetchTime!) < _cacheExpiry) {
        debugPrint('使用緩存的分類數據');
        return _cachedCategories!;
      }

      debugPrint('從 Firestore 獲取分類數據');
      
      final querySnapshot = await _firestore
          .collection('categories')
          .orderBy('sortOrder')
          .get();

      final categories = querySnapshot.docs
          .map((doc) => Category.fromFirestore(doc))
          .toList();

      // 更新緩存
      _cachedCategories = categories;
      _lastFetchTime = DateTime.now();

      debugPrint('獲取到 ${categories.length} 個分類');
      return categories;
    } catch (e) {
      debugPrint('獲取分類失敗: $e');
      
      // 如果有緩存數據，返回緩存數據
      if (_cachedCategories != null) {
        debugPrint('使用緩存的分類數據作為備用');
        return _cachedCategories!;
      }
      
      // 重新拋出異常，讓調用方決定如何處理
      // 不再自動回退到預設分類，確保 Firebase 數據的優先級
      throw Exception('無法從 Firebase 獲取分類數據，且沒有可用的緩存數據: $e');
    }
  }

  /// 根據類型獲取分類
  Future<List<Category>> getCategoriesByType(String type, {bool forceRefresh = false}) async {
    final allCategories = await getAllCategories(forceRefresh: forceRefresh);
    return allCategories.where((category) => category.type == type).toList();
  }

  /// 獲取活動類型的分類
  Future<List<Category>> getEventCategories({bool forceRefresh = false}) async {
    return getCategoriesByType('event', forceRefresh: forceRefresh);
  }

  /// 獲取任務類型的分類
  Future<List<Category>> getTaskCategories({bool forceRefresh = false}) async {
    return getCategoriesByType('task', forceRefresh: forceRefresh);
  }

  /// 獲取分類（如果 Firebase 失敗則使用預設分類）
  /// 這個方法只應該在初始化或緊急情況下使用
  Future<List<Category>> getCategoriesWithFallback({bool forceRefresh = false}) async {
    try {
      return await getAllCategories(forceRefresh: forceRefresh);
    } catch (e) {
      debugPrint('Firebase 分類獲取失敗，使用預設分類作為備用: $e');
      return _getDefaultCategories();
    }
  }

  /// 根據類型獲取分類（如果 Firebase 失敗則使用預設分類）
  Future<List<Category>> getCategoriesByTypeWithFallback(String type, {bool forceRefresh = false}) async {
    try {
      return await getCategoriesByType(type, forceRefresh: forceRefresh);
    } catch (e) {
      debugPrint('Firebase 分類獲取失敗，使用預設分類作為備用: $e');
      final defaultCategories = _getDefaultCategories();
      return defaultCategories.where((category) => category.type == type).toList();
    }
  }

  /// 根據 ID 獲取分類
  Future<Category?> getCategoryById(String categoryId) async {
    try {
      final allCategories = await getAllCategories();
      return allCategories.firstWhere(
        (category) => category.id == categoryId,
        orElse: () => throw StateError('Category not found'),
      );
    } catch (e) {
      debugPrint('根據 ID 獲取分類失敗: $e');
      return null;
    }
  }

  /// 根據 name 獲取分類
  Future<Category?> getCategoryByName(String categoryName) async {
    try {
      final allCategories = await getAllCategories();
      return allCategories.firstWhere(
        (category) => category.name == categoryName,
        orElse: () => throw StateError('Category not found'),
      );
    } catch (e) {
      debugPrint('根據 name 獲取分類失敗: $e');
      return null;
    }
  }

  /// 獲取分類的顯示名稱
  Future<String> getCategoryDisplayName(String categoryName) async {
    try {
      final category = await getCategoryByName(categoryName);
      return category?.displayName ?? categoryName;
    } catch (e) {
      debugPrint('獲取分類顯示名稱失敗: $e');
      return categoryName;
    }
  }

  /// 清除緩存
  void clearCache() {
    _cachedCategories = null;
    _lastFetchTime = null;
    debugPrint('分類緩存已清除');
  }

  /// 強制從 Firebase 重新載入分類數據
  Future<List<Category>> forceRefreshFromFirebase() async {
    debugPrint('強制從 Firebase 重新載入分類數據...');
    clearCache();
    return await getAllCategories(forceRefresh: true);
  }

  /// 檢查是否有可用的 Firebase 連接
  Future<bool> checkFirebaseConnection() async {
    try {
      await _firestore
          .collection('categories')
          .limit(1)
          .get();
      return true;
    } catch (e) {
      debugPrint('Firebase 連接檢查失敗: $e');
      return false;
    }
  }

  /// 測試方法：直接從 Firebase 獲取原始數據
  Future<void> testFirebaseData() async {
    try {
      debugPrint('=== 測試 Firebase 分類數據 ===');
      
      final querySnapshot = await _firestore
          .collection('categories')
          .get();
      
      debugPrint('找到 ${querySnapshot.docs.length} 個文檔');
      
      for (final doc in querySnapshot.docs) {
        debugPrint('文檔 ID: ${doc.id}');
        debugPrint('文檔數據: ${doc.data()}');
        debugPrint('---');
      }
    } catch (e) {
      debugPrint('測試 Firebase 數據失敗: $e');
    }
  }

  /// 預設分類數據（作為備用）
  List<Category> _getDefaultCategories() {
    return [
      // 活動類型分類
      const Category(
        id: 'EventCategory_language_teaching',
        name: 'EventCategory_language_teaching',
        displayName: '語言教學',
        type: 'event',
        sortOrder: 1,
        isActive: true,
      ),
      const Category(
        id: 'EventCategory_skill_experience',
        name: 'EventCategory_skill_experience',
        displayName: '技能體驗',
        type: 'event',
        sortOrder: 2,
        isActive: true,
      ),
      const Category(
        id: 'EventCategory_event_support',
        name: 'EventCategory_event_support',
        displayName: '活動支援',
        type: 'event',
        sortOrder: 3,
        isActive: true,
      ),
      const Category(
        id: 'EventCategory_life_service',
        name: 'EventCategory_life_service',
        displayName: '生活服務',
        type: 'event',
        sortOrder: 4,
        isActive: true,
      ),
      
      // 任務類型分類
      const Category(
        id: 'TaskCategory_event_support',
        name: 'TaskCategory_event_support',
        displayName: '活動支援',
        type: 'task',
        sortOrder: 1,
        isActive: true,
      ),
      const Category(
        id: 'TaskCategory_life_service',
        name: 'TaskCategory_life_service',
        displayName: '生活服務',
        type: 'task',
        sortOrder: 2,
        isActive: true,
      ),
      const Category(
        id: 'TaskCategory_skill_sharing',
        name: 'TaskCategory_skill_sharing',
        displayName: '技能分享',
        type: 'task',
        sortOrder: 3,
        isActive: true,
      ),
      const Category(
        id: 'TaskCategory_creative_work',
        name: 'TaskCategory_creative_work',
        displayName: '創意工作',
        type: 'task',
        sortOrder: 4,
        isActive: true,
      ),
    ];
  }

  /// 初始化分類數據到 Firestore（僅用於開發/測試）
  Future<void> initializeDefaultCategories() async {
    try {
      debugPrint('開始初始化預設分類數據...');
      
      final defaultCategories = _getDefaultCategories();
      final batch = _firestore.batch();
      
      for (final category in defaultCategories) {
        final docRef = _firestore.collection('categories').doc(category.id);
        batch.set(docRef, category.toMap());
      }
      
      await batch.commit();
      
      // 清除緩存以強制重新載入
      clearCache();
      
      debugPrint('預設分類數據初始化完成');
    } catch (e) {
      debugPrint('初始化預設分類數據失敗: $e');
      throw Exception('初始化分類數據失敗: $e');
    }
  }
}
