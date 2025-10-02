import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'activity_service.dart';

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

  /// 更新用戶資料
  Future<void> updateUserData(String uid, Map<String, dynamic> updateData) async {
    try {
      debugPrint('更新用戶資料: $uid');
      debugPrint('更新資料: $updateData');
      
      final data = {
        ...updateData,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      await _firestore.collection('users').doc(uid).update(data);
      debugPrint('用戶資料更新成功');
    } catch (e) {
      debugPrint('更新用戶資料時發生錯誤: $e');
      throw Exception('更新用戶資料失敗：$e');
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
      
      // 如果 KYC 狀態變為 approved，自動上架待審核的草稿活動
      final kycStatus = kycData['kycStatus'] as String?;
      if (kycStatus == 'approved') {
        try {
          final activityService = ActivityService();
          await activityService.autoPublishKycPendingDrafts(uid);
          debugPrint('自動上架 KYC 待審核草稿活動完成');
        } catch (e) {
          debugPrint('自動上架草稿活動失敗: $e');
          // 不拋出異常，避免影響 KYC 狀態更新
        }
      }
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

  /// 取得用戶帳號類型
  Future<String?> getUserAccountType(String uid) async {
    try {
      debugPrint('獲取用戶帳號類型: $uid');
      
      final doc = await getUserDocument(uid);
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        final accountType = data?['accountType'] as String?;
        debugPrint('用戶帳號類型: $accountType');
        return accountType;
      } else {
        debugPrint('用戶文檔不存在，無法獲取帳號類型');
        return null;
      }
    } catch (e) {
      debugPrint('取得用戶帳號類型時發生錯誤: $e');
      return null;
    }
  }

  /// 取得企業 KYC 狀態
  Future<String?> getBusinessKycStatus(String uid) async {
    try {
      debugPrint('獲取企業 KYC 狀態: $uid');
      
      final doc = await getUserDocument(uid);
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        final accountType = data?['accountType'] as String?;
        
        // 只有企業帳號才有 KYC 狀態
        if (accountType == 'business') {
          final businessKycStatus = data?['businessKycStatus'] as String?;
          debugPrint('企業 KYC 狀態: $businessKycStatus');
          return businessKycStatus ?? 'pending'; // 預設為待審核
        } else {
          debugPrint('非企業帳號，無企業 KYC 狀態');
          return null;
        }
      } else {
        debugPrint('用戶文檔不存在，無法獲取企業 KYC 狀態');
        return null;
      }
    } catch (e) {
      debugPrint('取得企業 KYC 狀態時發生錯誤: $e');
      return null;
    }
  }

  /// 更新企業 KYC 狀態
  Future<void> updateBusinessKycStatus(String uid, String status) async {
    try {
      debugPrint('更新企業 KYC 狀態: $uid -> $status');
      
      await _firestore.collection('users').doc(uid).update({
        'businessKycStatus': status, // pending, approved, rejected
        'businessKycUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('企業 KYC 狀態更新成功');
      
      // 如果 KYC 狀態變為 approved，自動上架待審核的草稿活動
      if (status == 'approved') {
        try {
          final activityService = ActivityService();
          await activityService.autoPublishKycPendingDrafts(uid);
          debugPrint('自動上架 KYC 待審核草稿活動完成');
        } catch (e) {
          debugPrint('自動上架草稿活動失敗: $e');
          // 不拋出異常，避免影響 KYC 狀態更新
        }
      }
    } catch (e) {
      debugPrint('更新企業 KYC 狀態時發生錯誤: $e');
      throw Exception('更新企業 KYC 狀態失敗：$e');
    }
  }

  /// 檢查用戶是否已完成 KYC（個人或企業）
  Future<bool> hasCompletedKyc(String uid) async {
    try {
      final doc = await getUserDocument(uid);
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        final accountType = data?['accountType'] as String?;
        
        if (accountType == 'business') {
          // 企業帳號檢查企業 KYC 狀態
          final businessKycStatus = data?['businessKycStatus'] as String?;
          return businessKycStatus == 'approved';
        } else {
          // 個人帳號檢查個人 KYC 狀態
          final personalKycStatus = data?['kyc']?['kycStatus'] as String?;
          return personalKycStatus == 'approved';
        }
      }
      return false;
    } catch (e) {
      debugPrint('檢查 KYC 完成狀態時發生錯誤: $e');
      return false;
    }
  }

  /// 取得統一的 KYC 狀態（個人或企業）
  Future<String?> getUnifiedKycStatus(String uid) async {
    try {
      final doc = await getUserDocument(uid);
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        final accountType = data?['accountType'] as String?;
        
        if (accountType == 'business') {
          // 企業帳號返回企業 KYC 狀態
          return data?['businessKycStatus'] as String? ?? 'pending';
        } else {
          // 個人帳號返回個人 KYC 狀態
          return data?['kyc']?['kycStatus'] as String?;
        }
      }
      return null;
    } catch (e) {
      debugPrint('取得統一 KYC 狀態時發生錯誤: $e');
      return null;
    }
  }

  /// 刪除用戶所有數據（Firestore文檔和Storage文件）
  Future<void> deleteUserData(String uid) async {
    try {
      debugPrint('開始刪除用戶數據: $uid');
      
      // 並行執行刪除操作
      await Future.wait([
        _deleteUserDocument(uid),
        _deleteUserStorageFiles(uid),
      ]);
      
      debugPrint('用戶數據刪除完成');
    } catch (e) {
      debugPrint('刪除用戶數據時發生錯誤: $e');
      throw Exception('刪除用戶數據失敗：$e');
    }
  }

  /// 刪除用戶Firestore文檔
  Future<void> _deleteUserDocument(String uid) async {
    try {
      debugPrint('刪除Firestore用戶文檔: $uid');
      
      await _firestore.collection('users').doc(uid).delete();
      
      debugPrint('Firestore用戶文檔刪除成功');
    } catch (e) {
      debugPrint('刪除Firestore用戶文檔時發生錯誤: $e');
      // 不拋出異常，讓其他刪除操作繼續進行
    }
  }

  /// 刪除用戶Storage文件
  Future<void> _deleteUserStorageFiles(String uid) async {
    try {
      debugPrint('刪除Firebase Storage用戶文件: $uid');
      
      // 獲取用戶文件夾的引用
      final userFolderRef = _storage.ref().child('users/$uid');
      
      // 列出所有文件
      final listResult = await userFolderRef.listAll();
      
      // 刪除所有文件
      final deleteFileTasks = listResult.items.map((item) => item.delete());
      
      // 遞歸刪除子文件夾
      final deleteSubfolderTasks = listResult.prefixes.map((prefix) async {
        final subListResult = await prefix.listAll();
        final subDeleteTasks = subListResult.items.map((item) => item.delete());
        await Future.wait(subDeleteTasks);
      });
      
      // 等待所有刪除操作完成
      await Future.wait([
        ...deleteFileTasks,
        ...deleteSubfolderTasks,
      ]);
      
      debugPrint('Firebase Storage用戶文件刪除成功');
    } catch (e) {
      debugPrint('刪除Firebase Storage用戶文件時發生錯誤: $e');
      // 不拋出異常，讓其他刪除操作繼續進行
    }
  }

}

