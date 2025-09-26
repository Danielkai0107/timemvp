import 'package:flutter/foundation.dart';

/// 模擬的用戶類別
class MockUser {
  final String uid;
  final String? email;
  
  MockUser({required this.uid, this.email});
}

/// 模擬的認證服務
class AuthService {
  static MockUser? _currentUser;
  
  /// 取得當前用戶
  MockUser? get currentUser => _currentUser;
  
  /// 使用電子郵件和密碼登入 (模擬)
  Future<MockUser?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    debugPrint('模擬登入: $email');
    
    // 模擬網路延遲
    await Future.delayed(const Duration(seconds: 1));
    
    // 模擬簡單驗證 (任何非空密碼都成功)
    if (email.isNotEmpty && password.isNotEmpty && email.contains('@')) {
      _currentUser = MockUser(
        uid: 'mock_user_${email.hashCode}',
        email: email,
      );
      debugPrint('模擬登入成功: ${_currentUser!.uid}');
      return _currentUser;
    } else {
      throw Exception('登入失敗：電子郵件或密碼格式錯誤');
    }
  }
  
  /// 使用電子郵件和密碼創建帳戶 (模擬)
  Future<MockUser?> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    debugPrint('模擬註冊: $email');
    
    // 模擬網路延遲
    await Future.delayed(const Duration(seconds: 2));
    
    // 模擬簡單驗證
    if (email.isNotEmpty && password.length >= 6 && email.contains('@')) {
      _currentUser = MockUser(
        uid: 'mock_user_${email.hashCode}',
        email: email,
      );
      debugPrint('模擬註冊成功: ${_currentUser!.uid}');
      return _currentUser;
    } else {
      throw Exception('註冊失敗：電子郵件格式錯誤或密碼太短');
    }
  }
  
  /// 發送重設密碼郵件 (模擬)
  Future<void> sendPasswordResetEmail({required String email}) async {
    debugPrint('模擬發送重設密碼郵件: $email');
    
    // 模擬網路延遲
    await Future.delayed(const Duration(seconds: 1));
    
    if (email.isEmpty || !email.contains('@')) {
      throw Exception('電子郵件格式錯誤');
    }
    
    debugPrint('模擬重設密碼郵件已發送');
  }
  
  /// 登出 (模擬)
  Future<void> signOut() async {
    debugPrint('模擬登出');
    
    // 模擬網路延遲
    await Future.delayed(const Duration(milliseconds: 500));
    
    _currentUser = null;
    debugPrint('模擬登出成功');
  }
}
