import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../models/story.dart';

class StoryAvatar extends StatelessWidget {
  final Story story;
  final VoidCallback? onTap;

  const StoryAvatar({
    super.key,
    required this.story,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (story.isUser) {
      return GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.only(right: Responsive.size(context, 12)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: Responsive.size(context, 58),
                height: Responsive.size(context, 58),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.streakOrange,
                ),
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: Responsive.size(context, 32),
                ),
              ),
              SizedBox(height: Responsive.size(context, 4)),
              Text(
                'My Day',
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, 11),
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(right: Responsive.size(context, 12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.size(context, 2.5)),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: story.hasUnseen ? AppColors.mintGreen : AppColors.cardBorder,
                  width: Responsive.size(context, 2.2),
                ),
              ),
              child: CircleAvatar(
                radius: Responsive.size(context, 26),
                backgroundColor: AppColors.mintLight,
                child: Text(
                  story.userName.isNotEmpty ? story.userName[0].toUpperCase() : 'U',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, 18),
                    fontWeight: FontWeight.bold,
                    color: AppColors.forestDark,
                  ),
                ),
              ),
            ),
            SizedBox(height: Responsive.size(context, 4)),
            Text(
              story.userName.split(' ').first,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 11),
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
