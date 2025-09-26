import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

/// 相片上傳組件
class PhotoUpload extends StatefulWidget {
  const PhotoUpload({
    super.key,
    this.maxPhotos = 4,
    this.onPhotosChanged,
    this.photos = const [],
  });

  /// 最大相片數量
  final int maxPhotos;
  
  /// 相片變化回調
  final ValueChanged<List<String>>? onPhotosChanged;
  
  /// 已選相片列表
  final List<String> photos;

  @override
  PhotoUploadState createState() => PhotoUploadState();
}

class PhotoUploadState extends State<PhotoUpload> {
  List<String> _photos = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _photos = List.from(widget.photos);
    debugPrint('PhotoUpload initState: ${_photos.length} 張相片');
  }

  @override
  void didUpdateWidget(PhotoUpload oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 同步外部照片狀態
    if (widget.photos != oldWidget.photos) {
      debugPrint('PhotoUpload didUpdateWidget: 外部相片更新 ${widget.photos.length} 張');
      setState(() {
        _photos = List.from(widget.photos);
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    debugPrint('PhotoUpload: 開始從相簿選擇圖片');
    
    if (_photos.length >= widget.maxPhotos) {
      _showErrorDialog('已達到最大相片數量限制');
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        debugPrint('PhotoUpload: 成功選擇圖片 ${image.path}');
        
        // 檢查文件是否存在
        final file = File(image.path);
        if (await file.exists()) {
          final fileSize = await file.length();
          debugPrint('PhotoUpload: 文件大小 $fileSize bytes');
          
          setState(() {
            _photos.add(image.path);
          });
          
          debugPrint('PhotoUpload: 觸發回調，總共 ${_photos.length} 張相片');
          widget.onPhotosChanged?.call(_photos);
        } else {
          debugPrint('PhotoUpload: 錯誤 - 選擇的文件不存在');
          _showErrorDialog('選擇的文件無法訪問');
        }
      } else {
        debugPrint('PhotoUpload: 用戶取消選擇圖片');
      }
    } catch (e) {
      debugPrint('PhotoUpload: 選擇圖片時發生錯誤: $e');
      _showErrorDialog('選擇相片失敗，請確認已授予相簿權限');
    }
  }

  Future<void> _takePhoto() async {
    debugPrint('PhotoUpload: 開始拍照');
    
    if (_photos.length >= widget.maxPhotos) {
      _showErrorDialog('已達到最大相片數量限制');
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        debugPrint('PhotoUpload: 成功拍照 ${image.path}');
        
        setState(() {
          _photos.add(image.path);
        });
        
        debugPrint('PhotoUpload: 觸發回調，總共 ${_photos.length} 張相片');
        widget.onPhotosChanged?.call(_photos);
      } else {
        debugPrint('PhotoUpload: 用戶取消拍照');
      }
    } catch (e) {
      debugPrint('PhotoUpload: 拍照時發生錯誤: $e');
      _showErrorDialog('拍照失敗，請確認已授予相機權限');
    }
  }

  void _removePhoto(int index) {
    debugPrint('PhotoUpload: 移除第 $index 張相片');
    
    setState(() {
      _photos.removeAt(index);
    });
    
    debugPrint('PhotoUpload: 移除後剩餘 ${_photos.length} 張相片');
    widget.onPhotosChanged?.call(_photos);
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 頂部拖拽指示器
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // 標題列和關閉按鈕
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFFF0F0F0),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 32),
                  Expanded(
                    child: Center(
                      child: Text(
                        '選擇相片來源',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 20,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // 選項列表
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  // 相簿選項
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Color(0xFFF8F8F8),
                          width: 1,
                        ),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      leading: const Icon(
                        Icons.photo_library_outlined,
                        color: Colors.black54,
                        size: 24,
                      ),
                      title: const Text(
                        '從相簿選擇',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _pickImageFromGallery();
                      },
                    ),
                  ),
                  
                  // 拍照選項
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    leading: const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.black54,
                      size: 24,
                    ),
                    title: const Text(
                      '拍照',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _takePhoto();
                    },
                  ),
                ],
              ),
            ),
            
            // 添加底部安全區域間距
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('錯誤'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('PhotoUpload build: ${_photos.length} 張相片');
    
    return Column(
      children: [
        // 已選相片網格
        if (_photos.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: _photos.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    // 相片
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_photos[index]),
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint('PhotoUpload: 圖片載入錯誤 ${_photos[index]}: $error');
                            return Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Icon(
                                  Icons.error_outline,
                                  color: Colors.grey,
                                  size: 32,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // 刪除按鈕
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _removePhoto(index),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

        // 新增相片按鈕
        GestureDetector(
          onTap: _showImageSourceDialog,
          child: Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add,
                  color: Colors.black,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  '新增相片',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 相片上傳建構器
class PhotoUploadBuilder {
  /// 個人相片上傳
  static Widget personal({
    ValueChanged<List<String>>? onPhotosChanged,
    List<String> photos = const [],
    int maxPhotos = 4,
  }) {
    return PhotoUpload(
      maxPhotos: maxPhotos,
      onPhotosChanged: onPhotosChanged,
      photos: photos,
    );
  }
}
