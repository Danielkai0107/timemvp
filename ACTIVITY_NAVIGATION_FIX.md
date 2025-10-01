# 活動卡片導航修復

## 問題描述
在「我的活動」頁面中，點擊活動卡片無法成功開啟活動詳情頁面。

## 問題原因
活動卡片點擊處理函數 `_onActivityTap()` 中的導航代碼被註釋掉了，只有調試輸出。

## 修復內容

### 1. 添加必要的導入
```dart
import 'activity_detail_page.dart';
```

### 2. 實現完整的導航邏輯
```dart
void _onActivityTap(Map<String, dynamic> activityData, bool isRegistered) {
  // 獲取活動ID和數據
  String? activityId;
  Map<String, dynamic>? activity;
  
  if (isRegistered) {
    // 報名的活動：從 registration 數據中獲取
    activityId = activityData['activity']?['id'] as String?;
    activity = activityData['activity'] as Map<String, dynamic>?;
  } else {
    // 發布的活動：直接從活動數據獲取
    activityId = activityData['id'] as String?;
    activity = activityData;
  }
  
  if (activityId != null) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ActivityDetailPage(
          activityId: activityId!,
          activityData: activity,
        ),
      ),
    );
  } else {
    // 錯誤處理
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('無法打開活動詳情'),
        backgroundColor: AppColors.error900,
      ),
    );
  }
}
```

### 3. 改善操作選單
- 將「查看報名詳情」改為「查看活動詳情」
- 為發布的活動也添加「查看活動詳情」選項
- 統一使用 `_onActivityTap()` 進行導航

## 數據結構處理

### 報名的活動數據結構
```json
{
  "registration": {
    "id": "userId_activityId",
    "userId": "...",
    "activityId": "...",
    "status": "registered"
  },
  "activity": {
    "id": "activityId",
    "name": "活動名稱",
    "..."
  }
}
```

### 發布的活動數據結構
```json
{
  "id": "activityId",
  "name": "活動名稱",
  "userId": "...",
  "displayStatus": "published",
  "..."
}
```

## 測試場景

### ✅ 應該能正常工作的場景
1. **點擊報名活動卡片** → 導航到活動詳情頁面
2. **點擊發布活動卡片** → 導航到活動詳情頁面
3. **點擊狀態標籤 → 查看活動詳情** → 導航到活動詳情頁面
4. **數據異常時** → 顯示錯誤提示

### 🔍 驗證方法
1. 在「我的活動」頁面切換到「我報名的」分頁
2. 點擊任一活動卡片
3. 應該成功導航到活動詳情頁面
4. 返回後切換到「我發布的」分頁
5. 點擊任一活動卡片
6. 應該成功導航到活動詳情頁面

## 錯誤處理
- 當無法獲取活動ID時，顯示錯誤提示
- 使用 SnackBar 提供用戶友好的錯誤信息
- 調試輸出幫助開發時排查問題

## 相關文件
- `/lib/pages/my_activities_page.dart` - 修復導航邏輯
- `/lib/pages/activity_detail_page.dart` - 目標詳情頁面
- `/lib/components/my_activity_card.dart` - 活動卡片組件
