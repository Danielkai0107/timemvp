import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 成功彈窗組件
/// 可用於各種成功提示場景，如發布成功、註冊成功等
class SuccessPopup extends StatelessWidget {
  const SuccessPopup({
    super.key,
    required this.title,
    required this.message,
    required this.buttonText,
    required this.onButtonPressed,
    this.showCloseButton = true,
    this.onClosePressed,
  });

  /// 標題文字
  final String title;
  
  /// 訊息內容
  final String message;
  
  /// 按鈕文字
  final String buttonText;
  
  /// 按鈕點擊回調
  final VoidCallback onButtonPressed;
  
  /// 是否顯示關閉按鈕
  final bool showCloseButton;
  
  /// 關閉按鈕點擊回調
  final VoidCallback? onClosePressed;

  /// 顯示發布成功彈窗（從底部彈出）
  static void showPublishSuccess(
    BuildContext context, {
    VoidCallback? onConfirm,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => BottomSuccessPopup(
        title: '發佈成功',
        message: '您的活動已成功發佈，\n可在我的活動中查看內容。',
        buttonText: '我知道了',
        onButtonPressed: onConfirm ?? () => Navigator.of(context).pop(),
        onClosePressed: onConfirm ?? () => Navigator.of(context).pop(),
      ),
    );
  }

  /// 顯示註冊成功彈窗
  static void showRegistrationSuccess(
    BuildContext context, {
    VoidCallback? onConfirm,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SuccessPopup(
        title: '註冊成功',
        message: '歡迎加入 TimeApp！\n您可以開始使用所有功能。',
        buttonText: '開始使用',
        onButtonPressed: onConfirm ?? () => Navigator.of(context).pop(),
        onClosePressed: onConfirm ?? () => Navigator.of(context).pop(),
      ),
    );
  }

  /// 顯示一般成功彈窗
  static void show(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = '確定',
    VoidCallback? onConfirm,
    bool showCloseButton = true,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SuccessPopup(
        title: title,
        message: message,
        buttonText: buttonText,
        onButtonPressed: onConfirm ?? () => Navigator.of(context).pop(),
        showCloseButton: showCloseButton,
        onClosePressed: onConfirm ?? () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 關閉按鈕
            if (showCloseButton)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: onClosePressed ?? () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 20,
                        color: AppColors.grey500,
                      ),
                    ),
                  ),
                ],
              ),
            
            if (showCloseButton) const SizedBox(height: 20),
            
            // 成功圖標
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success900.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.check_circle,
                size: 48,
                color: AppColors.success900,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 標題
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // 訊息內容
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 確認按鈕
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onButtonPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary900,
                  foregroundColor: AppColors.textPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 成功彈窗建構器
class SuccessPopupBuilder {
  /// 發布活動成功
  static void publishActivity(
    BuildContext context, {
    VoidCallback? onConfirm,
  }) {
    SuccessPopup.showPublishSuccess(context, onConfirm: onConfirm);
  }

  /// 註冊成功
  static void registration(
    BuildContext context, {
    VoidCallback? onConfirm,
  }) {
    SuccessPopup.showRegistrationSuccess(context, onConfirm: onConfirm);
  }

