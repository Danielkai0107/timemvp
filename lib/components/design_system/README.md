# TimeApp 設計系統

TimeApp 的統一設計系統，提供完整的 UI 組件庫和設計規範，確保整個應用程式的視覺一致性與使用者體驗。

## 目錄

- [色彩系統 (AppColors)](#色彩系統-appcolors)
- [組件庫](#組件庫)
- [使用方式](#使用方式)
- [最佳實踐](#最佳實踐)

---

## 色彩系統 (AppColors)

### 主要色彩 (Primary) - 黃色系

主要品牌色彩，用於重要按鈕、強調元素和品牌識別。

| 色彩 | 色碼 | 色塊 | 用途 |
|------|------|------|------|
| `primary900` | #FFBE0A | ![#FFBE0A](https://via.placeholder.com/20x20/FFBE0A/FFBE0A.png) | 主要按鈕、重點強調 |
| `primary700` | #FECC42 | ![#FECC42](https://via.placeholder.com/20x20/FECC42/FECC42.png) | 次要強調、懸停狀態 |
| `primary500` | #FEDA7A | ![#FEDA7A](https://via.placeholder.com/20x20/FEDA7A/FEDA7A.png) | 輕微強調、裝飾元素 |
| `primary300` | #FDE8B1 | ![#FDE8B1](https://via.placeholder.com/20x20/FDE8B1/FDE8B1.png) | 淺色背景、邊框 |
| `primary100` | #FCF6E9 | ![#FCF6E9](https://via.placeholder.com/20x20/FCF6E9/FCF6E9.png) | 最淺背景、微妙裝飾 |

### 次要色彩 (Secondary) - 紫色系

次要色彩，用於輔助元素和裝飾性設計。

| 色彩 | 色碼 | 色塊 | 用途 |
|------|------|------|------|
| `secondary900` | #AC6DFF | ![#AC6DFF](https://via.placeholder.com/20x20/AC6DFF/AC6DFF.png) | 次要按鈕、重點裝飾 |
| `secondary700` | #C293FF | ![#C293FF](https://via.placeholder.com/20x20/C293FF/C293FF.png) | 次要強調元素 |
| `secondary500` | #C293FF | ![#C293FF](https://via.placeholder.com/20x20/C293FF/C293FF.png) | 輔助裝飾 |
| `secondary300` | #D7B8FF | ![#D7B8FF](https://via.placeholder.com/20x20/D7B8FF/D7B8FF.png) | 淺色裝飾、邊框 |
| `secondary100` | #ECDEFF | ![#ECDEFF](https://via.placeholder.com/20x20/ECDEFF/ECDEFF.png) | 最淺背景 |

### 成功色彩 (Success) - 綠色系

用於表示成功狀態、完成操作和正面反饋。

| 色彩 | 色碼 | 色塊 | 用途 |
|------|------|------|------|
| `success900` | #00B383 | ![#00B383](https://via.placeholder.com/20x20/00B383/00B383.png) | 成功按鈕、完成狀態 |
| `success700` | #36C6A0 | ![#36C6A0](https://via.placeholder.com/20x20/36C6A0/36C6A0.png) | 成功提示 |
| `success500` | #6CD9BC | ![#6CD9BC](https://via.placeholder.com/20x20/6CD9BC/6CD9BC.png) | 輕微成功提示 |
| `success300` | #A2ECD8 | ![#A2ECD8](https://via.placeholder.com/20x20/A2ECD8/A2ECD8.png) | 成功背景 |
| `success100` | #DBFFF4 | ![#DBFFF4](https://via.placeholder.com/20x20/DBFFF4/DBFFF4.png) | 最淺成功背景 |

### 錯誤色彩 (Error) - 紅色系

用於錯誤提示、警告狀態和需要用戶注意的情況。

| 色彩 | 色碼 | 色塊 | 用途 |
|------|------|------|------|
| `error900` | #EF2562 | ![#EF2562](https://via.placeholder.com/20x20/EF2562/EF2562.png) | 錯誤按鈕、嚴重錯誤 |
| `error700` | #F35987 | ![#F35987](https://via.placeholder.com/20x20/F35987/F35987.png) | 錯誤提示 |
| `error500` | #F78EAE | ![#F78EAE](https://via.placeholder.com/20x20/F78EAE/F78EAE.png) | 輕微錯誤 |
| `error300` | #FBC2D3 | ![#FBC2D3](https://via.placeholder.com/20x20/FBC2D3/FBC2D3.png) | 錯誤背景 |
| `error100` | #FFF6F9 | ![#FFF6F9](https://via.placeholder.com/20x20/FFF6F9/FFF6F9.png) | 最淺錯誤背景 |

### 中性色彩 (Grey) - 灰色系

用於文字、邊框、背景和各種中性元素。

| 色彩 | 色碼 | 色塊 | 用途 |
|------|------|------|------|
| `grey900` | #222222 | ![#222222](https://via.placeholder.com/20x20/222222/222222.png) | 主要文字、深色元素 |
| `grey700` | #6A6A6A | ![#6A6A6A](https://via.placeholder.com/20x20/6A6A6A/6A6A6A.png) | 次要文字、說明文字 |
| `grey500` | #979797 | ![#979797](https://via.placeholder.com/20x20/979797/979797.png) | 提示文字、圖標 |
| `grey300` | #DDDDDD | ![#DDDDDD](https://via.placeholder.com/20x20/DDDDDD/DDDDDD.png) | 邊框、分隔線 |
| `grey100` | #F2F2F2 | ![#F2F2F2](https://via.placeholder.com/20x20/F2F2F2/F2F2F2.png) | 背景、禁用狀態 |

### 基礎色彩 (Basic)

| 色彩 | 色碼 | 色塊 | 用途 |
|------|------|------|------|
| `black` | #222222 | ![#222222](https://via.placeholder.com/20x20/222222/222222.png) | 純黑色，文字和圖標 |
| `white` | #FFFFFF | ![#FFFFFF](https://via.placeholder.com/20x20/FFFFFF/000000.png) | 純白色，背景和文字 |

### 語義化色彩別名

為了提高可讀性和維護性，我們提供了語義化的色彩別名：

```dart
// 品牌色彩
AppColors.brandPrimary     // primary900
AppColors.brandSecondary   // secondary900

// 文字色彩
AppColors.textPrimary      // grey900 - 主要文字
AppColors.textSecondary    // grey700 - 次要文字
AppColors.textHint         // grey500 - 提示文字

// 背景色彩
AppColors.backgroundPrimary   // white - 主要背景
AppColors.backgroundSecondary // grey100 - 次要背景

// 邊框與分隔
AppColors.divider          // grey300 - 分隔線
AppColors.border           // grey300 - 邊框

// 狀態色彩
AppColors.statusSuccess    // success900 - 成功
AppColors.statusError      // error900 - 錯誤
AppColors.statusWarning    // primary900 - 警告
```

---

## 組件庫

### 1. 自定義按鈕 (CustomButton)

統一的按鈕組件，支援多種樣式和狀態。

#### 樣式類型

- `primary` - 主要按鈕（黃色背景）
- `secondary` - 次要按鈕（紫色背景）
- `success` - 成功按鈕（綠色背景）
- `danger` - 危險按鈕（紅色背景）
- `info` - 資訊按鈕（淺灰色背景）
- `outline` - 外框按鈕（透明背景，有邊框）
- `text` - 文字按鈕（透明背景，無邊框）

#### 使用範例

```dart
// 基本使用
CustomButton(
  onPressed: () {},
  text: '確認',
  style: CustomButtonStyle.primary,
)

// 便捷建構器
ButtonBuilder.primary(
  onPressed: () {},
  text: '登入',
  width: double.infinity,
)

// 社交登入按鈕
ButtonBuilder.googleSignIn(
  onPressed: () {},
)
```

### 2. 自定義文字輸入框 (CustomTextInput)

Airbnb 風格的文字輸入框，具有浮動標籤和現代化設計。

#### 特色功能

- 浮動標籤動畫
- 錯誤狀態顯示
- 多種輸入類型支援
- 前置和後置圖標
- 多行文字輸入

#### 使用範例

```dart
// 基本使用
CustomTextInput(
  label: '電子信箱',
  controller: emailController,
  onChanged: (value) {},
)

// 便捷建構器
TextInputBuilder.email(
  controller: emailController,
  onChanged: (value) {},
)

TextInputBuilder.password(
  controller: passwordController,
  suffixIcon: Icon(Icons.visibility),
)
```

### 3. 自定義下拉選單 (CustomDropdown)

與文字輸入框保持一致設計的下拉選單組件。

#### 功能特色

- 浮動標籤
- 傳統下拉選單模式
- 彈窗選擇器模式
- 單選與多選支援
- 自動滾動到選中項目

#### 使用範例

```dart
// 基本使用
CustomDropdown<String>(
  label: '性別',
  items: [
    DropdownItem(value: 'male', label: '男性'),
    DropdownItem(value: 'female', label: '女性'),
  ],
  value: selectedGender,
  onChanged: (value) {},
)

// 便捷建構器
DropdownBuilder.gender(
  value: selectedGender,
  onChanged: (value) {},
)
```

### 4. 自定義分頁 (CustomTabs)

統一的分頁切換組件。

#### 使用範例

```dart
// 使用預設樣式
TabsBuilder.personalBusiness(
  onTabChanged: (index) {},
)

// 自定義分頁
CustomTabs(
  tabs: [
    TabItem(text: '個人', icon: Icons.person),
    TabItem(text: '企業', icon: Icons.business),
  ],
  onTabChanged: (index) {},
)
```

### 5. 相片上傳 (PhotoUpload)

支援相簿選擇和拍照的圖片上傳組件。

#### 使用範例

```dart
PhotoUpload(
  maxPhotos: 4,
  photos: selectedPhotos,
  onPhotosChanged: (photos) {},
)
```

### 6. 步驟指示器 (StepIndicator)

顯示當前進度的步驟指示器。

#### 使用範例

```dart
// 步驟指示器
StepIndicator(
  currentStep: 2,
  totalSteps: 5,
)

// 步驟導航按鈕
StepNavigationButtons(
  onPrevious: () {},
  onNext: () {},
  previousText: '上一步',
  nextText: '下一步',
)
```

### 7. 服務條款彈窗 (TermsPopup)

全屏服務條款和隱私政策顯示組件。

#### 使用範例

```dart
// 顯示服務條款
TermsPopupBuilder.showTermsOfService(context);

// 顯示隱私政策
TermsPopupBuilder.showPrivacyPolicy(context);
```

---

## 使用方式

### 1. 引入設計系統

```dart
import '../components/design_system/app_colors.dart';
import '../components/design_system/custom_button.dart';
import '../components/design_system/custom_text_input.dart';
// 其他組件...
```

### 2. 使用色彩

```dart
// 推薦：使用語義化別名
Container(
  color: AppColors.backgroundPrimary,
  child: Text(
    'Hello World',
    style: TextStyle(color: AppColors.textPrimary),
  ),
)

// 直接使用色彩常數
Container(
  decoration: BoxDecoration(
    color: AppColors.primary100,
    border: Border.all(color: AppColors.primary300),
  ),
)
```

### 3. 使用組件

```dart
// 使用設計系統組件替代原生組件
Column(
  children: [
    // ✅ 好的做法
    TextInputBuilder.email(
      controller: emailController,
    ),
    
    ButtonBuilder.primary(
      onPressed: () {},
      text: '登入',
    ),
    
    // ❌ 避免直接使用原生組件
    // TextField(...),
    // ElevatedButton(...),
  ],
)
```

---

## 最佳實踐

### 1. 色彩使用原則

- **一致性**：在整個應用程式中使用相同的色彩定義
- **語義化**：優先使用語義化別名（如 `textPrimary` 而非 `grey900`）
- **層次感**：使用不同色調建立視覺層次
- **無障礙**：確保足夠的對比度以符合無障礙標準

### 2. 組件使用原則

- **統一性**：優先使用設計系統組件而非原生組件
- **擴展性**：需要特殊功能時，擴展現有組件而非重新開發
- **簡潔性**：使用便捷建構器簡化常見用例

### 3. 維護原則

- **單一來源**：所有色彩定義集中在 `AppColors` 中
- **文檔化**：為新增的組件和色彩添加文檔說明
- **測試**：確保組件在不同狀態下的表現一致

### 4. 色彩對比度指南

確保文字與背景的對比度符合 WCAG 2.1 標準：

| 使用場景 | 最小對比度 | 推薦組合 |
|----------|------------|----------|
| 大文字 (18pt+) | 3:1 | `textPrimary` + `backgroundPrimary` |
| 小文字 | 4.5:1 | `textSecondary` + `backgroundSecondary` |
| 裝飾元素 | 3:1 | `primary300` + `backgroundPrimary` |

### 5. 響應式設計

組件設計考慮不同螢幕尺寸：

- 使用相對單位（如 `MediaQuery.of(context).size.width`）
- 提供 `width` 參數控制組件寬度
- 支援動態高度調整

### 6. 深色模式準備

雖然目前未實現深色模式，但色彩系統已為未來擴展做好準備：

```dart
// 未來可以這樣實現深色模式
class AppColors {
  static bool get isDarkMode => Theme.of(context).brightness == Brightness.dark;
  
  static Color get backgroundPrimary => 
    isDarkMode ? Color(0xFF121212) : Color(0xFFFFFFFF);
}
```

---

## 更新日誌

### v1.0.0 (當前版本)
- ✅ 完整的色彩系統定義
- ✅ 7個核心 UI 組件
- ✅ 語義化色彩別名
- ✅ 便捷建構器函數
- ✅ 完整的設計文檔

---

## 貢獻指南

如需添加新的色彩或組件：

1. 在 `AppColors` 中定義新色彩
2. 建立或擴展相關組件
3. 添加便捷建構器（如適用）
4. 更新此文檔
5. 確保在所有頁面中正確使用

---

*此設計系統持續演進中，如有建議或問題請聯繫開發團隊。*
