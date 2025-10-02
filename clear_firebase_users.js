const admin = require('firebase-admin');

// 初始化Firebase Admin SDK
// 您需要從Firebase Console下載service account key
const serviceAccount = require('./firebase-admin-key.json'); // 您需要下載這個文件

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://time-mvp-7b126-default-rtdb.firebaseio.com"
});

async function deleteAllUsers() {
  try {
    console.log('開始刪除所有Firebase Authentication用戶...');
    
    // 獲取所有用戶
    const listUsersResult = await admin.auth().listUsers();
    const users = listUsersResult.users;
    
    console.log(`找到 ${users.length} 個用戶`);
    
    if (users.length === 0) {
      console.log('沒有用戶需要刪除');
      return;
    }
    
    // 批量刪除用戶
    const deletePromises = users.map(user => {
      console.log(`刪除用戶: ${user.email} (${user.uid})`);
      return admin.auth().deleteUser(user.uid);
    });
    
    await Promise.all(deletePromises);
    
    console.log('所有用戶已成功刪除！');
    
  } catch (error) {
    console.error('刪除用戶時發生錯誤:', error);
  }
}

// 執行刪除
deleteAllUsers().then(() => {
  console.log('清理完成');
  process.exit(0);
}).catch(error => {
  console.error('執行失敗:', error);
  process.exit(1);
});