  /// 自定義成功彈窗
  static void custom(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = '確定',
    VoidCallback? onConfirm,
    bool showCloseButton = true,
  }) {
    SuccessPopup.show(
      context,
      title: title,
      message: message,
      buttonText: buttonText,
      onConfirm: onConfirm,
      showCloseButton: showCloseButton,
    );
  }

  /// KYC 提交成功
  static void kycSubmitted(
    BuildContext context, {
    VoidCallback? onConfirm,
  }) {
    SuccessPopup.show(
      context,
      title: '提交成功',
      message: '您的認證資料已成功提交，\n我們會在 3-7 天內完成審核。',
      buttonText: '我知道了',
      onConfirm: onConfirm,
    );
  }

  /// 企業註冊成功
  static void businessRegistration(
    BuildContext context, {
    VoidCallback? onConfirm,
  }) {
    SuccessPopup.show(
      context,
      title: '申請成功',
      message: '您的企業帳戶申請已成功提交，\n審核通過後我們會通知您。',
      buttonText: '前往登入',
      onConfirm: onConfirm,
    );
  }

  /// 活動報名成功
  static void activityRegistration(
    BuildContext context, {
    VoidCallback? onConfirm,
  }) {
    SuccessPopup.show(
      context,
      title: '報名成功',
      message: '您已成功報名此活動，\n請準時參加。',
      buttonText: '查看活動',
      onConfirm: onConfirm,
    );
  }

  /// 活動報名成功（底部彈出）
  static void activityRegistrationBottom(
    BuildContext context, {
    VoidCallback? onConfirm,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => BottomSuccessPopup(
        title: '報名成功',
        message: '您已成功報名此活動，\n請準時參加。',
        buttonText: '我知道了',
        onButtonPressed: onConfirm ?? () => Navigator.of(context).pop(),
        onClosePressed: onConfirm ?? () => Navigator.of(context).pop(),
      ),
    );
  }

  /// 付款成功
  static void paymentSuccess(
    BuildContext context, {
    VoidCallback? onConfirm,
  }) {
    SuccessPopup.show(
      context,
      title: '付款成功',
      message: '您的付款已成功處理，\n感謝您的使用。',
      buttonText: '完成',
      onConfirm: onConfirm,
    );
  }

  /// 取消發布確認
  static void cancelPublish(
    BuildContext context, {
    VoidCallback? onConfirm,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => BottomCancelConfirmationPopup(
        title: '取消發布',
        message: '確定要取消發布這個活動嗎？\n此操作無法復原。',
        confirmText: '確定取消',
        onConfirm: onConfirm ?? () => Navigator.of(context).pop(),
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  /// 取消報名確認
  static void cancelRegistration(
    BuildContext context, {
    VoidCallback? onConfirm,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => BottomCancelConfirmationPopup(
        title: '取消報名',
        message: '確定要取消報名這個活動嗎？',
        confirmText: '確定取消',
        onConfirm: onConfirm ?? () => Navigator.of(context).pop(),
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }
}

/// 底部成功彈窗組件（從底部彈出）
class BottomSuccessPopup extends StatelessWidget {
  const BottomSuccessPopup({
    super.key,
    required this.title,
    required this.message,
    required this.buttonText,
    required this.onButtonPressed,
    this.showCloseButton = true,
    this.onClosePressed,
  });

  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onButtonPressed;
  final bool showCloseButton;
  final VoidCallback? onClosePressed;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          
          // 關閉按鈕
          if (showCloseButton)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: onClosePressed ?? () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 20,
                        color: AppColors.grey500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // 內容區域
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
            child: Column(
              children: [
                // 標題
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // 訊息內容
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // 確認按鈕
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onButtonPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary900,
                      foregroundColor: AppColors.textPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      buttonText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 底部安全區域
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

/// 底部取消確認彈窗組件（從底部彈出）
class BottomCancelConfirmationPopup extends StatelessWidget {
  const BottomCancelConfirmationPopup({
    super.key,
    required this.title,
    required this.message,
    required this.confirmText,
    required this.onConfirm,
    required this.onCancel,
    this.showCloseButton = true,
  });

  final String title;
  final String message;
  final String confirmText;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool showCloseButton;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          
          // 關閉按鈕
          if (showCloseButton)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: onCancel,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 20,
                        color: AppColors.grey500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // 內容區域
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
            child: Column(
              children: [
                // 標題
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // 訊息內容
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // 按鈕組
                Row(
                  children: [
                    // 取消按鈕
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: onCancel,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.grey100,
                            foregroundColor: AppColors.textSecondary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            '取消',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // 確定按鈕
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: onConfirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error900,
                            foregroundColor: AppColors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            confirmText,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // 底部安全區域
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

/// 取消確認彈窗組件（已棄用，保留向後兼容）
class CancelConfirmationPopup extends StatelessWidget {
  const CancelConfirmationPopup({
    super.key,
    required this.title,
    required this.message,
    required this.confirmText,
    required this.onConfirm,
    required this.onCancel,
    this.showCloseButton = true,
  });

  final String title;
  final String message;
  final String confirmText;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool showCloseButton;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 關閉按鈕
            if (showCloseButton)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: onCancel,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 20,
                        color: AppColors.grey500,
                      ),
                    ),
                  ),
                ],
              ),
            
            if (showCloseButton) const SizedBox(height: 20),
            
            // 警告圖標
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error900.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.warning_rounded,
                size: 48,
                color: AppColors.error900,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 標題
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // 訊息內容
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 按鈕組
            Row(
              children: [
                // 取消按鈕
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: onCancel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.grey100,
                        foregroundColor: AppColors.textSecondary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '取消',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // 確定按鈕
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error900,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        confirmText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
