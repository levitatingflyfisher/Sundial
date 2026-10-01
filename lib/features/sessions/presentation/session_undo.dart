import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openhearth_design/openhearth_design.dart';

/// The Undo for a session deleted from Edit Session (fleet delete ruling:
/// a deliberate delete does not ask, and its Undo never times out). The
/// editor closes on delete, so the offer outlives it: it lives in a
/// provider and History shows it in an [OhUndoBar].
final sessionUndoControllerProvider = Provider<OhUndoController>((ref) {
  final controller = OhUndoController();
  ref.onDispose(controller.dispose);
  return controller;
});
