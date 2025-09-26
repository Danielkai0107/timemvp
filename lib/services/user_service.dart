import 'package:flutter/foundation.dart';

/// 模擬的文檔類別
class MockDocumentSnapshot {
  final Map<String, dynamic>? _data;
  final bool _exists;
  
  MockDocumentSnapshot({Map<String, dynamic>? data, bool exists = true}) 
    : _data = data, _exists = exists;
  
  bool get exists => _exists;
  Map<String, dynamic>? data() => _data;
}

/// 模擬的用戶服務
class UserService {
  // 模擬資料庫
  static final Map<String, Map<String, dynamic>> _mockDatabase = {};
  
  /// 創建用戶文檔 (模擬)
  Future<void> createUserDocument({
    required String uid,
    required String email,
    required Map<String, dynamic> userData,
  }) async {
    debugPrint('模擬創建用戶文檔: $uid');
    debugPrint('用戶資料: $userData');
    
    // 模擬網路延遲
    await Future.delayed(const Duration(seconds: 1));
    
    // 將資料存入模擬資料庫
    _mockDatabase[uid] = {
      'email': email,
      ...userData,
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    debugPrint('模擬用戶文檔創建成功');
  }
  
  /// 取得用戶文檔 (模擬)
  Future<MockDocumentSnapshot> getUserDocument(String uid) async {
    debugPrint('模擬取得用戶文檔: $uid');
    
    // 模擬網路延遲
    await Future.delayed(const Duration(milliseconds: 500));
    
    final userData = _mockDatabase[uid];
    if (userData != null) {
      debugPrint('模擬用戶文檔找到');
      return MockDocumentSnapshot(data: userData, exists: true);
    } else {
      debugPrint('模擬用戶文檔不存在');
      return MockDocumentSnapshot(exists: false);
    }
  }
  
  /// 上傳檔案 (模擬)
  Future<List<String>> uploadFiles({
    required List<String> filePaths,
    required String folderName,
    required String uid,
  }) async {
    debugPrint('模擬上傳檔案: $folderName, 檔案數量: ${filePaths.length}');
    
    // 模擬上傳延遲
    await Future.delayed(const Duration(seconds: 2));
    
    // 產生模擬的檔案 URLs
    final urls = filePaths.asMap().entries.map((entry) {
      final index = entry.key;
      final filePath = entry.value;
      final fileName = filePath.split('/').last;
      return 'https://mock-storage.example.com/$uid/$folderName/${index}_$fileName';
    }).toList();
    
    debugPrint('模擬檔案上傳成功，URLs: $urls');
    return urls;
  }
}

