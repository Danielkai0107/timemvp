# 我的活動頁面篩選功能實現

## 功能概述

在「我的活動」頁面的分頁導航下方新增了篩選區域，包含左側的狀態篩選和右側的類別篩選，讓用戶能夠快速找到特定的活動。

## 新增功能

### 1. 篩選UI設計

**位置**: 分頁導航下方，活動列表上方

**佈局**:
```
[狀態篩選下拉選單] [類別篩選下拉選單] [重置按鈕]
```

**設計特色**:
- 使用設計系統的 `CustomDropdown` 組件
- 響應式佈局，兩個下拉選單等寬
- 當有篩選條件時顯示重置按鈕
- 統一的視覺風格和交互體驗

### 2. 狀態篩選

#### 我報名的活動狀態選項
- 全部狀態
- 報名成功 (event)
- 應徵確認中 (task)  
- 應徵成功 (task)
- 已結束
- 已取消

#### 我發布的活動狀態選項
- 全部狀態
- 活動發布中 (event)
- 招募中 (task)
- 已結束
- 已取消

**智能切換**: 根據當前分頁自動顯示對應的狀態選項

### 3. 類別篩選

**通用類別選項**:
- 全部類別
- 運動健身
- 美食
- 旅遊
- 學習成長
- 娛樂
- 社交
- 志工服務
- 商業
- 藝術文化
- 科技

### 4. 篩選邏輯

#### 狀態篩選邏輯
```dart
// 報名活動：從 registration.status 獲取狀態
final statusString = registration['status'] as String? ?? 'registered';
final activityType = activity['type'] as String? ?? 'event';
final status = ActivityStatusUtils.fromString(statusString, activityType);

// 發布活動：從 displayStatus 獲取狀態
final statusString = activityData['displayStatus'] as String? ?? 'published';
final activityType = activityData['type'] as String? ?? 'event';
final status = ActivityStatusUtils.fromString(statusString, activityType);
```

#### 類別篩選邏輯
```dart
// 從活動數據中獲取類別
final category = activity['category'] as String?;
if (category != _selectedCategory) {
  return false; // 不符合篩選條件
}
```

### 5. 用戶體驗優化

#### 智能空狀態顯示
- **無篩選時**: 顯示「尚未報名任何活動」或「尚未發布任何活動」
- **有篩選時**: 顯示「沒有符合條件的活動」並提供清除篩選按鈕

#### 重置功能
- **顯示條件**: 當任一篩選條件被設置時
- **重置按鈕**: 圓形圖標按鈕，點擊清除所有篩選
- **一鍵清除**: 空狀態頁面的「清除篩選」按鈕

#### 即時篩選
- 選擇篩選條件後立即應用
- 無需額外的確認步驟
- 流暢的用戶體驗

## 技術實現

### 狀態管理
```dart
// 篩選狀態變數
String? _selectedRegisteredStatus;  // 報名活動狀態篩選
String? _selectedPublishedStatus;   // 發布活動狀態篩選  
String? _selectedCategory;          // 類別篩選

// 篩選後的數據
List<Map<String, dynamic>> _filteredRegisteredActivities = [];
List<Map<String, dynamic>> _filteredPublishedActivities = [];
```

### 核心方法
- `_applyFilters()` - 應用篩選邏輯
- `_resetFilters()` - 重置所有篩選條件
- `_buildFilterSection()` - 建構篩選UI
- `_getRegisteredStatusOptions()` - 獲取報名活動狀態選項
- `_getPublishedStatusOptions()` - 獲取發布活動狀態選項
- `_getCategoryOptions()` - 獲取類別選項

### 數據流程
1. **載入數據** → 獲取原始活動列表
2. **應用篩選** → 根據篩選條件過濾數據
3. **更新UI** → 顯示篩選後的結果
4. **用戶互動** → 修改篩選條件觸發重新篩選

## 使用場景

### 🎯 典型使用流程

1. **進入我的活動頁面** → 顯示所有活動
2. **選擇狀態篩選** → 例如「報名成功」
3. **選擇類別篩選** → 例如「運動健身」  
4. **查看篩選結果** → 只顯示符合條件的活動
5. **重置篩選** → 點擊重置按鈕回到全部活動

### 📱 響應式設計

- **手機端**: 兩個下拉選單並排顯示
- **平板端**: 保持相同佈局，利用更大空間
- **觸控友好**: 適當的點擊區域和間距

## 擴展性

### 未來可擴展功能
1. **時間範圍篩選** - 按活動日期篩選
2. **價格範圍篩選** - 按活動價格篩選
3. **地點篩選** - 按活動地點篩選
4. **排序功能** - 按時間、價格、熱度排序
5. **搜索功能** - 關鍵字搜索活動名稱
6. **篩選記憶** - 記住用戶的篩選偏好

### 性能優化
- 客戶端篩選適合中小型數據集
- 大數據量時可考慮服務器端篩選
- 虛擬化列表支持大量活動顯示

## 相關文件

- `/lib/pages/my_activities_page.dart` - 主要實現文件
- `/lib/components/design_system/custom_dropdown.dart` - 下拉選單組件
- `/lib/components/design_system/activity_status_badge.dart` - 狀態管理
- `/lib/components/my_activity_card.dart` - 活動卡片組件

