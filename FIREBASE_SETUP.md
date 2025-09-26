# Firebase 設置指南

## 已完成的更改

✅ **依賴項已加入 pubspec.yaml**
- firebase_core: ^3.6.0
- firebase_auth: ^5.3.1  
- cloud_firestore: ^5.4.3
- firebase_storage: ^12.3.2
- path_provider: ^2.1.4

✅ **已更新的服務類別**
- `lib/services/auth_service.dart` - 使用真正的 Firebase 認證
- `lib/services/user_service.dart` - 使用真正的 Firestore 和 Storage  
- `lib/services/firestore_test.dart` - 使用真正的 Firestore
- `lib/main.dart` - 初始化 Firebase

## 註冊功能
- 註冊資料會存到Firestore (`users/{uid}` collection)
- 註冊圖片會存到 Storage (`users/{uid}/{folderName}/` structure)
- 支援個人帳戶和企業帳戶的不同文件上傳

## 登入功能  
- 使用Firebase Authentication的email/password登入
- 包含完整的錯誤處理（密碼錯誤、用戶不存在等）
- 支援重設密碼功能

## 需要做的 Firebase Console 配置

1. **創建 Firebase 專案**
   - 前往 [Firebase Console](https://console.firebase.google.com)
   - 創建新專案或使用現有專案

2. **設置Authentication**  
   - 在 Firebase Console 中前往 Authentication
   - 啟用 "Email/Password" 簽入方法
   - （選用）啟用重設密碼功能

3. **設置Firestore Database**
   - 前往 Firestore Database
   - 創建數據庫（生產模式或測試模式）
   - 設置適當的安全規則

4. **設置Firebase Storage**
   - 前往 Storage  
   - 開啟 Storage
   - 設置適當的安全規則

5. **下載配置文件**
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`
   - Web: Firebase Web App 配置

## Security Rules 範例

### Firestore Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 用戶可以讀寫自己的文檔
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    // 測試文檔允許寫入
    match /test/{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Storage Rules  
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## 已實現的功能

### 認證功能
- ✅ Firebase Authentication 登入/註冊
- ✅ Email/Password 認證
- ✅ 錯誤處理和中文訊息
- ✅ 密碼重設功能

### 註冊功能
- ✅ 個人帳戶註冊（基本資料 + 相片上傳）
- ✅ 企業帳戶註冊（聯絡人 + 企業資料 + 文件上傳）
- ✅ 相片/文件上傳到 Firebase Storage
- ✅ 用戶資料存儲到 Firestore
- ✅ 註冊圖片整理（profile_images, business_registration, id_card 等）

### 登入功能  
- ✅ Firebase Authentication 整合
- ✅ 自動檢測用戶狀態
- ✅ 登入/登出狀態管理

所有功能現在都已經整合善寒真正的 Firebase 服務！
