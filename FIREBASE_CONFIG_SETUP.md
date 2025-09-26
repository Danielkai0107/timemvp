# Firebase 配置修復指南

## 🔥 問題原因
目前出現 `PlatformException` 錯誤是因為缺少 Firebase Android 配置檔案。

## 📋 解決步驟

### 第1步：創建Firebase專案 (如果還沒有)

1. 前往 [Firebase Console](https://console.firebase.google.com/)
2. 點擊 "創建專案" 或 "Add Project"
3. 輸入專案名稱（例如："TimemMVP"）
4. 啟用Google Analytics（推薦）
5. 完成專案創建

### 第2步：添加Android App到Firebase

1. 在Firebase Console中找到你的專案
2. 點擊 **⚙️ 專案符號** → "專案設定"
3. 進入 **"您的應用程式"** 標籤
4. 點擊 **Android圖示** 來添加Android應用

### 第3步：配置Android應用

填入以下資訊：
```
預設的Android套件名稱：time.mvp
應用程式暱稱：TimemMVP 或任何你喜歡的名稱
SHA-1證書指紋:(現在可以先跳過，使用debug模式)
```

- 套件名稱應該對應 `android/app/build.gradle.kts` 中的 `applicationId = "time.mvp"`
- 點擊 **"註冊應用程式"**

### 第4步：下載google-services.json

1. **下載 `google-services.json`檔案**
2. 將此檔案**精確放在**：`android/app/google-services.json`

⚠️ **重要：** 確保檔案名稱完全是 `google-services.json` (包含破折號，不是底線)

### 第5步：驗證Firebase服務設定

在Firebase Console的專案慨設置中：

1. 前往 **Authentication** → 點擊 **Get started** 
   - 在 "Sign-in method" 中啟用 **Email/Password**
   
2. 前往 **Firestore Database** → 創建數據庫
   - 選擇模式：**測試模式** (為開發)或**生產模式** (為部署)
   
3. 前往 **Storage** → 開始使用
   - 接受《Firebase 服務條款》
   - 選擇 Storage 位置

### 第6步：設置安全規則 (Firestore)

在 **Firestore Database** → **規則** 標籤頁，貼上此規則：

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 用戶可以讀寫自己的文檔
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    // 測試文檔允許所有認證用戶讀寫
    match /test/{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

點擊 **發布** 保存規則。

### 第7步：設置安全規則 (Storage)

在 **Storage** → **規則** 標籤頁，貼上此規則：

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

點擊 **發布** 保存規則。

## ✅ 完成驗證

確保你的項目結構如下：
```
android/
├── app/
│   ├── google-services.json    ← 重要！
│   └── build.gradle.kts
└── build.gradle.kts
```

重啟應用程式後，錯誤應該消失！
