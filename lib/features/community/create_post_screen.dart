import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/green_space.dart';
import '../../providers/app_providers.dart';
import '../../providers/community_provider.dart';
import '../shared/ecowell_app_bar.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _captionController = TextEditingController();
  GreenSpace? _selectedSpace;
  final double _rating = 4.8;
  String _selectedPhotoAsset = 'assets/images/Explore.png';

  final List<String> _photoOptions = const [
    'assets/images/Explore.png',
    'assets/images/home.png',
    'assets/images/place rating.png',
  ];

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spaces = ref.watch(greenSpacesProvider);
    _selectedSpace ??= spaces.isNotEmpty ? spaces.first : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const EcoWellAppBar(
        title: 'Create Nature Post',
        showBack: true,
        showNotifications: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Selected Photo Preview with switcher
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: AppColors.mintLight,
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(
                  _selectedPhotoAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.add_a_photo_rounded, color: AppColors.forestMid, size: 48),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Photo thumbnails picker
            SizedBox(
              height: 60,
              child: Row(
                children: _photoOptions.map((assetPath) {
                  final isSelected = _selectedPhotoAsset == assetPath;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedPhotoAsset = assetPath),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.mintGreen : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(assetPath, fit: BoxFit.cover),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 18),

            // Green space location picker
            const Text(
              'Select Green Space Location',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<GreenSpace>(
                  value: _selectedSpace,
                  isExpanded: true,
                  items: spaces.map((space) {
                    return DropdownMenuItem(
                      value: space,
                      child: Text(space.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSpace = val);
                  },
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Caption Text Input
            const Text(
              'Your Nature Reflection',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _captionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe how this nature visit helped your calm and mental wellness...',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textTertiary),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.inputBorder),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Publish Button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  final space = _selectedSpace;
                  if (space == null) return;

                  ref.read(communityProvider.notifier).addNewPost(
                        locationName: space.name,
                        locationAddress: space.address,
                        caption: _captionController.text.trim().isEmpty
                            ? 'Peaceful nature session at ${space.name} 🌿✨'
                            : _captionController.text.trim(),
                        rating: _rating,
                        imageUrl: _selectedPhotoAsset,
                      );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Post published to EcoWell community!')),
                  );

                  context.go('/community');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text(
                  'Share with Community',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
