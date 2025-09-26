import 'package:flutter/material.dart';

/// 步驟指示器組件 - 底部顯示當前進度
class StepIndicator extends StatelessWidget {
  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.activeColor = const Color(0xFFFFBE0A),
    this.inactiveColor = const Color(0xFFE0E0E0),
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
    this.previousText = '上一步',
    this.nextText = '下一步',
    this.showPrevious = true,
    this.showNext = true,
    this.isNextEnabled = true,
    this.isLoading = false,
  });

  /// 上一步回調
  final VoidCallback? onPrevious;
  
  /// 下一步回調
  final VoidCallback? onNext;
  
  /// 上一步按鈕文字
  final String previousText;
  
  /// 下一步按鈕文字
  final String nextText;
  
  /// 是否顯示上一步按鈕
  final bool showPrevious;
  
  /// 是否顯示下一步按鈕
  final bool showNext;
  
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
                  border: Border.all(color: Colors.grey[300]!),
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
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          
          // 間距
          if (showPrevious && showNext)
            const SizedBox(width: 16),
          
          // 下一步按鈕
          if (showNext)
            Expanded(
              child: Container(
                height: 60,
                child: ElevatedButton(
                  onPressed: isNextEnabled && !isLoading ? onNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isNextEnabled 
                      ? const Color(0xFFFFBE0A) 
                      : Colors.grey[300],
                    foregroundColor: isNextEnabled ? Colors.black : Colors.grey[600],
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
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
        ],
      ),
    );
  }
}
