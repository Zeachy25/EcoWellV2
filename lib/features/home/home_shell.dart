import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/green_space.dart';
import '../../providers/active_visit_provider.dart';
import '../../providers/geofence_provider.dart';
import '../shared/ecowell_bottom_nav.dart';

class HomeShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const HomeShell({super.key, required this.navigationShell});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(geofenceProvider.notifier).startMonitoring();
    });
  }

  void _goBranch(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(geofenceProvider, (previous, next) {
      final entered = previous?.insideSpace == null && next.insideSpace != null;
      final exited = previous?.insideSpace != null && next.insideSpace == null;

      if (entered) {
        final active = ref.read(activeVisitProvider);
        if (active == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _promptArrival(next.insideSpace!);
          });
        }
      } else if (exited) {
        final active = ref.read(activeVisitProvider);
        if (active != null && active.preCompleted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _promptDeparture(active.greenSpace);
          });
        }
      }
    });

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: EcoWellBottomNav(
        currentIndex: widget.navigationShell.currentIndex,
        onTabSelected: _goBranch,
      ),
    );
  }

  Future<void> _promptArrival(GreenSpace space) async {
    if (!mounted) return;
    final start = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.eco, color: Colors.green),
        title: Text('Welcome to ${space.name}'),
        content: const Text(
          'You have arrived within the nature area. Take a quick pre-visit stress check before enjoying your walk?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Skip'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Start Check'),
          ),
        ],
      ),
    );
    if (start == true && mounted) {
      ref.read(activeVisitProvider.notifier).beginVisit(space);
      context.push('/assessment?mode=pre&spaceId=${space.id}');
    }
  }

  Future<void> _promptDeparture(GreenSpace space) async {
    if (!mounted) return;
    final complete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.flag, color: Colors.green),
        title: Text('Leaving ${space.name}?'),
        content: const Text(
          'Complete a quick post-visit check to see your Stress Reduction Score!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Complete Check'),
          ),
        ],
      ),
    );
    if (complete == true && mounted) {
      context.push('/assessment?mode=post&spaceId=${space.id}');
    }
  }
}