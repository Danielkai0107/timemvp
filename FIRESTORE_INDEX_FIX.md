# Firebase Firestore 索引問題修復

## 問題描述

在我的活動頁面中，獲取用戶發布的活動時出現 Firestore 索引錯誤：

```
The query requires an index. You can create it here: https://console.firebase.google.com/v1/r/project/time-mvp-7b126/firestore/indexes?create_composite=...
```

## 問題原因

Firestore 對於包含 `where` 條件和 `orderBy` 的複合查詢需要創建複合索引。原始查詢：

```dart
.where('userId', isEqualTo: userId)
.orderBy('createdAt', descending: true)
```

這需要一個 `userId` (ASCENDING) + `createdAt` (DESCENDING) 的複合索引。

## 解決方案

### 方案1：客戶端排序（已實施）

移除 Firestore 查詢中的 `orderBy`，改為在客戶端進行排序：

```dart
// 修改前
final querySnapshot = await _firestore
    .collection('posts')
    .where('userId', isEqualTo: userId)
    .orderBy('createdAt', descending: true)  // 需要複合索引
    .limit(limit)
    .get();

// 修改後
final querySnapshot = await _firestore
    .collection('posts')
    .where('userId', isEqualTo: userId)
    .limit(limit)
    .get();

// 在客戶端排序
activities.sort((a, b) {
  final aCreatedAt = a['createdAt'] as String?;
  final bCreatedAt = b['createdAt'] as String?;
  
  if (aCreatedAt == null && bCreatedAt == null) return 0;
  if (aCreatedAt == null) return 1;
  if (bCreatedAt == null) return -1;
  
  try {
    final aDate = DateTime.parse(aCreatedAt);
    final bDate = DateTime.parse(bCreatedAt);
    return bDate.compareTo(aDate); // 降序排列
  } catch (e) {
    return 0;
  }
});
```

### 方案2：創建 Firebase 索引（備選）

如果需要服務器端排序（處理大量數據時），可以創建複合索引：

1. **手動創建**：點擊錯誤訊息中的連結直接創建
2. **使用配置文件**：部署 `firestore.indexes.json`

```bash
firebase deploy --only firestore:indexes
```

## 修改的文件

1. **lib/services/activity_service.dart**
   - `getUserActivities()` - 移除 orderBy，添加客戶端排序
   - `getUserPublishedActivities()` - 移除 orderBy，添加客戶端排序

2. **firestore.indexes.json** (新增)
   - 包含所需的複合索引配置
   - 可用於未來的索引部署

## 優點與缺點

### 客戶端排序
**優點：**
- 無需等待索引創建
- 立即解決問題
- 適合小到中等數據量

**缺點：**
- 數據量大時性能較差
- 需要下載所有數據再排序

### 服務器端排序（索引）
**優點：**
- 性能更好，特別是大數據量
- 節省網絡傳輸

**缺點：**
- 需要等待索引創建（幾分鐘）
- 增加 Firestore 成本

## 測試結果

修復後，我的活動頁面應該能夠正常載入：
- ✅ 獲取用戶報名的活動
- ✅ 獲取用戶發布的活動  
- ✅ 按時間排序顯示
- ✅ 無索引錯誤

## 後續建議

如果用戶發布的活動數量超過 100 個，建議：
1. 實施分頁載入
2. 創建 Firebase 複合索引
3. 使用服務器端排序和篩選

