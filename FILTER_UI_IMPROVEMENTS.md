# 篩選UI改進實現

## 修改概述

根據用戶需求對我的活動頁面的篩選功能進行了以下改進：

## 主要修改

### 1. 下拉選單設計改進

#### 移除標籤 (Label)
- **修改前**: 下拉選單有浮動標籤「狀態篩選」、「類別篩選」
- **修改後**: 完全移除標籤，直接顯示選中的值

#### 調整高度
- **修改前**: 48px 高度
- **修改後**: 40px 高度

#### 使用對話框模式
- **修改前**: 使用傳統下拉選單
- **修改後**: 使用 `showAsDialog: true` 的對話框選擇模式

### 2. 預設選項統一

#### 狀態篩選
- **修改前**: 「全部狀態」
- **修改後**: 「全部」

#### 類別篩選
- **修改前**: 「全部類別」  
- **修改後**: 「全部類別」（保持不變）

### 3. 移除清除按鈕

- **修改前**: 有篩選條件時顯示清除按鈕
- **修改後**: 完全移除清除按鈕，通過選擇「全部」來重置

### 4. 智能狀態選項

#### 根據分頁動態顯示狀態選項

**我報名的活動狀態**:
- 全部
- 報名成功 (event)
- 應徵確認中 (task)  
- 應徵成功 (task)
- 已結束
- 已取消

**我發布的活動狀態**:
- 全部
- 活動發布中 (event)
- 招募中 (task)
- 已結束
- 已取消

## 技術實現

### CustomDropdown 組件改進

```dart
// 支援無標籤模式
bool get _shouldFloatLabel {
  // 如果沒有標籤，不需要浮動
  if (widget.label.isEmpty) return false;
  // ... 其他邏輯
}

// 調整內容區域 padding
padding: EdgeInsets.only(
  left: 16,
  right: 16,
  top: widget.label.isEmpty ? 12 : (_shouldFloatLabel ? 26 : 20),
  bottom: 8,
),

// 條件性顯示標籤
if (widget.label.isNotEmpty)
  AnimatedPositioned(
    // 標籤相關代碼
  ),
```

### 篩選區域重構

```dart
/// 建立狀態下拉選單
Widget _buildStatusDropdown() {
  final isRegisteredTab = _tabController.index == 0;
  final currentValue = isRegisteredTab ? _selectedRegisteredStatus : _selectedPublishedStatus;
  final statusOptions = isRegisteredTab 
      ? _getRegisteredStatusOptions() 
      : _getPublishedStatusOptions();

  return CustomDropdown<String>(
    label: '', // 無標籤
    height: 40,
    showAsDialog: true,
    dialogTitle: '選擇狀態',
    items: [
      const DropdownItem(value: 'all', label: '全部'),
      ...statusOptions,
    ],
    value: currentValue ?? 'all',
    onChanged: (value) {
      // 直接篩選，無需清除按鈕
      setState(() {
        if (isRegisteredTab) {
          _selectedRegisteredStatus = value == 'all' ? null : value;
        } else {
          _selectedPublishedStatus = value == 'all' ? null : value;
        }
      });
      _applyFilters();
    },
  );
}
```

### 分頁監聽

```dart
@override
void initState() {
  super.initState();
  _tabController = TabController(length: 2, vsync: this);
  
  // 監聽分頁切換，重新構建篩選區域
  _tabController.addListener(() {
    if (mounted) {
      setState(() {});
    }
  });
  
  _loadActivities();
}
```

## 用戶體驗改進

### 1. 更簡潔的界面
- 移除不必要的標籤和按鈕
- 更緊湊的 40px 高度
- 清爽的視覺效果

### 2. 更直觀的操作
- 選擇「全部」即可重置篩選
- 對話框模式提供更好的選擇體驗
- 即時篩選，無需額外操作

### 3. 智能適應
- 根據分頁自動顯示對應的狀態選項
- 分頁切換時狀態選項自動更新
- 保持各分頁的篩選狀態獨立

## 視覺效果

### 修改前
```
[狀態篩選 ▼] [類別篩選 ▼] [✕]
     48px          48px      48px
```

### 修改後  
```
[全部 ▼] [全部類別 ▼]
  40px      40px
```

## 相關文件

- `/lib/pages/my_activities_page.dart` - 主要篩選邏輯
- `/lib/components/design_system/custom_dropdown.dart` - 下拉選單組件改進
- `/lib/components/design_system/activity_status_badge.dart` - 狀態管理

## 測試建議

1. **分頁切換測試** - 驗證狀態選項是否正確切換
2. **篩選功能測試** - 確認篩選邏輯正常運作
3. **重置功能測試** - 驗證選擇「全部」能正確重置
4. **UI響應測試** - 檢查 40px 高度的視覺效果
5. **對話框測試** - 確認對話框選擇體驗良好

