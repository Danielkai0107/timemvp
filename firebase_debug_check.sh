#!/bin/bash

echo "🔍 Firebase 配置檢查"
echo "===================="

echo
echo "1. 檢查 google-services.json 是否存在:"
if [ -f "android/app/google-services.json" ]; then
    echo "✅ google-services.json 存在"
    echo "📄 檔案大小: $(ls -lh android/app/google-services.json | awk '{print $5}')"
else
    echo "❌ google-services.json 不存在!"
fi

echo
echo "2. 檢查 package_name 是否匹配:"
PACKAGE_FROM_JSON=$(grep -o '"package_name": "[^"]*' android/app/google-services.json | cut -d'"' -f4)
PACKAGE_FROM_GRADLE=$(grep 'applicationId' android/app/build.gradle.kts | sed 's/.*= "//' | sed 's/"//')
echo "📱 JSON 中的 package_name: $PACKAGE_FROM_JSON"
echo "🔧 Gradle 中的 applicationId: $PACKAGE_FROM_GRADLE"
if [ "$PACKAGE_FROM_JSON" = "$PACKAGE_FROM_GRADLE" ]; then
    echo "✅ package name 匹配"
else
    echo "❌ package name 不匹配!"
fi

echo
echo "3. 檢查 Google Services plugin 配置:"
if grep -q "com.google.gms.google-services" android/app/build.gradle.kts; then
    echo "✅ Google Services plugin 已配置"
else
    echo "❌ 缺少 Google Services plugin!"
fi

echo
echo "4. 檢查項目級依賴:"
if grep -q "com.google.gms:google-services" android/build.gradle.kts; then
    echo "✅ 項目級 Google Services 依賴已配置"
else
    echo "❌ 缺少項目級 Google Services 依賴!"
fi

echo
echo "5. 檢查 Firebase 項目ID:"
PROJECT_ID=$(grep -o '"project_id": "[^"]*' android/app/google-services.json | cut -d'"' -f4)
echo "🆔 Firebase 項目ID: $PROJECT_ID"

echo
echo "🎯 建議的解決步驟:"
echo "1. 確保 Firebase Console 中啟用了 Authentication"
echo "2. 確保 Firebase Console 中啟用了 Firestore Database"  
echo "3. 確保 Firebase Console 中啟用了 Storage"
echo "4. 重啟應用程式: flutter run"
