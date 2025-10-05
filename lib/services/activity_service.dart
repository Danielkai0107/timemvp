import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'auth_service.dart';
import 'user_service.dart';

/// 活動服務類
/// 處理活動相關的 Firebase 操作
class ActivityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  /// 發布新活動
  /// 
  /// [activityData] 活動資料
  /// [imagePaths] 活動圖片本地路徑列表
  /// 
  /// 回傳: 發布成功的活動 ID
  Future<String> publishActivity({
    required Map<String, dynamic> activityData,
    required List<String> imagePaths,
  }) async {
    try {
      debugPrint('=== ActivityService: 開始發布活動 ===');
      
      // 檢查用戶是否已登入
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        debugPrint('錯誤: 用戶未登入');
        throw Exception('用戶未登入');
      }
      
      debugPrint('當前用戶: ${currentUser.uid}, ${currentUser.email}');

      // 上傳活動圖片
      debugPrint('開始上傳 ${imagePaths.length} 張圖片...');
      final List<Map<String, dynamic>> uploadedFiles = [];
      
      for (int i = 0; i < imagePaths.length; i++) {
        final imagePath = imagePaths[i];
        final file = File(imagePath);
        
        debugPrint('檢查圖片 $i: $imagePath');
        if (await file.exists()) {
          debugPrint('開始上傳圖片 $i...');
          try {
            final fileUrl = await _uploadActivityImage(
              file: file,
              userId: currentUser.uid,
              fileName: 'activity_image_${i + 1}.jpg',
            );
            
            debugPrint('圖片 $i 上傳成功: $fileUrl');
            
            uploadedFiles.add({
              'url': fileUrl,
              'originalName': 'activity_image_${i + 1}.jpg',
              'mimeType': 'image/jpeg',
              'fileSize': (await file.length()).toString(),
              'createdAt': DateTime.now().toIso8601String(),
            });
          } catch (e) {
            debugPrint('圖片 $i 上傳失敗: $e');
            // 繼續處理其他圖片，不要因為一張圖片失敗就停止
          }
        } else {
          debugPrint('圖片文件不存在: $imagePath');
        }
      }
      
      debugPrint('圖片上傳完成，成功 ${uploadedFiles.length} 張');

      // 獲取用戶完整資料
      debugPrint('開始獲取用戶資料...');
      final userInfo = await _userService.getUserBasicInfo(currentUser.uid);
      debugPrint('用戶資料獲取完成: ${userInfo['name']}');

      // 準備完整的活動資料
      final coverUrl = uploadedFiles.isNotEmpty ? uploadedFiles.first['url'] : null;
      debugPrint('設置封面圖片URL: $coverUrl');
      
      final completeActivityData = {
        ...activityData,
        'userId': currentUser.uid, // 使用Firebase UID
        'cover': coverUrl,
        'files': uploadedFiles,
        'user': {
          ...userInfo,
          'email': currentUser.email, // 確保使用當前登入的email
        },
      };

      debugPrint('準備發布的完整資料: $completeActivityData');

      // 保存到 Firestore posts 集合
      debugPrint('開始保存到 Firestore...');
      final docRef = await _firestore.collection('posts').add(completeActivityData);
      debugPrint('Firestore 文檔創建成功: ${docRef.id}');
      
      // 更新文檔，添加 id 字段
      await docRef.update({
        'id': docRef.id,
      });
      debugPrint('文檔 ID 更新成功');

      debugPrint('=== 活動發布完全成功 ===');
      return docRef.id;
    } catch (e) {
      debugPrint('ActivityService 發布失敗: $e');
      debugPrint('錯誤堆疊: ${e.toString()}');
      throw Exception('發布活動失敗: $e');
    }
  }

  /// 上傳活動圖片到 Firebase Storage
  Future<String> _uploadActivityImage({
    required File file,
    required String userId,
    required String fileName,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage.ref().child('activity/$userId/image/${timestamp}_$fileName');
      
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('圖片上傳失敗: $e');
    }
  }

  /// 獲取用戶發布的活動列表
  Future<List<Map<String, dynamic>>> getUserActivities({
    required String userId,
    int limit = 20,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId) // 直接使用字符串UID
          .limit(limit)
          .get();

      final activities = querySnapshot.docs
          .map((doc) => <String, dynamic>{
                'id': doc.id,
                ...doc.data(),
              })
          .toList();

      // 在客戶端按創建時間排序
      activities.sort((a, b) {
        final aCreatedAt = a['createdAt'] as String?;
        final bCreatedAt = b['createdAt'] as String?;
        
        if (aCreatedAt == null && bCreatedAt == null) return 0;
        if (aCreatedAt == null) return 1;
        if (bCreatedAt == null) return -1;
        
        try {
          final aDate = DateTime.parse(aCreatedAt);
          final bDate = DateTime.parse(bCreatedAt);
          return bDate.compareTo(aDate); // 降序排列（最新的在前）
        } catch (e) {
          debugPrint('日期解析錯誤: $e');
          return 0;
        }
      });

      return activities;
    } catch (e) {
      throw Exception('獲取活動列表失敗: $e');
    }
  }

  /// 獲取所有活動（首頁顯示）
  Future<List<Map<String, dynamic>>> getAllActivities({
    String? type,
    String? category,
    int limit = 20,
  }) async {
    try {
      debugPrint('開始獲取活動列表，類型: $type，分類: $category');
      
      // 只使用最基本的查詢，避免複合索引需求
      Query query = _firestore.collection('posts');
      
      // 只按創建時間排序，不使用其他 where 條件避免複合索引
      query = query.orderBy('createdAt', descending: true).limit(100); // 增加限制以確保有足夠數據進行客戶端篩選

      final querySnapshot = await query.get();
      debugPrint('從Firestore獲取到 ${querySnapshot.docs.length} 個文檔');

      final activities = querySnapshot.docs
          .map((doc) => <String, dynamic>{
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .where((activity) {
            // 在客戶端篩選所有條件
            bool isActive = activity['status'] == 'active';
            
            // 類型篩選
            bool matchesType = true;
            if (type != null && type.isNotEmpty) {
              matchesType = activity['type'] == type;
            }
            
            // 分類篩選
            bool matchesCategory = true;
            if (category != null && category.isNotEmpty) {
              matchesCategory = activity['category'] == category;
            }
            
            return isActive && matchesType && matchesCategory;
          })
          .take(limit) // 限制最終結果數量
          .toList();

      debugPrint('篩選後的活動數量: ${activities.length}');
      return activities;
    } catch (e) {
      debugPrint('獲取活動列表失敗: $e');
      throw Exception('獲取活動列表失敗: $e');
    }
  }

  /// 更新活動狀態
  Future<void> updateActivityStatus({
    required String activityId,
    required String status,
  }) async {
    try {
      await _firestore.collection('posts').doc(activityId).update({
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('更新活動狀態失敗: $e');
    }
  }

  /// 刪除活動
  Future<void> deleteActivity(String activityId) async {
    try {
      await _firestore.collection('posts').doc(activityId).delete();
    } catch (e) {
      throw Exception('刪除活動失敗: $e');
    }
  }

  /// 自動上架用戶的 KYC 待審核草稿活動
  /// 當用戶 KYC 狀態變為 approved 時調用
  Future<void> autoPublishKycPendingDrafts(String userId) async {
    try {
      debugPrint('開始自動上架用戶 KYC 待審核草稿活動: $userId');
      
      // 查詢該用戶的所有 KYC 待審核草稿活動
      final querySnapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'draft')
          .where('draftReason', isEqualTo: 'kyc_pending')
          .get();
      
      debugPrint('找到 ${querySnapshot.docs.length} 個 KYC 待審核草稿活動');
      
      // 批量更新狀態
      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {
          'status': 'active',
          'draftReason': null, // 清除草稿原因
          'updatedAt': DateTime.now().toIso8601String(),
          'publishedAt': DateTime.now().toIso8601String(), // 記錄實際上架時間
        });
      }
      
      await batch.commit();
      debugPrint('成功自動上架 ${querySnapshot.docs.length} 個活動');
    } catch (e) {
      debugPrint('自動上架 KYC 待審核草稿活動失敗: $e');
      throw Exception('自動上架活動失敗: $e');
    }
  }

  /// 手動切換活動的上架/草稿狀態
  /// 區分用戶手動操作和系統自動操作
  Future<void> toggleActivityPublishStatus({
    required String activityId,
    required bool publish, // true: 上架, false: 設為草稿
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': publish ? 'active' : 'draft',
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      if (publish) {
        // 上架時清除草稿原因並記錄上架時間
        updateData['draftReason'] = null;
        updateData['publishedAt'] = DateTime.now().toIso8601String();
      } else {
        // 設為草稿時標記為用戶手動操作
        updateData['draftReason'] = 'manual';
      }
      
      await _firestore.collection('posts').doc(activityId).update(updateData);
      debugPrint('活動狀態切換成功: $activityId -> ${publish ? "上架" : "草稿"}');
    } catch (e) {
      debugPrint('切換活動狀態失敗: $e');
      throw Exception('切換活動狀態失敗: $e');
    }
  }

  /// 獲取活動的報名數量
  Future<int> getActivityRegistrationCount(String activityId) async {
    try {
      debugPrint('獲取活動報名數量: $activityId');
      
      final querySnapshot = await _firestore
          .collection('user_registrations')
          .where('activityId', isEqualTo: activityId)
          .where('status', whereIn: ['registered', 'application_success'])
          .get();
      
      final count = querySnapshot.docs.length;
      debugPrint('活動 $activityId 的報名數量: $count');
      return count;
    } catch (e) {
      debugPrint('獲取報名數量失敗: $e');
      return 0; // 發生錯誤時返回 0，允許切換
    }
  }

  /// 更新活動
  Future<void> updateActivity({
    required String activityId,
    required Map<String, dynamic> updateData,
    List<String>? newImagePaths,
    List<String>? existingImageUrls,
  }) async {
    try {
      debugPrint('開始更新活動: $activityId');
      
      // 處理圖片上傳
      List<String> finalImageUrls = [];
      
      // 保留現有的網路圖片
      if (existingImageUrls != null) {
        finalImageUrls.addAll(existingImageUrls);
      }
      
      // 上傳新圖片
      if (newImagePaths != null && newImagePaths.isNotEmpty) {
        final user = _authService.currentUser;
        if (user != null) {
          for (String imagePath in newImagePaths) {
            try {
              final fileName = 'activity_${activityId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
              final ref = _storage.ref().child('activities/$activityId/$fileName');
              
              await ref.putFile(File(imagePath));
              final downloadUrl = await ref.getDownloadURL();
              finalImageUrls.add(downloadUrl);
              
              debugPrint('圖片上傳成功: $downloadUrl');
            } catch (e) {
              debugPrint('圖片上傳失敗: $imagePath, 錯誤: $e');
            }
          }
        }
      }
      
      // 更新活動資料
      final finalUpdateData = {
        ...updateData,
        'images': finalImageUrls,
      };
      
      await _firestore.collection('posts').doc(activityId).update(finalUpdateData);
      
      debugPrint('活動更新成功: $activityId');
    } catch (e) {
      debugPrint('更新活動失敗: $e');
      throw Exception('更新活動失敗: $e');
    }
  }

  /// 獲取活動詳情
  Future<Map<String, dynamic>?> getActivityDetail(String activityId) async {
    try {
      debugPrint('從Firebase獲取活動詳情: $activityId');
      final doc = await _firestore.collection('posts').doc(activityId).get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final activityDetail = <String, dynamic>{
          'id': doc.id,
          ...data,
        };
        
        // 獲取發布者資訊
        final userId = data['userId'] as String?;
        if (userId != null) {
          try {
            debugPrint('=== 獲取活動發布者資訊 ===');
            debugPrint('發布者用戶ID: $userId');
            debugPrint('活動ID: $activityId');
            debugPrint('活動名稱: ${data['name']}');
            
            final userInfo = await _userService.getUserBasicInfo(userId);
            debugPrint('從 UserService 獲取的用戶資訊: $userInfo');
            
            if (userInfo.isNotEmpty) {
              activityDetail['user'] = userInfo;
              debugPrint('✅ 發布者資訊獲取成功');
              debugPrint('發布者姓名: ${userInfo['name']}');
              debugPrint('發布者頭像: ${userInfo['avatar']}');
              debugPrint('發布者狀態: ${userInfo['status']}');
            } else {
              debugPrint('❌ 發布者資訊為空，使用預設資料');
              activityDetail['user'] = {
                'id': userId,
                'name': '主辦者',
                'avatar': null,
                'rating': '5.0',
                'status': 'pending',
              };
            }
          } catch (e) {
            debugPrint('❌ 獲取發布者資訊失敗: $e');
            debugPrint('錯誤類型: ${e.runtimeType}');
            // 發生錯誤時使用預設資料
            activityDetail['user'] = {
              'id': userId,
              'name': '主辦者',
              'avatar': null,
              'rating': '5.0',
              'status': 'pending',
            };
          }
        } else {
          debugPrint('❌ 活動沒有發布者ID');
        }
        
        debugPrint('活動詳情獲取成功: ${activityDetail['name']}');
        debugPrint('活動發布者ID: ${activityDetail['userId']}');
        return activityDetail;
      } else {
        debugPrint('活動文檔不存在: $activityId');
        return null;
      }
    } catch (e) {
      debugPrint('獲取活動詳情失敗: $e');
      throw Exception('獲取活動詳情失敗: $e');
    }
  }

  /// 用戶報名活動
  Future<void> registerForActivity({
    required String activityId,
    required String userId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      debugPrint('=== ActivityService: 開始用戶報名活動 ===');
      debugPrint('用戶ID: $userId');
      debugPrint('活動ID: $activityId');
      debugPrint('額外資料: $additionalData');
      
      // 檢查用戶是否已經報名
      final existingRegistration = await _firestore
          .collection('user_registrations')
          .doc('${userId}_$activityId')
          .get();
      
      if (existingRegistration.exists) {
        debugPrint('用戶已經報名過此活動');
        throw Exception('您已經報名過此活動');
      }
      
      final registrationData = {
        'userId': userId,
        'activityId': activityId,
        'status': 'registered', // 報名成功
        'registeredAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        ...?additionalData,
      };

      debugPrint('準備保存的報名資料: $registrationData');
      debugPrint('文檔ID: ${userId}_$activityId');

      // 保存到用戶報名記錄集合
      await _firestore
          .collection('user_registrations')
          .doc('${userId}_$activityId')
          .set(registrationData);

      debugPrint('=== 報名資料已成功保存到Firestore ===');
      
      // 驗證資料是否真的保存成功
      final savedDoc = await _firestore
          .collection('user_registrations')
          .doc('${userId}_$activityId')
          .get();
      
      if (savedDoc.exists) {
        debugPrint('✅ 驗證成功：報名資料已確實保存');
        debugPrint('保存的資料: ${savedDoc.data()}');
      } else {
        debugPrint('❌ 驗證失敗：報名資料未能保存');
        throw Exception('報名資料保存驗證失敗');
      }
      
    } catch (e) {
      debugPrint('=== ActivityService: 活動報名失敗 ===');
      debugPrint('錯誤詳情: $e');
      debugPrint('錯誤堆疊: ${StackTrace.current}');
      throw Exception('活動報名失敗: $e');
    }
  }

  /// 用戶應徵任務
  Future<void> applyForTask({
    required String activityId,
    required String userId,
    Map<String, dynamic>? applicationData,
  }) async {
    try {
      debugPrint('用戶應徵任務: $userId -> $activityId');
      
      final applicationDataMap = {
        'userId': userId,
        'activityId': activityId,
        'status': 'application_pending', // 應徵確認中
        'appliedAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        ...?applicationData,
      };

      // 保存到用戶報名記錄集合
      await _firestore
          .collection('user_registrations')
          .doc('${userId}_$activityId')
          .set(applicationDataMap);

      debugPrint('任務應徵提交成功');
    } catch (e) {
      debugPrint('任務應徵失敗: $e');
      throw Exception('任務應徵失敗: $e');
    }
  }

  /// 更新用戶報名/應徵狀態
  Future<void> updateRegistrationStatus({
    required String userId,
    required String activityId,
    required String status,
  }) async {
    try {
      debugPrint('更新報名狀態: $userId -> $activityId -> $status');
      
      await _firestore
          .collection('user_registrations')
          .doc('${userId}_$activityId')
          .update({
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      debugPrint('報名狀態更新成功');
    } catch (e) {
      debugPrint('更新報名狀態失敗: $e');
      throw Exception('更新報名狀態失敗: $e');
    }
  }

  /// 獲取用戶報名的活動列表
  Future<List<Map<String, dynamic>>> getUserRegisteredActivities({
    required String userId,
    int limit = 20,
  }) async {
    try {
      debugPrint('=== 獲取用戶報名活動列表 ===');
      debugPrint('用戶ID: $userId');
      
      // 獲取用戶的報名記錄
      final registrationQuery = await _firestore
          .collection('user_registrations')
          .where('userId', isEqualTo: userId)
          .limit(limit)
          .get();

      debugPrint('找到 ${registrationQuery.docs.length} 個報名記錄');

      final List<Map<String, dynamic>> registeredActivities = [];

      // 為每個報名記錄獲取對應的活動詳情
      for (int i = 0; i < registrationQuery.docs.length; i++) {
        final doc = registrationQuery.docs[i];
        final registrationData = doc.data();
        final activityId = registrationData['activityId'] as String;
        
        debugPrint('處理報名記錄 ${i + 1}: 活動ID=$activityId');
        debugPrint('報名資料: $registrationData');
        
        // 獲取活動詳情
        final activityDetail = await getActivityDetail(activityId);
        if (activityDetail != null) {
          debugPrint('活動詳情獲取成功: ${activityDetail['name']}');
          
          final combinedData = {
            'registration': {
              'id': doc.id,
              ...registrationData,
            },
            'activity': activityDetail,
          };
          
          debugPrint('組合後的資料結構: $combinedData');
          registeredActivities.add(combinedData);
        } else {
          debugPrint('❌ 活動詳情獲取失敗，活動ID: $activityId');
        }
      }

      debugPrint('=== 最終獲取到 ${registeredActivities.length} 個有效報名活動 ===');
      
      // 按報名時間排序（最新的在前）
      registeredActivities.sort((a, b) {
        final aRegisteredAt = a['registration']['registeredAt'] as String?;
        final bRegisteredAt = b['registration']['registeredAt'] as String?;
        
        if (aRegisteredAt == null && bRegisteredAt == null) return 0;
        if (aRegisteredAt == null) return 1;
        if (bRegisteredAt == null) return -1;
        
        try {
          final aDate = DateTime.parse(aRegisteredAt);
          final bDate = DateTime.parse(bRegisteredAt);
          return bDate.compareTo(aDate); // 降序排列（最新的在前）
        } catch (e) {
          debugPrint('日期解析錯誤: $e');
          return 0;
        }
      });
      
      return registeredActivities;
    } catch (e) {
      debugPrint('=== 獲取用戶報名活動失敗 ===');
      debugPrint('錯誤詳情: $e');
      throw Exception('獲取用戶報名活動失敗: $e');
    }
  }

  /// 獲取用戶發布的活動列表（擴展版本，包含狀態信息）
  Future<List<Map<String, dynamic>>> getUserPublishedActivities({
    required String userId,
    int limit = 20,
  }) async {
    try {
      debugPrint('獲取用戶發布活動列表: $userId');
      
      final querySnapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .limit(limit)
          .get();

      final activities = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return <String, dynamic>{
          'id': doc.id,
          ...data,
          // 根據活動狀態和類型確定顯示狀態
          'displayStatus': _getActivityDisplayStatus(data),
        };
      }).toList();

      // 在客戶端按創建時間排序
      activities.sort((a, b) {
        final aCreatedAt = a['createdAt'] as String?;
        final bCreatedAt = b['createdAt'] as String?;
        
        if (aCreatedAt == null && bCreatedAt == null) return 0;
        if (aCreatedAt == null) return 1;
        if (bCreatedAt == null) return -1;
        
        try {
          final aDate = DateTime.parse(aCreatedAt);
          final bDate = DateTime.parse(bCreatedAt);
          return bDate.compareTo(aDate); // 降序排列（最新的在前）
        } catch (e) {
          debugPrint('日期解析錯誤: $e');
          return 0;
        }
      });

      debugPrint('獲取到 ${activities.length} 個發布活動');
      return activities;
    } catch (e) {
      debugPrint('獲取用戶發布活動失敗: $e');
      throw Exception('獲取用戶發布活動失敗: $e');
    }
  }

  /// 根據活動數據確定顯示狀態
  String _getActivityDisplayStatus(Map<String, dynamic> activityData) {
    final status = activityData['status'] as String?;
    final type = activityData['type'] as String?;
    
    // 檢查活動是否已結束（根據結束時間）
    final endDateStr = activityData['endDate'] as String?;
    if (endDateStr != null) {
      try {
        final endDate = DateTime.parse(endDateStr);
        if (endDate.isBefore(DateTime.now())) {
          return 'ended';
        }
      } catch (e) {
        debugPrint('解析結束時間失敗: $e');
      }
    }

    // 根據狀態和類型返回顯示狀態
    switch (status) {
      case 'active':
        return type == 'event' ? 'published' : 'recruiting';
      case 'draft':
        return 'draft'; // 草稿狀態統一返回 'draft'
      case 'cancelled':
        return 'cancelled';
      case 'ended':
        return 'ended';
      default:
        return type == 'event' ? 'published' : 'recruiting';
    }
  }

  /// 取消用戶報名
  Future<void> cancelRegistration({
    required String userId,
    required String activityId,
  }) async {
    try {
      debugPrint('取消用戶報名: $userId -> $activityId');
      
      await _firestore
          .collection('user_registrations')
          .doc('${userId}_$activityId')
          .delete();

      debugPrint('報名取消成功');
    } catch (e) {
      debugPrint('取消報名失敗: $e');
      throw Exception('取消報名失敗: $e');
    }
  }

  /// 檢查用戶是否已報名某活動
  Future<bool> isUserRegistered({
    required String userId,
    required String activityId,
  }) async {
    try {
      debugPrint('=== 檢查用戶報名狀態 ===');
      debugPrint('用戶ID: $userId');
      debugPrint('活動ID: $activityId');
      debugPrint('查詢文檔ID: ${userId}_$activityId');
      
      final doc = await _firestore
          .collection('user_registrations')
          .doc('${userId}_$activityId')
          .get();
      
      final isRegistered = doc.exists;
      debugPrint('報名狀態: ${isRegistered ? "已報名" : "未報名"}');
      
      if (isRegistered) {
        debugPrint('報名資料: ${doc.data()}');
      }
      
      return isRegistered;
    } catch (e) {
      debugPrint('檢查報名狀態失敗: $e');
      return false;
    }
  }

  /// 獲取用戶的詳細報名狀態
  Future<Map<String, dynamic>?> getUserRegistrationStatus({
    required String userId,
    required String activityId,
  }) async {
    try {
      debugPrint('=== 獲取用戶詳細報名狀態 ===');
      debugPrint('用戶ID: $userId');
      debugPrint('活動ID: $activityId');
      
      final doc = await _firestore
          .collection('user_registrations')
          .doc('${userId}_$activityId')
          .get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        debugPrint('報名狀態詳情: $data');
        return data;
      } else {
        debugPrint('用戶未報名此活動');
        return null;
      }
    } catch (e) {
      debugPrint('獲取報名狀態詳情失敗: $e');
      return null;
    }
  }

  /// 獲取活動的報名者列表
  Future<List<Map<String, dynamic>>> getActivityParticipants({
    required String activityId,
    int limit = 50,
  }) async {
    try {
      debugPrint('=== 獲取活動報名者列表 ===');
      debugPrint('活動ID: $activityId');
      
      // 獲取該活動的所有報名記錄（包含已結束的參與者）
      final registrationQuery = await _firestore
          .collection('user_registrations')
          .where('activityId', isEqualTo: activityId)
          .where('status', whereIn: ['registered', 'application_success', 'ended'])
          .limit(limit)
          .get();

      debugPrint('找到 ${registrationQuery.docs.length} 個報名記錄');

      final List<Map<String, dynamic>> participants = [];

      // 為每個報名記錄獲取對應的用戶詳情
      for (int i = 0; i < registrationQuery.docs.length; i++) {
        final doc = registrationQuery.docs[i];
        final registrationData = doc.data();
        final userId = registrationData['userId'] as String;
        
        debugPrint('處理報名記錄 ${i + 1}: 用戶ID=$userId');
        
        try {
          // 獲取用戶詳情
          final userInfo = await _userService.getUserBasicInfo(userId);
          if (userInfo.isNotEmpty) {
            debugPrint('用戶詳情獲取成功: ${userInfo['name']}');
            
            final participantData = {
              'registration': {
                'id': doc.id,
                ...registrationData,
              },
              'user': userInfo,
            };
            
            participants.add(participantData);
          } else {
            debugPrint('❌ 用戶詳情獲取失敗，用戶ID: $userId');
          }
        } catch (e) {
          debugPrint('❌ 獲取用戶詳情時發生錯誤: $e');
        }
      }

      debugPrint('=== 最終獲取到 ${participants.length} 個有效報名者 ===');
      
      // 按報名時間排序（最新的在前）
      participants.sort((a, b) {
        final aRegisteredAt = a['registration']['registeredAt'] as String?;
        final bRegisteredAt = b['registration']['registeredAt'] as String?;
        
        if (aRegisteredAt == null && bRegisteredAt == null) return 0;
        if (aRegisteredAt == null) return 1;
        if (bRegisteredAt == null) return -1;
        
        try {
          final aDate = DateTime.parse(aRegisteredAt);
          final bDate = DateTime.parse(bRegisteredAt);
          return bDate.compareTo(aDate); // 降序排列（最新的在前）
        } catch (e) {
          debugPrint('日期解析錯誤: $e');
          return 0;
        }
      });
      
      return participants;
    } catch (e) {
      debugPrint('=== 獲取活動報名者失敗 ===');
      debugPrint('錯誤詳情: $e');
      throw Exception('獲取活動報名者失敗: $e');
    }
  }

  /// 刪除用戶發布的所有活動
  Future<void> deleteUserActivities(String userId) async {
    try {
      debugPrint('開始刪除用戶發布的所有活動: $userId');
      
      // 獲取用戶發布的所有活動
      final querySnapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .get();
      
      debugPrint('找到 ${querySnapshot.docs.length} 個用戶發布的活動');
      
      // 批量刪除活動文檔
      final batch = _firestore.batch();
      final List<String> activityIds = [];
      
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
        activityIds.add(doc.id);
      }
      
      await batch.commit();
      debugPrint('成功刪除 ${querySnapshot.docs.length} 個活動文檔');
      
      // 刪除活動相關的 Storage 文件
      await _deleteUserActivityStorageFiles(userId, activityIds);
      
      debugPrint('用戶活動刪除完成');
    } catch (e) {
      debugPrint('刪除用戶活動時發生錯誤: $e');
      // 不拋出異常，讓其他刪除操作繼續進行
    }
  }

  /// 刪除用戶活動相關的 Storage 文件
  Future<void> _deleteUserActivityStorageFiles(String userId, List<String> activityIds) async {
    try {
      debugPrint('刪除用戶活動 Storage 文件: $userId');
      
      // 刪除用戶活動文件夾下的所有文件
      final activityFolderRef = _storage.ref().child('activity/$userId');
      
      try {
        final listResult = await activityFolderRef.listAll();
        
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
        
        debugPrint('用戶活動 Storage 文件刪除成功');
      } catch (e) {
        debugPrint('刪除活動 Storage 文件時發生錯誤: $e');
        // 繼續執行，不影響其他刪除操作
      }
      
      // 也嘗試刪除以活動ID命名的文件夾
      for (final activityId in activityIds) {
        try {
          final activitySpecificRef = _storage.ref().child('activities/$activityId');
          final listResult = await activitySpecificRef.listAll();
          
          final deleteFileTasks = listResult.items.map((item) => item.delete());
          await Future.wait(deleteFileTasks);
          
          debugPrint('活動 $activityId 的 Storage 文件刪除成功');
        } catch (e) {
          debugPrint('刪除活動 $activityId Storage 文件時發生錯誤: $e');
          // 繼續處理下一個活動
        }
      }
      
    } catch (e) {
      debugPrint('刪除用戶活動 Storage 文件時發生錯誤: $e');
      // 不拋出異常，讓其他刪除操作繼續進行
    }
  }

  /// 刪除用戶的所有報名記錄
  Future<void> deleteUserRegistrations(String userId) async {
    try {
      debugPrint('開始刪除用戶的所有報名記錄: $userId');
      
      // 獲取用戶的所有報名記錄
      final querySnapshot = await _firestore
          .collection('user_registrations')
          .where('userId', isEqualTo: userId)
          .get();
      
      debugPrint('找到 ${querySnapshot.docs.length} 個用戶報名記錄');
      
      // 批量刪除報名記錄
      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      debugPrint('成功刪除 ${querySnapshot.docs.length} 個報名記錄');
      
    } catch (e) {
      debugPrint('刪除用戶報名記錄時發生錯誤: $e');
      // 不拋出異常，讓其他刪除操作繼續進行
    }
  }

  /// 刪除與用戶相關的所有活動數據（發布的活動和報名記錄）
  Future<void> deleteAllUserActivityData(String userId) async {
    try {
      debugPrint('開始刪除用戶的所有活動相關數據: $userId');
      
      // 並行執行刪除操作以提高效率
      await Future.wait([
        deleteUserActivities(userId),
        deleteUserRegistrations(userId),
      ]);
      
      debugPrint('用戶活動相關數據刪除完成');
    } catch (e) {
      debugPrint('刪除用戶活動相關數據時發生錯誤: $e');
      throw Exception('刪除用戶活動相關數據失敗：$e');
    }
  }

  /// 測試 Firestore 連接和權限
  Future<void> testFirestoreConnection() async {
    try {
      debugPrint('=== 測試 Firestore 連接 ===');
      
      // 測試讀取權限
      final testQuery = await _firestore
          .collection('user_registrations')
          .limit(1)
          .get();
      
      debugPrint('✅ Firestore 讀取測試成功，文檔數量: ${testQuery.docs.length}');
      
      // 測試寫入權限（創建一個測試文檔）
      final testDocId = 'test_${DateTime.now().millisecondsSinceEpoch}';
      await _firestore
          .collection('user_registrations')
          .doc(testDocId)
          .set({
        'test': true,
        'createdAt': DateTime.now().toIso8601String(),
      });
      
      debugPrint('✅ Firestore 寫入測試成功');
      
      // 刪除測試文檔
      await _firestore
          .collection('user_registrations')
          .doc(testDocId)
          .delete();
      
      debugPrint('✅ Firestore 刪除測試成功');
      debugPrint('=== Firestore 連接測試完成 ===');
      
    } catch (e) {
      debugPrint('❌ Firestore 連接測試失敗: $e');
      throw Exception('Firestore 連接測試失敗: $e');
    }
  }

  /// 提交活動評分
  /// 
  /// [activityId] 活動ID
  /// [raterId] 評分者ID
  /// [ratings] 評分數據 (主辦方ID -> 評分)
  /// [comment] 評論內容
  Future<void> submitActivityRating({
    required String activityId,
    required String raterId,
    required Map<String, dynamic> ratings,
    String? comment,
  }) async {
    try {
      debugPrint('=== 提交活動評分 ===');
      debugPrint('活動ID: $activityId');
      debugPrint('評分者ID: $raterId');
      debugPrint('評分數據: $ratings');
      debugPrint('評論: $comment');

      // 檢查用戶是否已經評分過
      final existingRating = await _firestore
          .collection('activity_ratings')
          .doc('${raterId}_$activityId')
          .get();

      if (existingRating.exists) {
        debugPrint('用戶已經評分過此活動');
        throw Exception('您已經評分過此活動');
      }

      // 準備評分數據
      final ratingData = {
        'activityId': activityId,
        'raterId': raterId,
        'ratings': ratings,
        'comment': comment,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // 保存評分記錄
      await _firestore
          .collection('activity_ratings')
          .doc('${raterId}_$activityId')
          .set(ratingData);

      debugPrint('評分記錄保存成功');

      // 更新被評分用戶的評分統計
      await _updateUserRatingStats(ratings);

      debugPrint('=== 活動評分提交完成 ===');
    } catch (e) {
      debugPrint('提交活動評分失敗: $e');
      throw Exception('提交評分失敗: $e');
    }
  }

  /// 更新用戶評分統計
  Future<void> _updateUserRatingStats(Map<String, dynamic> ratings) async {
    try {
      for (final entry in ratings.entries) {
        final userId = entry.key;
        final rating = entry.value as int;

        debugPrint('更新用戶 $userId 的評分統計，新評分: $rating');

        // 獲取用戶當前的評分統計
        final userDoc = await _firestore.collection('users').doc(userId).get();
        
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final currentRating = double.tryParse(userData['rating']?.toString() ?? '5.0') ?? 5.0;
          final ratingCount = userData['ratingCount'] as int? ?? 0;

          // 計算新的平均評分
          final totalRating = (currentRating * ratingCount) + rating;
          final newRatingCount = ratingCount + 1;
          final newAverageRating = totalRating / newRatingCount;

          // 更新用戶評分
          await _firestore.collection('users').doc(userId).update({
            'rating': double.parse(newAverageRating.toStringAsFixed(1)),
            'ratingCount': newRatingCount,
            'updatedAt': DateTime.now().toIso8601String(),
          });

          debugPrint('用戶 $userId 評分統計更新完成: ${newAverageRating.toStringAsFixed(1)} ($newRatingCount 次評分)');
        }
      }
    } catch (e) {
      debugPrint('更新用戶評分統計失敗: $e');
      // 不拋出異常，因為這不應該阻止評分提交
    }
  }

  /// 獲取活動的評分列表
  Future<List<Map<String, dynamic>>> getActivityRatings({
    required String activityId,
    int limit = 20,
  }) async {
    try {
      debugPrint('獲取活動評分列表: $activityId');

      final query = await _firestore
          .collection('activity_ratings')
          .where('activityId', isEqualTo: activityId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final ratings = <Map<String, dynamic>>[];

      for (final doc in query.docs) {
        final ratingData = doc.data();
        
        // 獲取評分者資訊
        final raterId = ratingData['raterId'] as String;
        final raterInfo = await _userService.getUserBasicInfo(raterId);

        ratings.add({
          'id': doc.id,
          ...ratingData,
          'rater': raterInfo,
        });
      }

      debugPrint('獲取到 ${ratings.length} 個評分記錄');
      return ratings;
    } catch (e) {
      debugPrint('獲取活動評分列表失敗: $e');
      return [];
    }
  }

  /// 檢查用戶是否已經評分過活動
  Future<bool> hasUserRatedActivity({
    required String userId,
    required String activityId,
  }) async {
    try {
      final doc = await _firestore
          .collection('activity_ratings')
          .doc('${userId}_$activityId')
          .get();

      return doc.exists;
    } catch (e) {
      debugPrint('檢查用戶評分狀態失敗: $e');
      return false;
    }
  }

  /// 檢查活動是否已結束且用戶有參與
  Future<bool> shouldShowRatingPopup({
    required String userId,
    required String activityId,
  }) async {
    try {
      // 檢查用戶是否已報名此活動
      final isRegistered = await isUserRegistered(
        userId: userId,
        activityId: activityId,
      );

      if (!isRegistered) {
        return false;
      }

      // 檢查用戶的報名狀態
      final registrationDoc = await _firestore
          .collection('user_registrations')
          .doc('${userId}_$activityId')
          .get();

      if (!registrationDoc.exists) {
        return false;
      }

      final registrationData = registrationDoc.data() as Map<String, dynamic>;
      final registrationStatus = registrationData['status'] as String?;

      // 檢查活動是否已結束（活動狀態或報名狀態）
      final activity = await getActivityDetail(activityId);
      if (activity == null) {
        return false;
      }

      final activityStatus = activity['status'] as String?;
      final endDateTime = activity['endDateTime'] as String?;

      bool isActivityEnded = false;

      // 檢查活動是否已結束的條件：
      // 1. 活動狀態為 'ended'，或
      // 2. 報名狀態為 'ended'，或  
      // 3. 當前時間已超過活動結束時間
      if (activityStatus == 'ended' || registrationStatus == 'ended') {
        isActivityEnded = true;
        debugPrint('活動已結束 - 活動狀態: $activityStatus, 報名狀態: $registrationStatus');
      } else if (endDateTime != null) {
        try {
          final endTime = DateTime.parse(endDateTime);
          final now = DateTime.now();
          isActivityEnded = now.isAfter(endTime);
          if (isActivityEnded) {
            debugPrint('活動已結束 - 超過預定結束時間: $endDateTime');
          }
        } catch (e) {
          debugPrint('解析活動結束時間失敗: $e');
        }
      }

      if (!isActivityEnded) {
        debugPrint('活動尚未結束，不顯示評分彈窗');
        return false;
      }

      // 檢查是否已經評分過
      final hasRated = await hasUserRatedActivity(
        userId: userId,
        activityId: activityId,
      );

      if (hasRated) {
        debugPrint('用戶已評分過此活動');
        return false;
      }

      debugPrint('符合評分條件，將顯示評分彈窗');
      return true;
    } catch (e) {
      debugPrint('檢查是否應顯示評分彈窗失敗: $e');
      return false;
    }
  }

  /// 批量更新活動所有報名者的狀態
  Future<void> updateAllRegistrationStatusForActivity({
    required String activityId,
    required String newStatus,
  }) async {
    try {
      debugPrint('=== 批量更新活動報名者狀態 ===');
      debugPrint('活動ID: $activityId');
      debugPrint('新狀態: $newStatus');

      // 獲取該活動的所有報名記錄
      final registrationQuery = await _firestore
          .collection('user_registrations')
          .where('activityId', isEqualTo: activityId)
          .get();

      debugPrint('找到 ${registrationQuery.docs.length} 個報名記錄需要更新');

      if (registrationQuery.docs.isEmpty) {
        debugPrint('沒有報名記錄需要更新');
        return;
      }

      // 使用批量操作更新所有報名記錄
      final batch = _firestore.batch();
      final updateTime = DateTime.now().toIso8601String();

      for (final doc in registrationQuery.docs) {
        final currentData = doc.data();
        final currentStatus = currentData['status'] as String?;
        
        // 只更新狀態為 'registered' 的記錄（避免覆蓋已取消的報名）
        if (currentStatus == 'registered') {
          batch.update(doc.reference, {
            'status': newStatus,
            'updatedAt': updateTime,
          });
          debugPrint('將更新報名記錄: ${doc.id} 從 $currentStatus 到 $newStatus');
        } else {
          debugPrint('跳過報名記錄: ${doc.id}，當前狀態: $currentStatus');
        }
      }

      // 執行批量更新
      await batch.commit();
      debugPrint('=== 批量更新報名者狀態完成 ===');

    } catch (e) {
      debugPrint('批量更新報名者狀態失敗: $e');
      throw Exception('批量更新報名者狀態失敗: $e');
    }
  }

  /// 提前結束活動（包含更新報名者狀態）
  Future<void> endActivityEarly({
    required String activityId,
  }) async {
    try {
      debugPrint('=== 開始提前結束活動流程 ===');
      debugPrint('活動ID: $activityId');

      // 1. 更新活動狀態為已結束
      await updateActivityStatus(
        activityId: activityId,
        status: 'ended',
      );
      debugPrint('✅ 活動狀態已更新為已結束');

      // 2. 更新所有報名者狀態為已結束
      await updateAllRegistrationStatusForActivity(
        activityId: activityId,
        newStatus: 'ended',
      );
      debugPrint('✅ 所有報名者狀態已更新為已結束');

      debugPrint('=== 提前結束活動流程完成 ===');

    } catch (e) {
      debugPrint('提前結束活動流程失敗: $e');
      throw Exception('提前結束活動失敗: $e');
    }
  }

  /// 獲取用戶收到的評分列表（作為主辦者被評分的記錄）
  Future<List<Map<String, dynamic>>> getUserReceivedRatings({
    required String userId,
    int limit = 10,
  }) async {
    try {
      debugPrint('獲取用戶收到的評分列表: $userId');

      // 查詢所有評分記錄，找出評分對象包含該用戶的記錄
      final query = await _firestore
          .collection('activity_ratings')
          .orderBy('createdAt', descending: true)
          .limit(100) // 先獲取較多記錄，然後在客戶端篩選
          .get();

      final userRatings = <Map<String, dynamic>>[];

      for (final doc in query.docs) {
        final ratingData = doc.data();
        final ratings = ratingData['ratings'] as Map<String, dynamic>? ?? {};
        
        // 檢查這個評分記錄是否包含對該用戶的評分
        if (ratings.containsKey(userId)) {
          // 獲取評分者資訊
          final raterId = ratingData['raterId'] as String;
          final raterInfo = await _userService.getUserBasicInfo(raterId);
          
          // 獲取活動資訊
          final activityId = ratingData['activityId'] as String;
          final activityInfo = await getActivityDetail(activityId);

          userRatings.add({
            'id': doc.id,
            ...ratingData,
            'rater': raterInfo,
            'activity': activityInfo,
            'userRating': ratings[userId], // 該用戶收到的具體評分
          });

          // 達到限制數量就停止
          if (userRatings.length >= limit) {
            break;
          }
        }
      }

      debugPrint('獲取到 ${userRatings.length} 個用戶評分記錄');
      return userRatings;
    } catch (e) {
      debugPrint('獲取用戶收到的評分列表失敗: $e');
      return [];
    }
  }

  /// 發布者提交對參與者的評分
  Future<void> submitOrganizerRating({
    required String activityId,
    required String organizerId,
    required Map<String, dynamic> ratings,
    String? comment,
  }) async {
    try {
      debugPrint('=== 發布者提交參與者評分 ===');
      debugPrint('活動ID: $activityId');
      debugPrint('發布者ID: $organizerId');
      debugPrint('評分數據: $ratings');
      debugPrint('評論: $comment');

      // 檢查發布者是否已經評分過
      final existingRating = await _firestore
          .collection('organizer_ratings')
          .doc('${organizerId}_$activityId')
          .get();

      if (existingRating.exists) {
        debugPrint('發布者已經評分過此活動的參與者');
        throw Exception('您已經評分過此活動的參與者');
      }

      // 準備評分數據
      final ratingData = {
        'activityId': activityId,
        'organizerId': organizerId,
        'ratings': ratings,
        'comment': comment,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // 保存評分記錄
      await _firestore
          .collection('organizer_ratings')
          .doc('${organizerId}_$activityId')
          .set(ratingData);

      debugPrint('發布者評分記錄保存成功');

      // 更新被評分參與者的評分統計
      await _updateParticipantRatingStats(ratings);

      debugPrint('=== 發布者評分提交完成 ===');
    } catch (e) {
      debugPrint('提交發布者評分失敗: $e');
      throw Exception('提交評分失敗: $e');
    }
  }

  /// 更新參與者評分統計
  Future<void> _updateParticipantRatingStats(Map<String, dynamic> ratings) async {
    try {
      for (final entry in ratings.entries) {
        final userId = entry.key;
        final rating = entry.value as int;

        debugPrint('更新參與者 $userId 的評分統計，新評分: $rating');

        // 獲取用戶當前的評分統計
        final userDoc = await _firestore.collection('users').doc(userId).get();
        
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final currentRating = double.tryParse(userData['participantRating']?.toString() ?? '5.0') ?? 5.0;
          final ratingCount = userData['participantRatingCount'] as int? ?? 0;

          // 計算新的平均評分
          final totalRating = (currentRating * ratingCount) + rating;
          final newRatingCount = ratingCount + 1;
          final newAverageRating = totalRating / newRatingCount;

          // 更新用戶參與者評分
          await _firestore.collection('users').doc(userId).update({
            'participantRating': double.parse(newAverageRating.toStringAsFixed(1)),
            'participantRatingCount': newRatingCount,
            'updatedAt': DateTime.now().toIso8601String(),
          });

          debugPrint('參與者 $userId 評分統計更新完成: ${newAverageRating.toStringAsFixed(1)} ($newRatingCount 次評分)');
        }
      }
    } catch (e) {
      debugPrint('更新參與者評分統計失敗: $e');
      // 不拋出異常，因為這不應該阻止評分提交
    }
  }

  /// 檢查發布者是否已經評分過參與者
  Future<bool> hasOrganizerRatedParticipants({
    required String organizerId,
    required String activityId,
  }) async {
    try {
      final doc = await _firestore
          .collection('organizer_ratings')
          .doc('${organizerId}_$activityId')
          .get();

      return doc.exists;
    } catch (e) {
      debugPrint('檢查發布者評分狀態失敗: $e');
      return false;
    }
  }

  /// 檢查發布者是否應該顯示評分參與者彈窗
  Future<bool> shouldShowOrganizerRatingPopup({
    required String organizerId,
    required String activityId,
  }) async {
    try {
      // 檢查活動是否存在且由該用戶發布
      final activity = await getActivityDetail(activityId);
      if (activity == null || activity['userId'] != organizerId) {
        return false;
      }

      // 檢查活動是否已結束
      final activityStatus = activity['status'] as String?;
      final endDateTime = activity['endDateTime'] as String?;

      bool isActivityEnded = false;

      // 檢查活動是否已結束的條件：
      // 1. 活動狀態為 'ended'，或
      // 2. 活動結束時間已過
      if (activityStatus == 'ended') {
        isActivityEnded = true;
      } else if (endDateTime != null) {
        try {
          final endTime = DateTime.parse(endDateTime);
          final now = DateTime.now();
          if (now.isAfter(endTime)) {
            isActivityEnded = true;
          }
        } catch (e) {
          debugPrint('解析活動結束時間失敗: $e');
        }
      }

      if (!isActivityEnded) {
        debugPrint('活動尚未結束，不顯示評分彈窗');
        return false;
      }

      // 檢查是否已經評分過
      final hasRated = await hasOrganizerRatedParticipants(
        organizerId: organizerId,
        activityId: activityId,
      );

      if (hasRated) {
        debugPrint('發布者已經評分過參與者，不顯示評分彈窗');
        return false;
      }

      // 檢查是否有參與者
      final participants = await getActivityParticipants(activityId: activityId);
      if (participants.isEmpty) {
        debugPrint('活動沒有參與者，不顯示評分彈窗');
        return false;
      }

      debugPrint('滿足顯示發布者評分彈窗的條件');
      return true;
    } catch (e) {
      debugPrint('檢查發布者評分彈窗條件失敗: $e');
      return false;
    }
  }

  /// 獲取活動的發布者評分記錄
  Future<List<Map<String, dynamic>>> getOrganizerRatings({
    required String activityId,
    int limit = 20,
  }) async {
    try {
      debugPrint('獲取活動發布者評分列表: $activityId');

      final query = await _firestore
          .collection('organizer_ratings')
          .where('activityId', isEqualTo: activityId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final ratings = <Map<String, dynamic>>[];

      for (final doc in query.docs) {
        final ratingData = doc.data();
        
        // 獲取發布者資訊
        final organizerId = ratingData['organizerId'] as String;
        final organizerInfo = await _userService.getUserBasicInfo(organizerId);

        ratings.add({
          'id': doc.id,
          ...ratingData,
          'organizer': organizerInfo,
        });
      }

      debugPrint('獲取到 ${ratings.length} 個發布者評分記錄');
      return ratings;
    } catch (e) {
      debugPrint('獲取活動發布者評分列表失敗: $e');
      return [];
    }
  }

  /// 獲取用戶作為參與者收到的評分列表
  Future<List<Map<String, dynamic>>> getUserParticipantRatings({
    required String userId,
    int limit = 20,
  }) async {
    try {
      debugPrint('獲取用戶作為參與者收到的評分列表: $userId');

      // 查詢所有發布者評分記錄，找出評分對象包含該用戶的記錄
      final query = await _firestore
          .collection('organizer_ratings')
          .orderBy('createdAt', descending: true)
          .limit(100) // 先獲取較多記錄，然後在客戶端篩選
          .get();

      final userRatings = <Map<String, dynamic>>[];

      for (final doc in query.docs) {
        final ratingData = doc.data();
        final ratings = ratingData['ratings'] as Map<String, dynamic>? ?? {};
        
        // 檢查這個評分記錄是否包含對該用戶的評分
        if (ratings.containsKey(userId)) {
          // 獲取發布者資訊
          final organizerId = ratingData['organizerId'] as String;
          final organizerInfo = await _userService.getUserBasicInfo(organizerId);
          
          // 獲取活動資訊
          final activityId = ratingData['activityId'] as String;
          final activityInfo = await getActivityDetail(activityId);

          userRatings.add({
            'id': doc.id,
            ...ratingData,
            'organizer': organizerInfo,
            'activity': activityInfo,
            'userRating': ratings[userId], // 該用戶收到的具體評分
          });

          // 達到限制數量就停止
          if (userRatings.length >= limit) {
            break;
          }
        }
      }

      debugPrint('獲取到 ${userRatings.length} 個用戶參與者評分記錄');
      return userRatings;
    } catch (e) {
      debugPrint('獲取用戶參與者評分列表失敗: $e');
      return [];
    }
  }
}
