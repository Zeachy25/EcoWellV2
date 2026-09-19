import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../models/green_space.dart';

class QuietScoreDialog extends StatefulWidget {
  final GreenSpace space;

  const QuietScoreDialog({super.key, required this.space});

  static Future<void> show(BuildContext context, {required GreenSpace space}) {
    return showDialog(
      context: context,
      builder: (context) => QuietScoreDialog(space: space),
    );
  }

  @override
  State<QuietScoreDialog> createState() => _QuietScoreDialogState();
}

class _QuietScoreDialogState extends State<QuietScoreDialog> {
  int _quietRating = 5;
  int _noiseLevel = 2; // 1-5
  int _crowdDensity = 2; // 1-5
  final TextEditingController _commentController = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(context, 20))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: AppColors.primaryGreen, size: Responsive.size(context, 54)),
            SizedBox(height: Responsive.size(context, 14)),
            Text(
              'Thank You!',
              style: TextStyle(fontSize: Responsive.fontSize(context, 18), fontWeight: FontWeight.w800, fontFamily: 'serif'),
            ),
            SizedBox(height: Responsive.size(context, 6)),
            Text(
              'Your Quiet Score & perception rating has been contributed to the community database.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: Responsive.fontSize(context, 13), color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(context, 24))),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(Responsive.size(context, 20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Rate ${widget.space.name}',
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, 16),
                        fontWeight: FontWeight.w800,
                        fontFamily: 'serif',
                        color: AppColors.forestDark,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: Responsive.size(context, 8)),
              Text(
                'Quiet Score (1-5 Stars)',
                style: TextStyle(fontSize: Responsive.fontSize(context, 13), fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              SizedBox(height: Responsive.size(context, 4)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final score = index + 1;
                  return GestureDetector(
                    onTap: () => setState(() => _quietRating = score),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        score <= _quietRating ? Icons.star : Icons.star_border,
                        color: AppColors.goldStar,
                        size: Responsive.size(context, 32),
                      ),
                    ),
                  );
                }),
              ),
              Center(
                child: Text(
                  '$_quietRating / 5 Stars',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.forestDark),
                ),
              ),

              SizedBox(height: Responsive.size(context, 16)),
              _buildSliderRow('Perceived Noise Level', _noiseLevel, (val) => setState(() => _noiseLevel = val.toInt())),
              SizedBox(height: Responsive.size(context, 12)),
              _buildSliderRow('Perceived Crowd Density', _crowdDensity, (val) => setState(() => _crowdDensity = val.toInt())),

              SizedBox(height: Responsive.size(context, 16)),
              Text(
                'Add a Note (Optional)',
                style: TextStyle(fontSize: Responsive.fontSize(context, 13), fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              SizedBox(height: Responsive.size(context, 6)),
              TextField(
                controller: _commentController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Share tips about benches, shade, or best visiting hours...',
                  hintStyle: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                  fillColor: AppColors.inputFill,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Responsive.radius(context, 12)),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                ),
              ),

              SizedBox(height: Responsive.size(context, 20)),
              SizedBox(
                width: double.infinity,
                height: Responsive.size(context, 46),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _submitted = true);
                    Future.delayed(const Duration(seconds: 2), () {
                      if (context.mounted) Navigator.pop(context);
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forestDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.radius(context, 12))),
                  ),
                  child: const Text('Submit Rating', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliderRow(String label, int value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            Text('$value/5', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.forestDark)),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          activeColor: AppColors.mintGreen,
          inactiveColor: AppColors.mintLight,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
