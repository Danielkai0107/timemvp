#!/usr/bin/env python3

# 讀取文件
with open('lib/pages/registration_page.dart', 'r') as f:
    lines = f.readlines()

# 修復第1127-1131行的onPhotosChanged回調
for i, line in enumerate(lines):
    if i >= 1126 and i <= 1130:  # 0-based indexing, so 1127-1131 becomes 1126-1130
        if 'onPhotosChanged: (photos) {' in line:
            lines[i] = '              onPhotosChanged: (photos) {\n'
            lines[i+1] = '                debugPrint("=== 註冊頁面相片回調觸發 ===");\n'
            lines[i+2] = '                debugPrint("收到相片數量: ${photos.length}");\n'
            lines[i+3] = '                debugPrint("相片路徑: $photos");\n'
            lines[i+4] = '                setState(() {\n'
            lines[i+5] = '                  _uploadedPhotos = photos;\n'
            lines[i+6] = '                });\n'
            lines[i+7] = '                debugPrint("_uploadedPhotos 已更新為: $_uploadedPhotos");\n'
            lines[i+8] = '              },\n'
            break

# 修復_canProceedFromStep4方法
for i, line in enumerate(lines):
    if 'bool _canProceedFromStep4() {' in line:
        lines[i] = '  bool _canProceedFromStep4() {\n'
        lines[i+1] = '    debugPrint("=== 檢查步驟4是否可以繼續 ===");\n'
        lines[i+2] = '    debugPrint("當前 _uploadedPhotos 數量: ${_uploadedPhotos.length}");\n'
        lines[i+3] = '    debugPrint("_uploadedPhotos 內容: $_uploadedPhotos");\n'
        lines[i+4] = '    final canProceed = _uploadedPhotos.isNotEmpty;\n'
        lines[i+5] = '    debugPrint("步驟4可以繼續: $canProceed");\n'
        lines[i+6] = '    return canProceed;\n'
        lines[i+7] = '  }\n'
        break

# 修復_saveUserData方法
for i, line in enumerate(lines):
    if 'Future<void> _saveUserData({required bool isVerified}) async {' in line:
        lines[i+1] = '    debugPrint("=== 開始註冊流程 ===");\n'
        lines[i+2] = '    debugPrint("帳戶類型: $_selectedAccountType");\n' 
        lines[i+3] = '    debugPrint("個人相片數量: ${_uploadedPhotos.length}");\n'
        lines[i+4] = '    debugPrint("個人相片路徑: $_uploadedPhotos");\n'
        lines[i+5] = '    try {\n'
        break

# 寫入文件
with open('lib/pages/registration_page.dart', 'w') as f:
    f.writelines(lines)

print("修復完成!")
