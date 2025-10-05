// 初始化 Firestore 分類數據的腳本
// 在 Firebase Console 或使用 Firebase Admin SDK 運行

const categories = [
  // 活動類型分類
  {
    id: 'EventCategory_language_teaching',
    name: 'EventCategory_language_teaching',
    displayName: '語言教學',
    type: 'event',
    sortOrder: 1,
    isActive: true,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  },
  {
    id: 'EventCategory_skill_experience',
    name: 'EventCategory_skill_experience',
    displayName: '技能體驗',
    type: 'event',
    sortOrder: 2,
    isActive: true,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  },
  {
    id: 'EventCategory_event_support',
    name: 'EventCategory_event_support',
    displayName: '活動支援',
    type: 'event',
    sortOrder: 3,
    isActive: true,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  },
  {
    id: 'EventCategory_life_service',
    name: 'EventCategory_life_service',
    displayName: '生活服務',
    type: 'event',
    sortOrder: 4,
    isActive: true,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  },
  
  // 任務類型分類
  {
    id: 'TaskCategory_event_support',
    name: 'TaskCategory_event_support',
    displayName: '活動支援',
    type: 'task',
    sortOrder: 1,
    isActive: true,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  },
  {
    id: 'TaskCategory_life_service',
    name: 'TaskCategory_life_service',
    displayName: '生活服務',
    type: 'task',
    sortOrder: 2,
    isActive: true,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  },
  {
    id: 'TaskCategory_skill_sharing',
    name: 'TaskCategory_skill_sharing',
    displayName: '技能分享',
    type: 'task',
    sortOrder: 3,
    isActive: true,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  },
  {
    id: 'TaskCategory_creative_work',
    name: 'TaskCategory_creative_work',
    displayName: '創意工作',
    type: 'task',
    sortOrder: 4,
    isActive: true,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  }
];

// 如果使用 Firebase Admin SDK
/*
const admin = require('firebase-admin');

// 初始化 Firebase Admin
const serviceAccount = require('./path/to/serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function initializeCategories() {
  const batch = db.batch();
  
  categories.forEach(category => {
    const docRef = db.collection('categories').doc(category.id);
    batch.set(docRef, category);
  });
  
  try {
    await batch.commit();
    console.log('分類數據初始化完成！');
  } catch (error) {
    console.error('初始化分類數據失敗:', error);
  }
}

initializeCategories();
*/

// 如果在 Firebase Console 中運行，可以複製以下數據：
console.log('請在 Firebase Console 的 Firestore 中創建 "categories" 集合，並添加以下文檔：');
categories.forEach(category => {
  console.log(`文檔 ID: ${category.id}`);
  console.log('數據:', JSON.stringify(category, null, 2));
  console.log('---');
});

// 或者使用 Firebase CLI 和 Firestore 模擬器
/*
firebase emulators:start --only firestore
然後在模擬器中運行此腳本
*/
