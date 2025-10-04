import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'app_colors.dart';

/// 頭像上傳組件
class AvatarUpload extends StatefulWidget {
  final String? currentAvatarUrl;
  final Function(String?)? onAvatarChanged;
  final double size;
  final bool isEnabled;

  const AvatarUpload({
    super.key,
    this.currentAvatarUrl,
    this.onAvatarChanged,
    this.size = 120,
    this.isEnabled = true,
  });

  @override
  State<AvatarUpload> createState() => _AvatarUploadState();
}

class _AvatarUploadState extends State<AvatarUpload> {
  final ImagePicker _picker = ImagePicker();
  String? _localImagePath;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isEnabled ? _showImageSourceDialog : null,
      child: Stack(
        children: [
          // 頭像容器
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: AppColors.primary100,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary300,
                width: 3,
              ),
            ),
            child: ClipOval(
              child: _buildAvatarContent(),
            ),
          ),
          
          // 編輯按鈕
          if (widget.isEnabled)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary900,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent() {
    // 優先顯示本地選擇的圖片
    if (_localImagePath != null) {
      return Image.file(
        File(_localImagePath!),
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('載入本地頭像失敗: $error');
          return _buildDefaultAvatar();
        },
      );
    }
    
    // 顯示網路圖片
    if (widget.currentAvatarUrl != null && widget.currentAvatarUrl!.isNotEmpty) {
      return Image.network(
        widget.currentAvatarUrl!,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary900),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('載入網路頭像失敗: $error');
          return _buildDefaultAvatar();
        },
      );
    }
    
    // 預設頭像
    return _buildDefaultAvatar();
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: widget.size,
      height: widget.size,
      color: AppColors.primary100,
      child: Icon(
        Icons.person,
        size: widget.size * 0.5,
        color: AppColors.primary900,
      ),
    );
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
                        '選擇頭像來源',
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
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: (widget.currentAvatarUrl != null || _localImagePath != null) 
                              ? const Color(0xFFF8F8F8) 
                              : Colors.transparent,
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
                  ),
                  
                  // 移除頭像選項（如果有現有頭像）
                  if (widget.currentAvatarUrl != null || _localImagePath != null)
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      leading: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 24,
                      ),
                      title: const Text(
                        '移除頭像',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _removeAvatar();
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

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        final file = File(image.path);
        if (await file.exists()) {
          setState(() {
            _localImagePath = image.path;
          });
          widget.onAvatarChanged?.call(image.path);
        }
      }
    } catch (e) {
      debugPrint('拍照失敗: $e');
      if (mounted) {
        _showErrorDialog('拍照失敗，請確認已授予相機權限');
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        final file = File(image.path);
        if (await file.exists()) {
          setState(() {
            _localImagePath = image.path;
          });
          widget.onAvatarChanged?.call(image.path);
        }
      }
    } catch (e) {
      debugPrint('選擇圖片失敗: $e');
      if (mounted) {
        _showErrorDialog('選擇圖片失敗，請確認已授予相簿權限');
      }
    }
  }

  void _removeAvatar() {
    setState(() {
      _localImagePath = null;
    });
    widget.onAvatarChanged?.call(null);
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('錯誤'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('確定'),
            ),
          ],
        );
      },
    );
  }
}
