// 測試 Firebase 分類數據的簡單腳本
// 在 Flutter 項目中運行: flutter run test_firebase_categories.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lib/services/category_service.dart';

void main() {
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase 分類測試',
      home: const TestPage(),
    );
  }
}

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  final CategoryService _categoryService = CategoryService();
  List<String> _logs = [];
  bool _isLoading = false;

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toIso8601String()}: $message');
    });
    print(message);
  }

  Future<void> _testFirebaseConnection() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
    });

    _addLog('開始測試 Firebase 連接...');

    try {
      // 1. 測試基本連接
      final firestore = FirebaseFirestore.instance;
      _addLog('Firestore 實例創建成功');

      // 2. 測試讀取 categories 集合
      _addLog('嘗試讀取 categories 集合...');
      final querySnapshot = await firestore.collection('categories').get();
      _addLog('成功讀取到 ${querySnapshot.docs.length} 個文檔');

      // 3. 顯示每個文檔的內容
      for (int i = 0; i < querySnapshot.docs.length; i++) {
        final doc = querySnapshot.docs[i];
        _addLog('文檔 ${i + 1}:');
        _addLog('  ID: ${doc.id}');
        _addLog('  數據: ${doc.data()}');
        
        // 檢查必要欄位
        final data = doc.data();
        if (data['displayName'] != null) {
          _addLog('  ✓ displayName: ${data['displayName']}');
        } else {
          _addLog('  ✗ 缺少 displayName 欄位');
        }
        
        if (data['type'] != null) {
          _addLog('  ✓ type: ${data['type']}');
        } else {
          _addLog('  ✗ 缺少 type 欄位');
        }
        
        if (data['sortOrder'] != null) {
          _addLog('  ✓ sortOrder: ${data['sortOrder']}');
        } else {
          _addLog('  ⚠ 缺少 sortOrder 欄位（將使用預設值 0）');
        }
      }

      // 4. 測試 CategoryService
      _addLog('測試 CategoryService...');
      try {
        final categories = await _categoryService.getAllCategories(forceRefresh: true);
        _addLog('CategoryService 成功解析 ${categories.length} 個分類');
        
        for (final category in categories) {
          _addLog('  - ${category.displayName} (${category.type})');
        }
      } catch (e) {
        _addLog('CategoryService 解析失敗: $e');
      }

    } catch (e) {
      _addLog('Firebase 連接失敗: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase 分類測試'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _testFirebaseConnection,
              child: _isLoading 
                  ? const CircularProgressIndicator()
                  : const Text('測試 Firebase 分類數據'),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    _logs[index],
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
