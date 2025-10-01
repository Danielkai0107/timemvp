# 活動詳情頁面資料結構修復總結

## 問題描述
活動詳情頁面無法正確顯示從 Firebase 獲取的資料，原因是欄位名稱對應不正確。

## 發布活動時的資料結構
```javascript
{
  // 基本資訊
  'name': '活動名稱',
  'type': 'event' | 'group',
  'status': 'active',
  'category': '活動類別key',
  
  // 時間資訊
  'startDateTime': 'ISO8601格式',
  'endDateTime': 'ISO8601格式',
  
  // 價格和人數
  'price': 整數價格,
  'seats': 人數(-1表示不限),
  
  // 地點資訊
  'address': '完整地址',
  'city': '城市',
  'area': '區域',
  'latitude': 緯度,
  'longitude': 經度,
  'isOnline': 是否線上活動,
  
  // 內容資訊
  'introduction': '活動介紹文字',
  'youtubeUrl': 'YouTube連結(可選)',
  'remark': '備註(可選)',
  
  // 系統資訊
  'userId': 'Firebase UID',
  'cover': '封面圖片URL',
  'files': [圖片檔案陣列],
  'user': {用戶資訊物件},
  'createdAt': '創建時間',
  'updatedAt': '更新時間',
  'isProfitActivity': 是否營利活動
}
```

## 修復的欄位對應問題

### 1. 人數欄位
- **錯誤**: 使用 `maxParticipants` 和 `currentParticipants`
- **正確**: 使用 `seats`，-1 表示不限人數
- **修復**: 更新 `_buildParticipantInfo()` 方法

### 2. 活動介紹欄位
- **錯誤**: 使用 `description`
- **正確**: 使用 `introduction`
- **修復**: 更新 `_buildDescription()` 方法，並添加 YouTube 影片顯示

### 3. 地點欄位
- **錯誤**: 僅使用 `locationName` 或 `address`
- **正確**: 根據 `isOnline` 判斷，使用 `city`、`area`、`address`
- **修復**: 更新 `_buildLocation()` 方法，支援線上/實體活動區別

### 4. 價格顯示
- **錯誤**: 0元顯示免費
- **正確**: 小於50元顯示免費（與發布邏輯一致）
- **修復**: 更新 `_formatPrice()` 方法

### 5. 用戶匹配邏輯
- **錯誤**: 使用臨時數字ID
- **正確**: 使用 Firebase UID
- **修復**: 更新 `_checkIfMyActivity()` 和相關 ActivityService 方法

## 新增功能

### 1. YouTube 影片顯示
- 在活動介紹中顯示 YouTube 影片預覽
- 當 `youtubeUrl` 不為空時顯示播放器佔位符

### 2. 線上活動支援
- 根據 `isOnline` 欄位顯示不同的地點圖示
- 線上活動顯示 "線上活動"，實體活動顯示地址

### 3. 改善資料獲取
- 總是從 Firebase 獲取最新資料
- 增強錯誤處理和調試日誌
- 正確的用戶身份驗證

## 修改的檔案

### 1. `/lib/pages/activity_detail_page.dart`
- 修復所有欄位對應問題
- 添加 YouTube 影片顯示
- 改善地點和人數顯示
- 修復用戶匹配邏輯

### 2. `/lib/pages/home.dart`
- 更新價格顯示邏輯
- 添加地點文字獲取方法
- 確保與詳情頁面邏輯一致

### 3. `/lib/services/activity_service.dart`
- 修復用戶ID存儲（使用Firebase UID）
- 更新查詢邏輯
- 增強調試日誌

## 測試驗證
- ✅ Flutter 語法檢查通過
- ✅ 所有欄位對應正確
- ✅ 用戶匹配邏輯正確
- ✅ 價格顯示邏輯一致
- ✅ 支援線上/實體活動區別

## 使用說明
1. 點擊首頁活動卡片進入詳情頁面
2. 詳情頁面會從 Firebase 獲取最新資料
3. 根據活動發布者顯示不同按鈕：
   - 我的活動：「查看報名狀況」
   - 其他活動：「費用 + 立即報名」

所有修復已完成，活動詳情頁面現在能正確顯示完整的活動資訊！
