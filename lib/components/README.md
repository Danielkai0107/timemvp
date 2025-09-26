# CustomTextInput 組件系統

## 🎨 Airbnb 風格輸入框組件

這是一個現代化、可重複使用的文字輸入組件，具有浮動標籤、聚焦動畫和美觀的設計。

## 📚 基本用法

### 基礎組件
```dart
CustomTextInput(
  label: '標籤文字',
  controller: textController,
  onChanged: (value) {
    print('輸入值: $value');
  },
)
```

## 🛠️ 便捷建構器

### 電子信箱輸入框
```dart
TextInputBuilder.email(
  controller: emailController,
  onChanged: (value) => print(value),
)
```

### 密碼輸入框
```dart
TextInputBuilder.password(
  controller: passwordController,
  onChanged: (value) => print(value),
)
```

### 數字輸入框
```dart
TextInputBuilder.number(
  label: '輸入數字',
  controller: numberController,
)
```

### 多行輸入框
```dart
TextInputBuilder.multiline(
  label: '多行內容',
  controller: textController,
  maxLines: 4,
  height: 120,
)
```

## ⚙️ 自訂參數

| 參數 | 類型 | 預設值 | 說明 |
|------|------|--------|------|
| `label` | String | 必填 | 浮動標籤文字 |
| `controller` | TextEditingController? | null | 文字控制器 |
| `onChanged` | ValueChanged<String>? | null | 文字變化回調 |
| `isEnabled` | bool | true | 是否啟用 |
| `errorText` | String? | null | 錯誤訊息 |
| `obscureText` | bool | false | 是否隱藏文字（密碼） |
| `prefixIcon` | Widget? | null | 前置圖標 |
| `suffixIcon` | Widget? | null | 後置圖標 |
| `height` | double | 60.0 | 輸入框高度 |
| `borderRadius` | double | 12.0 | 邊框圓角 |

## 🎯 特色功能

- ✅ **浮動標籤動畫**: 智能標籤位置調整
- ✅ **聚焦狀態回饋**: 邊框和顏色變化
- ✅ **錯誤狀態顯示**: 紅色邊框和錯誤訊息
- ✅ **禁用狀態**: 灰色樣式和無法互動
- ✅ **圖標支持**: 前置和後置圖標
- ✅ **多行支持**: 可調整高度的多行輸入
- ✅ **響應式設計**: 適配不同螢幕尺寸