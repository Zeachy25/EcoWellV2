import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_providers.dart';

/// Remembered position of the draggable AI mascot.
///
/// The value is normalized to 0..1 on both axes so the mascot keeps the same
/// relative spot on other screen sizes and after rotation. Null means the user
/// has never moved it, so the widget can fall back to its default spot.
class AiMascotPositionController extends Notifier<Offset?> {
  @override
  Offset? build() => ref.watch(localStoreProvider).aiMascotPosition;

  /// Stores the finalized position once the user lets go of the mascot.
  ///
  /// Only called on drag end: writing on every pan update would persist and
  /// rebuild on every frame of the drag.
  Future<void> save(Offset position) async {
    final clamped = Offset(
      position.dx.clamp(0.0, 1.0),
      position.dy.clamp(0.0, 1.0),
    );
    state = clamped;
    await ref.read(localStoreProvider).saveAiMascotPosition(clamped);
  }
}

final aiMascotPositionProvider =
    NotifierProvider<AiMascotPositionController, Offset?>(
      AiMascotPositionController.new,
    );
