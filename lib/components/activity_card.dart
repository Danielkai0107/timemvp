import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ActivityCard extends StatelessWidget {
  final String title;
  final String date;
  final String time;
  final String price;
  final String location;
  final String? imageUrl;
  final bool isPro;
  final VoidCallback? onTap;

  const ActivityCard({
    super.key,
    required this.title,
    required this.date,
    required this.time,
    required this.price,
    required this.location,
    this.imageUrl,
    this.isPro = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
            // 活動圖片
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade200,
                image: imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl == null
                  ? Icon(
                      Icons.image,
                      color: Colors.grey.shade400,
                      size: 32,
                    )
                  : null,
            ),

           const SizedBox(width: 16), 
            // 活動資訊
            Expanded(
             child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 日期和時間
                    Text(
                      '$date $time',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // 活動標題
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    // 價格、地點和 PRO 標籤
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            location.isNotEmpty ? '$price｜$location' : price,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isPro)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: SvgPicture.asset(
                              'assets/images/pro-tag.svg',
                              width: 40,
                              height: 20,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
