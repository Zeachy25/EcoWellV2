import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../providers/active_visit_provider.dart';

class ActiveVisitBanner extends StatelessWidget {
  final ActiveVisit visit;

  const ActiveVisitBanner({super.key, required this.visit});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFF3E0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.timelapse, color: Color(0xFFEF6C00)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    visit.preCompleted
                        ? 'Visiting ${visit.greenSpace.name}'
                        : 'Checked in at ${visit.greenSpace.name}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: Text(
                visit.preCompleted
                    ? 'Complete Post-Visit Check'
                    : 'Take Pre-Visit Check',
              ),
              onPressed: () => context.push(
                '/assessment?mode=${visit.preCompleted ? 'post' : 'pre'}&spaceId=${visit.greenSpace.id}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}