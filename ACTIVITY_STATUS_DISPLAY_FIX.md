# 活動詳情頁狀態顯示修復文檔

## 問題描述

用戶報告在報名者視角下，活動明明已經結束但是活動詳情頁的狀態沒有更新，仍然顯示為「報名成功」而不是「已結束」。

## 問題分析

通過代碼分析發現問題出現在活動詳情頁面的狀態顯示邏輯：

### 原有問題

1. **狀態判斷過於簡化**：
   ```dart
   // 原有邏輯
   if (_isRegistered) {
     return ActivityStatus.registrationSuccess; // 總是返回報名成功
   }
   ```

2. **缺少詳細報名狀態**：
   - 只檢查是否報名（`_isRegistered`），但沒有獲取具體的報名狀態
   - 沒有考慮報名狀態可能已經更新為 `'ended'`

3. **沒有綜合考慮活動結束條件**：
   - 沒有檢查活動狀態是否為 `'ended'`
   - 沒有檢查活動是否超過結束時間
   - 沒有檢查報名狀態是否為 `'ended'`

## 修復方案

### 1. 在 ActivityService 中新增方法

新增 `getUserRegistrationStatus` 方法來獲取用戶的詳細報名狀態：

```dart
Future<Map<String, dynamic>?> getUserRegistrationStatus({
  required String userId,
  required String activityId,
}) async {
  // 獲取完整的報名記錄，包含狀態信息
}
```

**功能特點**：
- 返回完整的報名記錄數據
- 包含詳細的狀態信息（如 `'registered'`, `'ended'`, `'cancelled'` 等）
- 提供詳細的調試日誌

### 2. 更新活動詳情頁面的狀態檢查邏輯

#### 2.1 添加詳細報名狀態字段

```dart
String? _registrationStatus; // 詳細的報名狀態
```

#### 2.2 更新報名狀態檢查方法

修改 `_checkRegistrationStatus` 方法：
- 使用新的 `getUserRegistrationStatus` 方法
- 獲取並保存詳細的報名狀態
- 提供更詳細的調試信息

#### 2.3 重寫活動狀態判斷邏輯

完全重寫 `_getActivityStatus` 方法：

```dart
ActivityStatus? _getActivityStatus() {
  // 1. 發布者視角：使用活動狀態
  if (_isMyActivity) {
    return ActivityStatusUtils.fromString(status, activityType, draftReason: draftReason);
  }
  
  // 2. 報名者視角：綜合考慮多種結束條件
  if (_isRegistered && _registrationStatus != null) {
    bool isActivityEnded = false;
    
    // 檢查活動狀態是否為 ended
    if (activityStatus == 'ended') {
      isActivityEnded = true;
    }
    
    // 檢查報名狀態是否為 ended
    if (_registrationStatus == 'ended') {
      isActivityEnded = true;
    }
    
    // 檢查是否超過活動結束時間
    if (!isActivityEnded && endDateTime != null) {
      final endTime = DateTime.parse(endDateTime);
      isActivityEnded = DateTime.now().isAfter(endTime);
    }
    
    // 根據結束狀態決定顯示
    if (isActivityEnded) {
      return ActivityStatus.ended;
    }
    
    return ActivityStatusUtils.fromString(_registrationStatus!, activityType);
  }
  
  return null;
}
```

## 修復效果

修復後，系統能夠正確處理以下場景：

### 1. 自然結束的活動
- **場景**：活動到達預定結束時間
- **修復前**：報名者看到「報名成功」
- **修復後**：報名者看到「已結束」

### 2. 提前結束的活動
- **場景**：發布者手動提前結束活動，報名者狀態更新為 `'ended'`
- **修復前**：報名者看到「報名成功」
- **修復後**：報名者看到「已結束」

### 3. 活動狀態更新
- **場景**：活動狀態直接更新為 `'ended'`
- **修復前**：報名者看到「報名成功」
- **修復後**：報名者看到「已結束」

### 4. 多重檢查機制
- 同時檢查活動狀態、報名狀態和結束時間
- 任一條件滿足都會正確顯示「已結束」
- 提供更準確的狀態反映

## 狀態顯示邏輯

### 發布者視角
- 使用活動本身的狀態
- 顯示：草稿、已發布、已結束、已取消等

### 報名者視角
- 綜合考慮活動狀態和報名狀態
- 優先顯示「已結束」（如果活動已結束）
- 其次顯示報名狀態（報名成功、待審核等）

### 未報名用戶
- 不顯示狀態標籤
- 保持簡潔的界面

## 調試改進

### 新增調試日誌
```dart
debugPrint('報名狀態詳情: $_registrationStatus');
debugPrint('活動狀態: $activityStatus');
debugPrint('活動是否已結束: $isActivityEnded');
```

### 狀態檢查流程
1. 獲取詳細報名狀態
2. 檢查活動狀態
3. 檢查報名狀態
4. 檢查結束時間
5. 綜合判斷並顯示正確狀態

## 相關文件

- `lib/services/activity_service.dart` - 新增 `getUserRegistrationStatus` 方法
- `lib/pages/activity_detail_page.dart` - 更新狀態檢查和顯示邏輯
- `lib/components/design_system/activity_status_badge.dart` - 狀態標籤組件

## 測試建議

### 1. 自然結束測試
- 創建一個即將結束的活動
- 用戶報名參與
- 等待活動自然結束
- 檢查報名者視角的狀態顯示

### 2. 提前結束測試
- 創建一個活動並有用戶報名
- 發布者手動提前結束活動
- 檢查報名者視角的狀態顯示

### 3. 狀態同步測試
- 檢查活動結束後狀態是否及時更新
- 檢查不同用戶角色的狀態顯示是否正確
- 檢查頁面刷新後狀態是否保持正確

### 4. 邊界情況測試
- 活動剛好結束的時間點
- 網絡延遲情況下的狀態更新
- 多個用戶同時查看的狀態一致性

## 注意事項

1. **向後兼容性**：修復不會影響現有功能，只是改進了狀態顯示邏輯

2. **性能影響**：新增的狀態檢查不會顯著影響性能，因為只是在現有的數據載入流程中增加了狀態解析

3. **數據一致性**：確保活動狀態和報名狀態的更新是同步的

4. **用戶體驗**：提供更準確的狀態反映，讓用戶清楚了解活動的當前狀態

## 後續改進建議

1. **實時狀態更新**：考慮使用 Firestore 實時監聽來自動更新狀態

2. **狀態變更通知**：在狀態變更時向用戶發送通知

3. **統一狀態管理**：創建一個統一的狀態管理系統來處理所有狀態邏輯

4. **自動化測試**：添加單元測試來確保狀態邏輯的正確性
