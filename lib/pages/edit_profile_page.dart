import 'package:flutter/material.dart';
import '../components/design_system/app_colors.dart';
import '../components/design_system/custom_button.dart';
import '../components/design_system/custom_text_input.dart';
import '../components/design_system/custom_dropdown.dart';
import '../components/design_system/custom_snackbar.dart';
import '../components/design_system/step_indicator.dart';
import '../components/design_system/avatar_upload.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

/// 編輯個人資料頁面，使用 terms_popup.dart 的 UI 設計
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  
  // 控制器
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _contactNameController = TextEditingController();
  
  // 狀態變數
  AuthUser? _currentUser;
  Map<String, dynamic>? _userData;
  String? _selectedGender;
  int? _selectedAge;
  String? _newAvatarPath;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyNameController.dispose();
    _contactNameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      _currentUser = _authService.currentUser;
      if (_currentUser != null) {
        final doc = await _userService.getUserDocument(_currentUser!.uid);
        
        if (mounted) {
          setState(() {
            if (doc.exists && doc.data() != null) {
              _userData = doc.data() as Map<String, dynamic>;
              _initializeControllers();
            }
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('載入用戶資料失敗: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _initializeControllers() {
    if (_userData != null) {
      if (_userData!['accountType'] == 'personal') {
        _nameController.text = _userData!['name'] ?? '';
        _selectedGender = _userData!['gender'];
        _selectedAge = _userData!['age'];
      } else {
        _companyNameController.text = _userData!['companyName'] ?? '';
        _contactNameController.text = _userData!['contactName'] ?? '';
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_currentUser == null || _userData == null) {
      CustomSnackBar.showError(
        context,
        message: '無法載入用戶資料',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      Map<String, dynamic> updateData = {};
      bool hasChanges = false;
      
      // 處理頭像更新
      if (_newAvatarPath != null) {
        debugPrint('開始上傳頭像: $_newAvatarPath');
        await _userService.updateUserAvatar(_currentUser!.uid, _newAvatarPath);
        debugPrint('頭像上傳成功');
        hasChanges = true;
      }
      
      // 處理其他資料更新
      if (_userData!['accountType'] == 'personal') {
        if (_nameController.text.trim().isNotEmpty && 
            _nameController.text.trim() != (_userData!['name'] ?? '')) {
          updateData['name'] = _nameController.text.trim();
        }
        if (_selectedGender != null && _selectedGender != _userData!['gender']) {
          updateData['gender'] = _selectedGender;
        }
        if (_selectedAge != null && _selectedAge != _userData!['age']) {
          updateData['age'] = _selectedAge;
        }
      } else {
        if (_companyNameController.text.trim().isNotEmpty && 
            _companyNameController.text.trim() != (_userData!['companyName'] ?? '')) {
          updateData['companyName'] = _companyNameController.text.trim();
        }
        if (_contactNameController.text.trim().isNotEmpty && 
            _contactNameController.text.trim() != (_userData!['contactName'] ?? '')) {
          updateData['contactName'] = _contactNameController.text.trim();
        }
      }

      if (updateData.isNotEmpty) {
        await _userService.updateUserData(_currentUser!.uid, updateData);
        hasChanges = true;
      }

      if (hasChanges) {
        if (mounted) {
          // 直接返回，成功訊息由 profile_page 處理
          Navigator.of(context).pop(true); // 返回 true 表示已更新
        }
      } else {
        if (mounted) {
          CustomSnackBar.showInfo(
            context,
            message: '沒有變更需要儲存',
          );
          
          // 短暫延遲讓用戶看到訊息，然後返回
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              Navigator.of(context).pop(false);
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(
          context,
          message: '更新失敗: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String? _getCurrentAvatarUrl() {
    if (_userData == null) return null;
    
    // 檢查是否有 avatar 欄位（新格式）
    if (_userData!['avatar'] != null && _userData!['avatar'].toString().isNotEmpty) {
      return _userData!['avatar'] as String;
    }
    
    // 檢查是否有 profileImages 欄位（舊格式）
    if (_userData!['profileImages'] != null) {
      final profileImages = _userData!['profileImages'] as List<dynamic>?;
      if (profileImages != null && profileImages.isNotEmpty) {
        return profileImages.first as String;
      }
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: GestureDetector(
        onTap: () {
          // 點擊空白區域時取消焦點
          FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: 24.0,
                  right: 24.0,
                  bottom: 40.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // 關閉按鈕區域 - 距離上方60px
                const SizedBox(height: 40),
                CustomButton(
                  onPressed: () {
                    // 關閉前確保取消焦點
                    FocusScope.of(context).unfocus();
                    Navigator.of(context).pop();
                  },
                  text: '關閉',
                  width: 80,
                  style: CustomButtonStyle.info,
                  borderRadius: 30.0, // 完全圓角
                ),
                
                const SizedBox(height: 24),
                
                // 標題
                const Text(
                  '編輯個人資料',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // 內容區域
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 100), // 為底部按鈕留出空間
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_userData != null) ...[
                            // 頭像編輯區域
                            Center(
                              child: Column(
                                children: [
                                  const Text(
                                    '個人頭像',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  AvatarUpload(
                                    currentAvatarUrl: _getCurrentAvatarUrl(),
                                    onAvatarChanged: (avatarPath) {
                                      setState(() {
                                        _newAvatarPath = avatarPath;
                                      });
                                    },
                                    size: 120,
                                    isEnabled: !_isSaving,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '點擊頭像來更換照片',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            
                            if (_userData!['accountType'] == 'personal') ...[
                              // 個人帳戶編輯欄位
                              CustomTextInput(
                                label: '姓名',
                                controller: _nameController,
                                isEnabled: !_isSaving,
                              ),
                              
                              const SizedBox(height: 20),
                              
                              CustomDropdown<String>(
                                label: '性別',
                                value: _selectedGender,
                                isEnabled: !_isSaving,
                                items: const [
                                  DropdownItem(value: 'male', label: '男性'),
                                  DropdownItem(value: 'female', label: '女性'),
                                  DropdownItem(value: 'other', label: '其他'),
                                  DropdownItem(value: 'prefer_not_to_say', label: '不願透露'),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedGender = value;
                                  });
                                },
                              ),
                              
                              const SizedBox(height: 20),
                              
                              CustomDropdown<int>(
                                label: '年齡',
                                value: _selectedAge,
                                isEnabled: !_isSaving,
                                items: List.generate(83, (index) => index + 18)
                                    .map((age) => DropdownItem(
                                          value: age,
                                          label: '$age 歲',
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedAge = value;
                                  });
                                },
                              ),
                            ] else ...[
                              // 企業帳戶編輯欄位
                              CustomTextInput(
                                label: '企業名稱',
                                controller: _companyNameController,
                                isEnabled: !_isSaving,
                              ),
                              
                              const SizedBox(height: 20),
                              
                              CustomTextInput(
                                label: '聯絡人',
                                controller: _contactNameController,
                                isEnabled: !_isSaving,
                              ),
                            ],
                          ] else ...[
                            const Center(
                              child: Text(
                                '無法載入用戶資料',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                
                  ],
                ),
              ),
              
              // 底部導航按鈕
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: AppColors.white,
                  child: StepNavigationButtons(
                    showPrevious: false,
                    showNext: true,
                    nextText: '儲存',
                    isNextEnabled: !_isSaving,
                    isLoading: _isSaving,
                    onNext: _saveProfile,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
