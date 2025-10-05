# 動態分類系統實作說明

## 概述

本次更新將原本硬編碼的分類系統改為從後端 Firestore 動態讀取，方便日後從後台管理分類。

## 主要變更

### 1. 新增 CategoryService (`lib/services/category_service.dart`)

- 管理分類的 CRUD 操作
- 支持緩存機制，提升性能
- 區分活動類型 (`event`) 和任務類型 (`task`)
- 提供預設分類作為備用

### 2. 更新 CategoryTabs 組件 (`lib/components/category_tabs.dart`)

- 支持動態載入分類數據
- 根據活動類型顯示對應分類
- 新增載入狀態和錯誤處理
- 回調函數現在提供 `CategoryTabData` 物件

### 3. 更新首頁 (`lib/pages/home.dart`)

- 使用新的 CategoryTabs 組件
- 根據選中的分類篩選活動
- 支持活動/任務類型切換時的分類更新

### 4. 更新創建活動頁面 (`lib/pages/create_activity_page.dart`)

- 根據選擇的發布類型（單辦活動/找幫手）載入對應分類
- 動態更新分類下拉選單
- 添加分類載入狀態指示器

### 5. 更新我的活動頁面 (`lib/pages/my_activities_page.dart`)

- 分類下拉選單顯示格式：`活動 - 技能培養`、`任務 - 生活服務`
- 支持動態分類數據
- 提供預設分類作為備用

## 資料庫結構

### Firestore 集合：`categories`

```javascript
{
  // 文檔 ID (例如: EventCategory_language_teaching)
  "name": "EventCategory_language_teaching",     // 分類名稱（用於程式邏輯）
  "displayName": "語言教學",                      // 顯示名稱（用於 UI）
  "type": "event",                              // 類型：'event' 或 'task'
  "sortOrder": 1,                               // 排序順序
  "isActive": true,                             // 是否啟用
  "createdAt": "2025-01-01T00:00:00.000Z",     // 創建時間
  "updatedAt": "2025-01-01T00:00:00.000Z"      // 更新時間
}
```

## 初始化分類數據

### 方法一：使用 Firebase Console

1. 打開 Firebase Console
2. 進入 Firestore Database
3. 創建 `categories` 集合
4. 參考 `initialize_categories.js` 中的數據結構添加文檔

### 方法二：使用 Firebase Admin SDK

```bash
node initialize_categories.js
```

### 方法三：在 App 中初始化（僅用於開發）

```dart
// 在開發環境中可以調用此方法初始化分類
await CategoryService().initializeDefaultCategories();
```

## 預設分類

### 活動類型 (event)
- 語言教學 (`EventCategory_language_teaching`)
- 技能體驗 (`EventCategory_skill_experience`)
- 活動支援 (`EventCategory_event_support`)
- 生活服務 (`EventCategory_life_service`)

### 任務類型 (task)
- 活動支援 (`TaskCategory_event_support`)
- 生活服務 (`TaskCategory_life_service`)
- 技能分享 (`TaskCategory_skill_sharing`)
- 創意工作 (`TaskCategory_creative_work`)

## 使用方式

### 獲取分類

```dart
final categoryService = CategoryService();

// 獲取所有分類
final allCategories = await categoryService.getAllCategories();

// 獲取活動類型分類
final eventCategories = await categoryService.getEventCategories();

// 獲取任務類型分類
final taskCategories = await categoryService.getTaskCategories();

// 根據名稱獲取分類
final category = await categoryService.getCategoryByName('EventCategory_language_teaching');
```

### 使用 CategoryTabs 組件

```dart
CategoryTabs(
  activityType: 'event', // 'event', 'task', 或 'all'
  initialIndex: 0,
  showAllTab: true,
  onTabChanged: (index, categoryData) {
    // categoryData 包含選中的分類信息
    print('選中分類: ${categoryData?.displayName}');
  },
)
```

## 緩存機制

- CategoryService 實現了 30 分鐘的緩存機制
- 可以通過 `forceRefresh: true` 強制重新載入
- 使用 `clearCache()` 清除緩存

## 數據載入優先級

### 優先級順序
1. **Firebase 實時數據** - 優先從 Firestore 獲取最新分類
2. **緩存數據** - 如果 Firebase 失敗但有緩存，使用緩存數據
3. **備用數據** - 只有在 Firebase 和緩存都失敗時才使用預設分類

### 錯誤處理策略

- **Firebase 連接失敗**: 使用緩存數據（如果可用）
- **沒有緩存數據**: 使用預設分類並顯示警告
- **完全失敗**: 顯示錯誤訊息，只顯示"全部"選項

### 確保後台更新生效

- App 會優先嘗試從 Firebase 獲取最新數據
- 只有在網路完全無法連接時才使用備用數據
- 用戶可以通過下拉刷新重新載入 Firebase 數據
- 緊急情況下可以調用 `forceRefreshFromFirebase()` 強制更新

## 後台管理建議

未來可以在後台管理系統中：

1. 新增/編輯/刪除分類
2. 調整分類排序
3. 啟用/停用分類
4. 管理分類的多語言支持

## 注意事項

1. 分類的 `name` 欄位用於程式邏輯，不應隨意更改
2. `displayName` 欄位用於 UI 顯示，可以自由修改
3. 刪除分類前請確保沒有活動使用該分類
4. 建議在正式環境中設置適當的 Firestore 安全規則
