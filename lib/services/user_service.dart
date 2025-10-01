import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

/// 用戶服務，負責與Firestore和Firebase Storage進行交互
class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  /// 創建用戶文檔到Firestore
  Future<void> createUserDocument({
    required String uid,
    required String email,
    required Map<String, dynamic> userData,
  }) async {
    try {
      debugPrint('創建Firestore用戶文檔: $uid');
      debugPrint('用戶資料: $userData');
      
      // 準備文檔資料
      final data = {
        'email': email,
        ...userData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      await _firestore.collection('users').doc(uid).set(data);
      
      debugPrint('Firestore用戶文檔創建成功');
    } catch (e) {
      debugPrint('創建用戶文檔時發生錯誤: $e');
      throw Exception('創建用戶文檔失敗：$e');
    }
  }
  
  /// 取得用戶文檔
  Future<DocumentSnapshot> getUserDocument(String uid) async {
    try {
      debugPrint('從Firestore取得用戶文檔: $uid');
      
      final doc = await _firestore.collection('users').doc(uid).get();
      
      if (doc.exists) {
        debugPrint('Firestore用戶文檔找到');
      } else {
        debugPrint('Firestore用戶文檔不存在');
      }
      
      return doc;
    } catch (e) {
      debugPrint('取得用戶文檔時發生錯誤: $e');
      throw Exception('取得用戶文檔失敗：$e');
    }
  }

  /// 獲取用戶基本資料（用於活動發布）
  Future<Map<String, dynamic>> getUserBasicInfo(String uid) async {
    try {
      debugPrint('獲取用戶基本資料: $uid');
      
      final doc = await _firestore.collection('users').doc(uid).get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': uid,
          'name': data['name'] ?? data['fullName'] ?? '用戶',
          'email': data['email'],
          'phone': data['phone'],
          'avatar': data['avatar'] ?? data['profileImage'],
          'status': 'approved',
          'rating': '0.00',
        };
      } else {
        // 如果用戶文檔不存在，返回基本資料
        debugPrint('用戶文檔不存在，使用預設資料');
        return {
          'id': uid,
          'name': '用戶',
          'email': null,
          'phone': null,
          'avatar': null,
          'status': 'approved',
          'rating': '0.00',
        };
      }
    } catch (e) {
      debugPrint('獲取用戶基本資料失敗: $e');
      // 發生錯誤時返回預設資料
      return {
        'id': uid,
        'name': '用戶',
        'email': null,
        'phone': null,
        'avatar': null,
        'status': 'approved',
        'rating': '0.00',
      };
    }
  }
  
  /// 上傳檔案到Firebase Storage
  Future<List<String>> uploadFiles({
    required List<String> filePaths,
    required String folderName,
    required String uid,
  }) async {
    try {
      debugPrint('Firebase Storage上傳檔案: $folderName, 檔案數量: ${filePaths.length}');
      
      final List<String> downloadUrls = [];
      
      for (int i = 0; i < filePaths.length; i++) {
        final filePath = filePaths[i];
        final fileName = filePath.split('/').last;
        final storagePath = 'users/$uid/$folderName/${i}_$fileName';
        
        // 創建參考
        final ref = _storage.ref().child(storagePath);
        final file = File(filePath);
        
        // 上傳檔案
        final uploadTask = ref.putFile(file);
        
        // 等待上傳完成
        await uploadTask;
        
        // 獲取下載URL
        final downloadUrl = await ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
        
        debugPrint('檔案上傳完成: $storagePath -> $downloadUrl');
      }
      
      debugPrint('Firebase Storage檔案上傳成功，URLs數量: ${downloadUrls.length}');
      return downloadUrls;
    } catch (e) {
      debugPrint('上傳檔案時發生錯誤: $e');
      throw Exception('上傳檔案失敗：$e');
    }
  }

  /// 創建用戶（新的統一方法）
  Future<void> createUser(String uid, Map<String, dynamic> userData) async {
    try {
      debugPrint('創建用戶: $uid');
      
      final data = {
        ...userData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      await _firestore.collection('users').doc(uid).set(data);
      debugPrint('用戶創建成功');
    } catch (e) {
      debugPrint('創建用戶時發生錯誤: $e');
      throw Exception('創建用戶失敗：$e');
    }
  }

  /// 更新用戶 KYC 資料
  Future<void> updateUserKyc(String uid, Map<String, dynamic> kycData) async {
    try {
      debugPrint('更新用戶 KYC 資料: $uid');
      
      await _firestore.collection('users').doc(uid).update({
        'kyc': kycData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('KYC 資料更新成功');
    } catch (e) {
      debugPrint('更新 KYC 資料時發生錯誤: $e');
      throw Exception('更新 KYC 資料失敗：$e');
    }
  }

  /// 取得用戶 KYC 狀態
  Future<String?> getUserKycStatus(String uid) async {
    try {
      final doc = await getUserDocument(uid);
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        return data?['kyc']?['kycStatus'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('取得 KYC 狀態時發生錯誤: $e');
      return null;
    }
  }
}

