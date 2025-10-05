# 發布者評分參與者系統實現文檔

## 概述

本文檔描述了發布者評分參與者系統的完整實現，實現了雙向評分機制，讓活動發布者也能對參與者進行評分。

## 功能特性

### 1. 發布者評分參與者彈窗 (OrganizerRatingPopup)
- **位置**: `lib/components/design_system/organizer_rating_popup.dart`
- **功能**:
  - 從底部彈出的評分界面
  - 支持多個參與者的滾動顯示
  - 5星評分系統
  - 可選評論功能
  - 可跳過評分
  - 動畫效果
  - 頁面指示器（參與者超過5個時智能顯示）

### 2. 數據存儲
- **Firestore 集合**: `organizer_ratings`
- **文檔結構**:
  ```json
  {
    "activityId": "活動ID",
    "organizerId": "發布者ID", 
    "ratings": {
      "參與者ID": 評分數值
    },
    "comment": "評論內容",
    "createdAt": "創建時間",
    "updatedAt": "更新時間"
  }
  ```

### 3. 用戶參與者評分統計更新
- 自動更新被評分參與者的平均評分 (`participantRating`)
- 更新評分次數統計 (`participantRatingCount`)
- 保持評分歷史記錄

### 4. 雙向評分系統
- 參與者評分發布者：使用 `activity_ratings` 集合
- 發布者評分參與者：使用 `organizer_ratings` 集合
- 分別維護不同的評分統計字段

## 觸發條件

發布者評分參與者彈窗會在以下條件全部滿足時自動顯示：

1. 用戶已登入
2. 用戶是活動發布者
3. 活動已結束
4. 發布者尚未對參與者評分
5. 活動有參與者

## 核心方法

### ActivityService 新增方法

#### `submitOrganizerRating()`
發布者提交對參與者的評分到 Firestore

#### `hasOrganizerRatedParticipants()`
檢查發布者是否已評分過參與者

#### `shouldShowOrganizerRatingPopup()`
檢查是否應顯示發布者評分彈窗

#### `getOrganizerRatings()`
獲取活動的發布者評分記錄

#### `getUserParticipantRatings()`
獲取用戶作為參與者收到的評分列表

#### `_updateParticipantRatingStats()`
更新參與者評分統計

### ActivityDetailPage 新增方法

#### `_checkAndShowOrganizerRatingPopup()`
檢查並顯示發布者評分參與者彈窗

#### `_showOrganizerRatingPopup()`
顯示發布者評分參與者彈窗

#### `_handleOrganizerRatingSubmit()`
處理發布者評分提交

## UI 更新

### 活動詳情頁面底部按鈕
- **活動進行中**: 只顯示「查看報名狀況」按鈕
- **活動已結束**: 顯示「查看報名狀況」和「評分參與者」按鈕
- **草稿狀態**: 顯示「編輯」和「查看報名狀況」按鈕

### 評分參與者按鈕
- 位置：活動詳情頁面底部
- 樣式：outline 按鈕，主色調邊框
- 圖標：星星輪廓圖標
- 只在活動結束後對發布者顯示

## 使用流程

1. **活動結束**: 活動到達結束時間或被提前結束
2. **自動彈出評分**: 發布者打開活動詳情頁時自動彈出評分界面
3. **發布者評分**: 發布者可以給每個參與者評分並留下評論
4. **數據存儲**: 評分數據保存到 `organizer_ratings` 集合
5. **統計更新**: 自動更新參與者的評分統計
6. **手動評分**: 發布者也可以點擊「評分參與者」按鈕手動評分

## 技術實現細節

### 評分彈窗設計
- 使用 `SlideTransition` 和 `FadeTransition` 實現動畫效果
- 支持單個或多個參與者的評分
- 多個參與者時使用 `PageView` 實現滑動顯示
- 智能頁面指示器（超過5個參與者時只顯示當前附近的點）

### 數據一致性
- 使用文檔ID `${organizerId}_${activityId}` 確保每個發布者只能對同一活動評分一次
- 評分提交時會檢查是否已存在評分記錄

### 性能優化
- 評分數據延遲載入，不影響主要頁面載入速度
- 使用限制查詢 (limit) 控制評分列表大小
- 評分統計更新失敗不會影響評分提交

## Firestore 索引配置

新增以下索引以支持查詢：

```json
{
  "collectionGroup": "organizer_ratings",
  "queryScope": "COLLECTION",
  "fields": [
    {
      "fieldPath": "activityId",
      "order": "ASCENDING"
    },
    {
      "fieldPath": "createdAt",
      "order": "DESCENDING"
    }
  ]
}
```

## 數據結構更新

### 用戶文檔新增字段
- `participantRating`: 用戶作為參與者的平均評分
- `participantRatingCount`: 用戶作為參與者收到的評分次數

### 評分類型區分
- `rating`: 用戶作為發布者的評分（原有）
- `ratingCount`: 用戶作為發布者收到的評分次數（原有）
- `participantRating`: 用戶作為參與者的評分（新增）
- `participantRatingCount`: 用戶作為參與者收到的評分次數（新增）

## 未來擴展

1. **評分統計頁面**: 顯示用戶的雙向評分統計
2. **評分篩選**: 可以按評分等級篩選參與者
3. **評分回覆**: 參與者可以回覆發布者的評分
4. **評分提醒**: 活動結束後推送評分提醒
5. **匿名評分**: 支持匿名評分選項
6. **評分報告**: 為發布者提供參與者評分報告

## 注意事項

1. 發布者評分彈窗會在參與者評分彈窗之後延遲顯示（2.5秒），避免衝突
2. 評分數據存儲在獨立的 `organizer_ratings` 集合中，便於管理和查詢
3. 參與者評分統計更新是異步進行的，不會阻塞評分提交
4. 只有活動結束後發布者才能評分參與者
5. 每個發布者對每個活動只能評分一次

## 測試建議

1. 測試發布者評分彈窗的顯示條件
2. 測試多個參與者的滑動顯示和頁面指示器
3. 測試評分數據的正確存儲
4. 測試參與者評分統計的更新
5. 測試重複評分的防護機制
6. 測試活動結束後的按鈕顯示
7. 測試手動點擊評分按鈕的功能
