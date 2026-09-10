import 'package:flutter/services.dart';

class HapticsService {
  const HapticsService();

  Future<void> tap({required bool enabled}) async {
    if (enabled) await HapticFeedback.selectionClick();
  }

  Future<void> success({required bool enabled}) async {
    if (enabled) await HapticFeedback.mediumImpact();
  }
}
