import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 骨架載入器組件
class SkeletonLoader extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.grey300.withValues(alpha: _animation.value),
            borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
          ),
        );
      },
    );
  }
}

/// 活動詳情頁面骨架UI
class ActivityDetailSkeleton extends StatelessWidget {
  const ActivityDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 主要內容區域
          Column(
            children: [
              // 活動詳情內容
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 頂部間距
                      const SizedBox(height: 140),
                      
                      // 活動封面圖片骨架
                      _buildCoverImageSkeleton(),
                      
                      // 活動內容骨架
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 活動標題骨架
                            _buildTitleSkeleton(),
                            
                            const SizedBox(height: 24),
                            
                            // 主辦者資訊卡片骨架
                            _buildOrganizerCardSkeleton(),
                            
                            const SizedBox(height: 24),
                            _buildDivider(),
                            const SizedBox(height: 24),
                            
                            // 日期時間骨架
                            _buildInfoSectionSkeleton('日期'),
                            
                            const SizedBox(height: 24),
                            _buildDivider(),
                            const SizedBox(height: 24),
                            
                            // 報名費用骨架
                            _buildInfoSectionSkeleton('報名費用'),
                            
                            const SizedBox(height: 24),
                            _buildDivider(),
                            const SizedBox(height: 24),
                            
                            // 地點資訊骨架
                            _buildInfoSectionSkeleton('地點'),
                            
                            const SizedBox(height: 24),
                            _buildDivider(),
                            const SizedBox(height: 24),
                            
                            // 人數資訊骨架
                            _buildInfoSectionSkeleton('人數'),
                            
                            const SizedBox(height: 24),
                            _buildDivider(),
                            const SizedBox(height: 24),
                            
                            // 活動介紹骨架
                            _buildDescriptionSkeleton(),
                            
                            // 底部按鈕留空間
                            const SizedBox(height: 90),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // 底部按鈕骨架
              _buildBottomBarSkeleton(),
            ],
          ),
          
          // 頂部操作欄骨架
          _buildTopBarSkeleton(),
        ],
      ),
    );
  }

  Widget _buildCoverImageSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: AspectRatio(
        aspectRatio: 5 / 3,
        child: SkeletonLoader(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildTitleSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 狀態標籤骨架
        SkeletonLoader(
          width: 80,
          height: 28,
          borderRadius: BorderRadius.circular(14),
        ),
        const SizedBox(height: 16),
        
        // 標題骨架
        SkeletonLoader(
          width: double.infinity,
          height: 32,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),
        SkeletonLoader(
          width: 200,
          height: 32,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildOrganizerCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Row(
        children: [
          // 頭像骨架
          SkeletonLoader(
            width: 50,
            height: 50,
            borderRadius: BorderRadius.circular(25),
          ),
          
          const SizedBox(width: 12),
          
          // 主辦者資訊骨架
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SkeletonLoader(
                      width: 100,
                      height: 20,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(width: 8),
                    SkeletonLoader(
                      width: 60,
                      height: 20,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ...List.generate(5, (index) => Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: SkeletonLoader(
                        width: 16,
                        height: 16,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    )),
                    const SizedBox(width: 8),
                    SkeletonLoader(
                      width: 30,
                      height: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSectionSkeleton(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SkeletonLoader(
              width: 20,
              height: 20,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(width: 8),
            SkeletonLoader(
              width: 60,
              height: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SkeletonLoader(
          width: 180,
          height: 18,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildDescriptionSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SkeletonLoader(
              width: 20,
              height: 20,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(width: 8),
            SkeletonLoader(
              width: 80,
              height: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // 多行文字骨架
        SkeletonLoader(
          width: double.infinity,
          height: 18,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),
        SkeletonLoader(
          width: double.infinity,
          height: 18,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),
        SkeletonLoader(
          width: 250,
          height: 18,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: Colors.grey.shade200,
    );
  }

  Widget _buildTopBarSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 8),
          child: Row(
            children: [
              // 返回按鈕骨架
              SkeletonLoader(
                width: 48,
                height: 48,
                borderRadius: BorderRadius.circular(24),
              ),
              
              const Spacer(),
              
              // 操作按鈕骨架
              SkeletonLoader(
                width: 120,
                height: 48,
                borderRadius: BorderRadius.circular(24),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBarSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 16),
          child: Row(
            children: [
              // 價格信息骨架
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SkeletonLoader(
                    width: 80,
                    height: 16,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 4),
                  SkeletonLoader(
                    width: 100,
                    height: 24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
              
              const Spacer(),
              
              // 按鈕骨架
              SkeletonLoader(
                width: 140,
                height: 54,
                borderRadius: BorderRadius.circular(27),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
