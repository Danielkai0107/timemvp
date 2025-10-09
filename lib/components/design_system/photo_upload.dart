import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'app_colors.dart';

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
          color: AppColors.white,
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
                color: AppColors.grey300,
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
                          color: AppColors.textPrimary,
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
                          color: AppColors.textPrimary,
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
                        color: AppColors.textPrimary,
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
    
    // 如果沒有照片，顯示"+ 新增照片"按鈕
    if (_photos.isEmpty) {
      return _buildInitialAddButton();
    }
    
    return _build2x2PhotoGrid();
  }

  /// 建構初始新增照片按鈕（沒有照片時顯示）
  Widget _buildInitialAddButton() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
          color: AppColors.white,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add,
              color: AppColors.textPrimary,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              '新增相片',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 建構2x2照片網格
  Widget _build2x2PhotoGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 4 / 3, // 修改為4:3比例
      ),
      itemCount: 4, // 固定4個位置
      itemBuilder: (context, index) {
        if (index < _photos.length) {
          // 顯示已上傳的照片
          return _buildPhotoSlot(photoPath: _photos[index], index: index);
        } else if (index == _photos.length && _photos.length < widget.maxPhotos) {
          // 顯示新增按鈕（虛線方框 + icon）
          return _buildAddPhotoSlot();
        } else {
          // 空白位置
          return _buildEmptySlot();
        }
      },
    );
  }

  /// 建構照片位置（已上傳的照片）
  Widget _buildPhotoSlot({required String photoPath, required int index}) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.grey300,
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(photoPath),
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('PhotoUpload: 圖片載入錯誤 $photoPath: $error');
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
                color: AppColors.white,
              ),
            ),
          ),
        ),
        // 封面標籤（只在第一張照片顯示）
        if (index == 0)
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                '封面',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 建構新增照片按鈕（虛線方框 + icon）
  Widget _buildAddPhotoSlot() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: CustomPaint(
        painter: DashedBorderPainter(
          color: AppColors.grey300,
          strokeWidth: 2.0,
          borderRadius: 12.0,
          dashWidth: 12.0,
          dashSpace: 12.0,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.transparent,
          ),
          child: const Center(
            child: Icon(
              Icons.add,
              size: 32,
              color: AppColors.grey500,
            ),
          ),
        ),
      ),
    );
  }

  /// 建構空白位置
  Widget _buildEmptySlot() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
      ),
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

/// 虛線邊框繪製器
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double borderRadius;
  final double dashWidth;
  final double dashSpace;

  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.borderRadius,
    this.dashWidth = 5.0,
    this.dashSpace = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rect);
    
    _drawDashedPath(canvas, path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final pathMetrics = path.computeMetrics();
    
    for (final metric in pathMetrics) {
      double distance = 0.0;
      bool draw = true;
      
      while (distance < metric.length) {
        final length = draw ? dashWidth : dashSpace;
        final endDistance = distance + length;
        
        if (draw) {
          final extractPath = metric.extractPath(distance, endDistance);
          canvas.drawPath(extractPath, paint);
        }
        
        distance = endDistance;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
