# 帳號註銷功能測試文檔

## 功能概述
當用戶註銷帳號時，系統會自動清除以下所有相關數據：

### 1. 用戶基本數據
- Firestore `users` 集合中的用戶文檔
- Firebase Storage 中 `users/{uid}/` 路徑下的所有文件（頭像、KYC文件等）

### 2. 用戶發布的活動
- Firestore `posts` 集合中所有 `userId` 等於該用戶的活動文檔
- Firebase Storage 中 `activity/{uid}/` 路徑下的所有活動圖片文件
- Firebase Storage 中 `activities/{activityId}/` 路徑下的活動相關文件

### 3. 用戶報名記錄
- Firestore `user_registrations` 集合中所有 `userId` 等於該用戶的報名記錄

### 4. Firebase Authentication 帳號
- Firebase Authentication 中的用戶帳號

## 實現細節

### ActivityService 新增方法：
1. `deleteUserActivities(String userId)` - 刪除用戶發布的所有活動
2. `deleteUserRegistrations(String userId)` - 刪除用戶的所有報名記錄
3. `deleteAllUserActivityData(String userId)` - 統一刪除用戶的所有活動相關數據
4. `_deleteUserActivityStorageFiles(String userId, List<String> activityIds)` - 刪除活動相關的 Storage 文件

### UserService 更新：
- `deleteUserData(String uid)` 方法現在會調用 `ActivityService.deleteAllUserActivityData()` 來清除活動相關數據

## 註銷流程
1. 用戶在個人資料頁面點擊「註銷帳號」
2. 輸入密碼進行身份驗證
3. 系統執行以下步驟：
   - 重新驗證用戶身份
   - 刪除用戶數據（包括活動和報名記錄）
   - 刪除 Firebase Authentication 帳號
4. 導向登入頁面

## 安全特性
- 需要密碼重新驗證才能執行註銷
- 所有刪除操作都有錯誤處理，即使部分操作失敗也不會影響其他操作
- 使用批量操作提高效率和一致性
- 並行執行刪除操作以提高性能

## 測試建議
1. 創建測試帳號並發布幾個活動
2. 報名其他用戶的活動
3. 執行帳號註銷
4. 驗證所有相關數據都已被清除：
   - 檢查 Firestore 中的 `users`、`posts`、`user_registrations` 集合
   - 檢查 Firebase Storage 中的用戶文件夾
   - 確認無法再登入該帳號
