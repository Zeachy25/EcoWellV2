import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/green_space.dart';
import '../../providers/active_visit_provider.dart';
import '../../providers/geofence_provider.dart';
import '../shared/ecowell_ai_mascot.dart';
import '../shared/ecowell_bottom_nav.dart';

/// What the geofence listener should act on for a state update.
enum GeofenceAction {
  none,
  promptArrival,
  promptDeparture,
  clearAbandonedVisit,
}

/// Pure decision logic for the geofence listener.
///
/// Entering a fenced area prompts the pre-visit assessment unless a visit is
/// already active; leaving prompts the post-visit assessment only once the
/// pre check has been completed. Leaving while a check-in was never finished
/// clears that abandoned visit, so returning to the place prompts again.
/// Kept as a pure function so the trigger behavior can be unit tested.
GeofenceAction resolveGeofenceAction(
  GeofenceState? previous,
  GeofenceState next,
  ActiveVisit? active,
) {
  final entered = previous?.insideSpace == null && next.insideSpace != null;
  final exited = previous?.insideSpace != null && next.insideSpace == null;

  if (entered) {
    return active == null
        ? GeofenceAction.promptArrival
        : GeofenceAction.none;
  }
  if (exited) {
    if (active == null) return GeofenceAction.none;
    return active.preCompleted
        ? GeofenceAction.promptDeparture
        : GeofenceAction.clearAbandonedVisit;
  }
  return GeofenceAction.none;
}

class HomeShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const HomeShell({super.key, required this.navigationShell});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  /// The space the current arrival prompt is about, whether it is still queued
  /// or already on screen.
  GreenSpace? _arrivalSpace;

  /// Whether the arrival dialog route is actually pushed.
  bool _arrivalShown = false;

  /// Consecutive fixes outside [_arrivalSpace] since the dialog appeared.
  /// Requiring two keeps GPS noise from closing the dialog instantly.
  int _outsideFixCount = 0;

  /// Context of the pushed dialog, used to pop it.
  BuildContext? _arrivalDialogContext;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(geofenceProvider.notifier).startMonitoring();
    });
  }

  @override
  void dispose() {
    _arrivalSpace = null;
    _arrivalShown = false;
    _outsideFixCount = 0;
    _arrivalDialogContext = null;
    super.dispose();
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
      _trackArrivalPrompt(next);

      final action = resolveGeofenceAction(
        previous,
        next,
        ref.read(activeVisitProvider),
      );

      if (action == GeofenceAction.promptArrival) {
        _arrivalSpace = next.insideSpace;
        _outsideFixCount = 0;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(_showArrivalDialog());
        });
      } else if (action == GeofenceAction.promptDeparture) {
        final active = ref.read(activeVisitProvider);
        if (active == null) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(_promptDeparture(active.greenSpace));
        });
      } else if (action == GeofenceAction.clearAbandonedVisit) {
        // The user left before finishing the pre check, so the check-in is
        // dropped and returning to the place prompts again.
        ref.read(activeVisitProvider.notifier).cancel();
      }
    });

    return Stack(
      children: [
        Scaffold(
          body: widget.navigationShell,
          bottomNavigationBar: EcoWellBottomNav(
            currentIndex: widget.navigationShell.currentIndex,
            onTabSelected: _goBranch,
          ),
        ),
        // Wraps the Scaffold rather than sitting in the body so the mascot can
        // float over the bottom nav too. Dialogs are pushed on the root
        // navigator, so they still appear above it.
        const Positioned.fill(child: DraggableEcoWellAiMascot()),
      ],
    );
  }

  /// Keeps the arrival prompt in step with where the user actually is: shows it
  /// immediately on arrival, and takes it away again once the exit is
  /// confirmed by two fixes outside the place.
  void _trackArrivalPrompt(GeofenceState next) {
    final space = _arrivalSpace;
    if (space == null) return;
    if (next.insideSpace?.id == space.id) {
      _outsideFixCount = 0;
      return;
    }
    if (_arrivalShown) {
      if (++_outsideFixCount >= 2) _resetArrival();
    } else {
      // Queued but not yet rendered, so it can simply be dropped.
      _resetArrival();
    }
  }

  /// Clears the arrival prompt, dismissing the dialog if it is on screen.
  void _resetArrival() {
    _arrivalSpace = null;
    _outsideFixCount = 0;
    _closeArrivalDialog();
  }

  /// Single exit point for the arrival dialog, shared by the buttons and the
  /// auto-dismiss, so a tap landing in the same frame as a position update
  /// cannot pop the dialog twice.
  void _closeArrivalDialog({bool? result}) {
    if (!_arrivalShown) return;
    _arrivalShown = false;
    final dialogContext = _arrivalDialogContext;
    _arrivalDialogContext = null;
    if (dialogContext != null &&
        dialogContext.mounted &&
        (ModalRoute.of(dialogContext)?.isCurrent ?? false)) {
      Navigator.of(dialogContext, rootNavigator: true).pop(result);
    }
  }

  Future<void> _showArrivalDialog() async {
    final space = _arrivalSpace;
    if (space == null || _arrivalShown || !mounted) return;
    // The user may already have walked back out before this frame ran.
    if (ref.read(geofenceProvider).insideSpace?.id != space.id) {
      _resetArrival();
      return;
    }
    _arrivalShown = true;
    _outsideFixCount = 0;
    final start = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        _arrivalDialogContext = dialogContext;
        return AlertDialog(
          icon: const Icon(Icons.eco, color: Colors.green),
          title: Text('Welcome to ${space.name}'),
          content: const Text(
            'You have arrived within the nature area. Take a quick pre-visit stress check before enjoying your walk?',
          ),
          actions: [
            TextButton(
              onPressed: () => _closeArrivalDialog(result: false),
              child: const Text('Skip'),
            ),
            FilledButton(
              onPressed: () => _closeArrivalDialog(result: true),
              child: const Text('Start Check'),
            ),
          ],
        );
      },
    );
    _arrivalDialogContext = null;
    _arrivalShown = false;
    if (_arrivalSpace?.id == space.id) {
      _arrivalSpace = null;
      _outsideFixCount = 0;
    }
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