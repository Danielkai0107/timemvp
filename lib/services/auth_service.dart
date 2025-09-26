import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 用戶類別封裝Firebase User
class AuthUser {
  final String uid;
  final String? email;
  
  AuthUser({required this.uid, this.email});
}

/// Firebase認證服務
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  AuthUser? _currentUser;
  
  /// 取得當前用戶
  AuthUser? get currentUser {
    // 如果 _currentUser 為 null，檢查 Firebase Auth 的當前用戶
    if (_currentUser == null && _auth.currentUser != null) {
      _currentUser = AuthUser(
        uid: _auth.currentUser!.uid,
        email: _auth.currentUser!.email,
      );
    }
    return _currentUser;
  }
  
  /// 初始化當前用戶狀態
  void initializeCurrentUser() {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      _currentUser = AuthUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email,
      );
      debugPrint('已初始化當前用戶: ${_currentUser!.uid}');
    } else {
      _currentUser = null;
      debugPrint('當前沒有用戶登入');
    }
  }
  
  /// 使用電子郵件和密碼登入
  Future<AuthUser?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('Firebase登入: $email');
      
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (result.user != null) {
        _currentUser = AuthUser(
          uid: result.user!.uid,
          email: result.user!.email,
        );
        debugPrint('Firebase登入成功: ${_currentUser!.uid}');
        return _currentUser;
      } else {
        throw Exception('登入失敗：無法獲取用戶資訊');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'wrong-password':
          errorMessage = '密碼錯誤';
          break;
        case 'user-not-found':
          errorMessage = '找不到此用戶帳號';
          break;
        case 'user-disabled':
          errorMessage = '此帳號已被停用';
          break;
        case 'invalid-email':
          errorMessage = '電子郵件格式錯誤';
          break;
        case 'too-many-requests':
          errorMessage = '嘗試次數過多，請稍後再試';
          break;
        default:
          errorMessage = '登入失敗：${e.message}';
      }
      throw Exception(errorMessage);
    }
  }
  
  /// 使用電子郵件和密碼創建帳戶
  Future<AuthUser?> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('Firebase註冊: $email');
      
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (result.user != null) {
        _currentUser = AuthUser(
          uid: result.user!.uid,
          email: result.user!.email,
        );
        debugPrint('Firebase註冊成功: ${_currentUser!.uid}');
        return _currentUser;
      } else {
        throw Exception('註冊失敗：無法創建用戶');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = '此電子郵件已被註冊';
          break;
        case 'weak-password':
          errorMessage = '密碼強度不足，請使用至少6個字符';
          break;
        case 'invalid-email':
          errorMessage = '電子郵件格式錯誤';
          break;
        default:
          errorMessage = '註冊失敗：${e.message}';
      }
      throw Exception(errorMessage);
    }
  }
  
  /// 檢查電子郵件是否已被註冊
  /// 由於 Firebase 安全設置不允許檢查電子郵件存在性，暫時禁用此功能
  Future<bool> isEmailAlreadyInUse({required String email}) async {
    debugPrint('==========================================');
    debugPrint('電子郵件檢查功能已禁用');
    debugPrint('原因：Firebase 安全設置不允許檢查電子郵件存在性');
    debugPrint('建議：在實際註冊時處理 email-already-in-use 錯誤');
    debugPrint('電子郵件: $email - 假設可用');
    debugPrint('==========================================');
    
    // 始終返回 false，表示電子郵件可用
    // 實際的重複檢查將在註冊時由 Firebase 處理
    return false;
  }

  /// 發送重設密碼郵件
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      debugPrint('發送重設密碼郵件: $email');
      
      await _auth.sendPasswordResetEmail(email: email);
      
      debugPrint('重設密碼郵件已發送');
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = '找不到此電子郵件帳號';
          break;
        case 'invalid-email':
          errorMessage = '電子郵件格式錯誤';
          break;
        case 'too-many-requests':
          errorMessage = '要求次數過多，請稍後再試';
          break;
        default:
          errorMessage = '發送失敗：${e.message}';
      }
      throw Exception(errorMessage);
    }
  }
  
  /// 登出
  Future<void> signOut() async {
    try {
      debugPrint('Firebase登出');
      
      await _auth.signOut();
      
      _currentUser = null;
      debugPrint('登出成功');
    } on FirebaseAuthException catch (e) {
      debugPrint('登出錯誤：${e.message}');
      throw Exception('登出失敗：${e.message}');
    }
  }
}
