# 發布者評分參與者功能修復文檔

## 問題描述

用戶報告在活動結束後，發布者評分參與者功能無法找到參與者，顯示「活動沒有參與者，不顯示評分彈窗」的錯誤訊息。

## 問題分析

通過日誌分析發現：
```
I/flutter (12950): === 獲取活動報名者列表 ===
I/flutter (12950): 活動ID: IYi2j3uv2jAjYinmcCIA
I/flutter (12950): 找到 0 個報名記錄
I/flutter (12950): === 最終獲取到 0 個有效報名者 ===
I/flutter (12950): 活動沒有參與者，不顯示評分彈窗
```

問題的根本原因是：

1. **狀態更新機制**：當活動結束時（無論是自然結束還是提前結束），系統會將所有參與者的報名狀態從 `'registered'` 更新為 `'ended'`

2. **查詢條件不完整**：`getActivityParticipants` 方法的查詢條件只包含 `['registered', 'application_success']`，沒有包含 `'ended'` 狀態

3. **數據一致性問題**：`getActivityRegistrationCount` 方法錯誤地使用了 `registrations` 集合而不是 `user_registrations` 集合

## 修復方案

### 1. 更新參與者查詢條件

修改 `getActivityParticipants` 方法，在查詢條件中添加 `'ended'` 狀態：

```dart
// 修復前
.where('status', whereIn: ['registered', 'application_success'])

// 修復後  
.where('status', whereIn: ['registered', 'application_success', 'ended'])
```

**修復位置**：`lib/services/activity_service.dart` 第810行

### 2. 修復集合名稱不一致問題

修正 `getActivityRegistrationCount` 方法中的集合名稱：

```dart
// 修復前
.collection('registrations')

// 修復後
.collection('user_registrations')
```

**修復位置**：`lib/services/activity_service.dart` 第327行

## 修復效果

修復後，系統能夠正確處理以下場景：

1. **自然結束的活動**：活動到達預定結束時間後，參與者狀態變為 `'ended'`，發布者仍能看到並評分參與者

2. **提前結束的活動**：發布者手動提前結束活動後，參與者狀態變為 `'ended'`，發布者仍能看到並評分參與者

3. **數據一致性**：所有報名相關查詢都使用統一的 `user_registrations` 集合

## 相關功能流程

### 活動結束流程
1. 活動到達結束時間或被手動提前結束
2. 系統調用 `endActivityEarly` 方法
3. 更新活動狀態為 `'ended'`
4. 批量更新所有參與者狀態為 `'ended'`
5. 參與者和發布者都可以進行評分

### 評分彈窗顯示邏輯
1. 檢查活動是否已結束
2. 檢查是否已經評分過
3. 獲取參與者列表（現在包含 `'ended'` 狀態的參與者）
4. 如果有參與者，顯示評分彈窗

## 測試建議

1. **自然結束測試**：
   - 創建一個活動，設置較短的結束時間
   - 讓用戶報名參與
   - 等待活動自然結束
   - 檢查發布者是否能看到評分參與者功能

2. **提前結束測試**：
   - 創建一個活動並有用戶報名
   - 發布者手動提前結束活動
   - 檢查發布者是否能看到評分參與者功能

3. **狀態一致性測試**：
   - 檢查活動結束後參與者狀態是否正確更新為 `'ended'`
   - 檢查 `getActivityParticipants` 是否能正確返回已結束的參與者
   - 檢查 `getActivityRegistrationCount` 是否使用正確的集合

## 注意事項

1. **Firestore 索引**：確保 `user_registrations` 集合有正確的複合索引支持 `activityId` 和 `status` 的查詢

2. **向後兼容性**：修復不會影響現有功能，只是擴展了查詢範圍

3. **性能影響**：添加 `'ended'` 狀態到查詢條件不會顯著影響性能，因為使用了現有的複合索引

## 相關文件

- `lib/services/activity_service.dart` - 主要修復文件
- `lib/pages/activity_detail_page.dart` - 使用修復後的方法
- `lib/components/design_system/organizer_rating_popup.dart` - 評分彈窗組件
- `firestore.indexes.json` - Firestore 索引配置

## 後續改進建議

1. **統一狀態管理**：考慮創建一個統一的狀態管理類來處理所有報名狀態轉換

2. **自動化測試**：添加單元測試來確保狀態轉換的正確性

3. **監控和日誌**：增加更詳細的日誌來追蹤狀態變化過程

4. **用戶通知**：考慮在活動結束時向參與者和發布者發送評分提醒通知
