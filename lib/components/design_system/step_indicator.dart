import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 步驟指示器組件 - 底部顯示當前進度
class StepIndicator extends StatelessWidget {
  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.activeColor = AppColors.primary900,
    this.inactiveColor = AppColors.grey300,
    this.height = 4.0,
    this.spacing = 8.0,
  });

  /// 當前步驟（從1開始）
  final int currentStep;
  
  /// 總步驟數
  final int totalSteps;
  
  /// 活躍步驟顏色
  final Color activeColor;
  
  /// 非活躍步驟顏色
  final Color inactiveColor;
  
  /// 指示器高度
  final double height;
  
  /// 步驟間距
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Row(
        children: List.generate(totalSteps, (index) {
          final stepNumber = index + 1;
          final isActive = stepNumber <= currentStep;
          
          return Expanded(
            child: Container(
              height: height,
              margin: EdgeInsets.only(
                right: index < totalSteps - 1 ? spacing : 0,
              ),
              decoration: BoxDecoration(
                color: isActive ? activeColor : inactiveColor,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// 步驟導航按鈕組合
class StepNavigationButtons extends StatelessWidget {
  const StepNavigationButtons({
    super.key,
    this.onPrevious,
    this.onNext,
    this.onSkip,
    this.previousText = '上一步',
    this.nextText = '下一步',
    this.skipText = '跳過',
    this.showPrevious = true,
    this.showNext = true,
    this.showSkip = false,
    this.isNextEnabled = true,
    this.isLoading = false,
  });

  /// 上一步回調
  final VoidCallback? onPrevious;
  
  /// 下一步回調
  final VoidCallback? onNext;
  
  /// 跳過回調
  final VoidCallback? onSkip;
  
  /// 上一步按鈕文字
  final String previousText;
  
  /// 下一步按鈕文字
  final String nextText;
  
  /// 跳過按鈕文字
  final String skipText;
  
  /// 是否顯示上一步按鈕
  final bool showPrevious;
  
  /// 是否顯示下一步按鈕
  final bool showNext;
  
  /// 是否顯示跳過按鈕
  final bool showSkip;
  
  /// 下一步按鈕是否啟用
  final bool isNextEnabled;
  
  /// 是否顯示載入狀態
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          // 上一步按鈕
          if (showPrevious)
            Expanded(
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextButton(
                  onPressed: onPrevious,
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    overlayColor: Colors.transparent,
                  ),
                  child: Text(
                    previousText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          
          // 間距
          if (showPrevious && (showNext || showSkip))
            const SizedBox(width: 12),
          
          // 下一步按鈕（當有跳過按鈕時隱藏）
          if (showNext && !showSkip)
            Expanded(
              child: SizedBox(
                height: 60,
                child: ElevatedButton(
                  onPressed: isNextEnabled && !isLoading ? onNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isNextEnabled 
                      ? AppColors.primary900 
                      : AppColors.grey300,
                    foregroundColor: isNextEnabled ? AppColors.black : AppColors.grey700,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.black),
                        ),
                      )
                    : Text(
                        nextText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                ),
              ),
            ),
          
          // 跳過按鈕（黃色，替代 next 按鈕的位置）
          if (showSkip)
            Expanded(
              child: SizedBox(
                height: 60,
                child: ElevatedButton(
                  onPressed: onSkip,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary900,
                    foregroundColor: AppColors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    skipText,
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
    );
  }
}
