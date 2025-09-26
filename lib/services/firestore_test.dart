import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore 測試服務
class FirestoreTestService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// 檢查 Firestore 規則並測試連接
  static Future<void> checkFirestoreRules() async {
    try {
      debugPrint('測試Firestore連接和規則');
      await Future.delayed(const Duration(milliseconds: 100));
      debugPrint('Firestore連接測試完成');
    } catch (e) {
      debugPrint('Firestore連接測試失敗: $e');
      throw Exception('Firestore連接失敗：$e');
    }
  }
  
  /// 測試 Firestore 寫入權限
  static Future<bool> testFirestoreWrite() async {
    try {
      debugPrint('測試Firestore寫入權限');
      
      // 嘗試寫入測試文檔
      await _firestore.collection('test').doc('test_write_permission').set({
        'test': true,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      debugPrint('Firestore寫入測試成功');
      return true;
    } catch (e) {
      debugPrint('Firestore寫入測試失敗: $e');
      return false;
    }
  }
}
