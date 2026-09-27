import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/quiet_score.dart';
import '../../core/utils/responsive.dart';
import '../../models/green_space.dart';
import '../../models/place_review.dart';
import '../../providers/active_visit_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reviews_provider.dart';
import '../../providers/visits_provider.dart';

class GreenSpaceDetailSheet extends ConsumerWidget {
  final GreenSpace space;
  final double distanceMeters;
  final VoidCallback? onUpdated;

  const GreenSpaceDetailSheet({
    super.key,
    required this.space,
    required this.distanceMeters,
    this.onUpdated,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeVisit = ref.watch(activeVisitProvider);
    final visits = ref.watch(visitsProvider).value ?? const [];
    final userReviews = ref.watch(reviewsProvider)[space.id] ?? const [];

    final quietScore = quietScoreFor(space, visits);
    final recommended = isHighlyRecommended(quietScore);
    final spaceVisits = visits
        .where((v) => v.greenSpaceId == space.id)
        .toList();
    final allReviews = [...space.reviews, ...userReviews];

    final visitingHere =
        activeVisit != null && activeVisit.greenSpace.id == space.id;

    return Padding(
      padding: EdgeInsets.only(
        left: Responsive.size(context, 24),
        right: Responsive.size(context, 24),
        top: Responsive.size(context, 16),
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: Responsive.size(context, 16)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    space.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Chip(
                  label: Text(space.category),
                  backgroundColor: const Color(0xFFE8F5E9),
                  labelStyle: const TextStyle(color: Color(0xFF2E7D32)),
                  side: BorderSide.none,
                ),
              ],
            ),
            SizedBox(height: Responsive.size(context, 4)),
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 16, color: Colors.grey),
                SizedBox(width: Responsive.size(context, 4)),
                Expanded(
                  child: Text(
                    space.address,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            if (distanceMeters >= 0) ...[
              SizedBox(height: Responsive.size(context, 4)),
              Text(
                '${Formatters.distance(distanceMeters)} from your location',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            SizedBox(height: Responsive.size(context, 16)),
            if (recommended)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.size(context, 12),
                  vertical: Responsive.size(context, 6),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(Responsive.size(context, 20)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 16, color: Color(0xFFEF6C00)),
                    SizedBox(width: Responsive.size(context, 6)),
                    const Text(
                      'Highly Recommended',
                      style: TextStyle(
                        color: Color(0xFFEF6C00),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: Responsive.size(context, 16)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  quietScore.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E7D32),
                      ),
                ),
                SizedBox(width: Responsive.size(context, 8)),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'QUIET SCORE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        'out of 5.0 · ${spaceVisits.length} visit${spaceVisits.length == 1 ? '' : 's'}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.size(context, 16)),
            _QuietMetricRow(
              icon: Icons.volume_off_outlined,
              label: 'Noise Level',
              value: space.noiseLevel.label,
            ),
            SizedBox(height: Responsive.size(context, 8)),
            _QuietMetricRow(
              icon: Icons.people_outline,
              label: 'Crowd Density',
              value: space.crowdDensity.label,
            ),
            SizedBox(height: Responsive.size(context, 8)),
            _QuietMetricRow(
              icon: Icons.self_improvement,
              label: 'Calm Factor',
              value: space.calmFactor.label,
            ),
            SizedBox(height: Responsive.size(context, 16)),
            Text(
              space.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: Responsive.size(context, 16)),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final amenity in space.amenities)
                  Chip(
                    avatar: const Icon(Icons.check,
                        size: 16, color: Color(0xFF2E7D32)),
                    label: Text(amenity),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
              ],
            ),
            SizedBox(height: Responsive.size(context, 20)),
            FilledButton.icon(
              icon: const Icon(Icons.star_border),
              label: const Text('Rate This Place'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
              ),
              onPressed: () => _openRatingDialog(context, ref),
            ),
            SizedBox(height: Responsive.size(context, 16)),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: Icon(
                      visitingHere ? Icons.flag : Icons.add_location_alt,
                    ),
                    label: Text(
                      visitingHere
                          ? (activeVisit.preCompleted
                              ? 'Complete Visit (Post-Visit Check)'
                              : 'Take Pre-Visit Check')
                          : 'Check In Here',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFEF6C00),
                    ),
                    onPressed: () {
                      if (visitingHere) {
                        final active = activeVisit;
                        context.push(
                          '/assessment?mode=${active.preCompleted ? 'post' : 'pre'}&spaceId=${space.id}',
                        );
                      } else {
                        ref.read(activeVisitProvider.notifier).beginVisit(space);
                        context.push('/assessment?mode=pre&spaceId=${space.id}');
                      }
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.size(context, 12)),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.navigation),
                    label: const Text('Navigate'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push('/navigate?spaceId=${space.id}');
                    },
                  ),
                ),
                SizedBox(width: Responsive.size(context, 8)),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.directions),
                    label: const Text('Get Directions'),
                    onPressed: _openMaps,
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.size(context, 20)),
            Row(
              children: [
                Text(
                  'User Reviews',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                if (allReviews.isNotEmpty)
                  Text(
                    '${allReviews.length} review${allReviews.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
              ],
            ),
            SizedBox(height: Responsive.size(context, 8)),
            if (allReviews.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No reviews yet. Be the first to rate this place!',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              for (final review in allReviews.take(4))
                _ReviewTile(review: review),
          ],
        ),
      ),
    );
  }

  void _openRatingDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => _RatePlaceDialog(
        space: space,
        onSubmitted: (rating, comment) async {
          final user = ref.read(authControllerProvider).user;
          final review = PlaceReview(
            spaceId: space.id,
            reviewerName: user?.name ?? 'You',
            rating: rating,
            comment: comment,
            date: DateTime.now(),
            isUser: true,
          );
          await ref.read(reviewsProvider.notifier).addReview(review);
          if (context.mounted) Navigator.of(context).pop();
          onUpdated?.call();
        },
      ),
    );
  }

  Future<void> _openMaps() async {
    final uri = Uri.parse(
      'geo:${space.latitude},${space.longitude}?q=${space.latitude},${space.longitude}(${Uri.encodeComponent(space.name)})',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _QuietMetricRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _QuietMetricRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.size(context, 12),
        vertical: Responsive.size(context, 10),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F0),
        borderRadius: BorderRadius.circular(Responsive.size(context, 12)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2E7D32)),
          SizedBox(width: Responsive.size(context, 10)),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final PlaceReview review;

  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: Responsive.size(context, 12)),
      padding: EdgeInsets.all(Responsive.size(context, 12)),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(Responsive.size(context, 12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: Responsive.size(context, 16),
                backgroundColor: const Color(0xFFE8F5E9),
                child: Text(
                  review.reviewerName.isEmpty
                      ? '?'
                      : review.reviewerName[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: Responsive.size(context, 8)),
              Expanded(
                child: Text(
                  review.reviewerName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              _Stars(rating: review.rating),
              SizedBox(width: Responsive.size(context, 6)),
              Text(
                review.rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEF6C00),
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            SizedBox(height: Responsive.size(context, 8)),
            Text(review.comment, style: Theme.of(context).textTheme.bodySmall),
          ],
          SizedBox(height: Responsive.size(context, 6)),
          Text(
            DateFormat('MMM d, yyyy').format(review.date),
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  final double rating;

  const _Stars({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= rating.round() ? Icons.star : Icons.star_border,
            size: 14,
            color: const Color(0xFFEF6C00),
          ),
      ],
    );
  }
}

class _RatePlaceDialog extends StatefulWidget {
  final GreenSpace space;
  final Future<void> Function(double rating, String comment) onSubmitted;

  const _RatePlaceDialog({required this.space, required this.onSubmitted});

  @override
  State<_RatePlaceDialog> createState() => _RatePlaceDialogState();
}

class _RatePlaceDialogState extends State<_RatePlaceDialog> {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Rate ${widget.space.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  onPressed: () => setState(() => _rating = i),
                  icon: Icon(
                    i <= _rating ? Icons.star : Icons.star_border,
                    color: const Color(0xFFEF6C00),
                    size: 32,
                  ),
                ),
            ],
          ),
          Text('$_rating / 5', style: Theme.of(context).textTheme.labelMedium),
          SizedBox(height: Responsive.size(context, 12)),
          TextField(
            controller: _commentController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Share your experience (optional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving
              ? null
              : () async {
                  setState(() => _saving = true);
                  await widget.onSubmitted(
                    _rating.toDouble(),
                    _commentController.text.trim(),
                  );
                },
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }
}