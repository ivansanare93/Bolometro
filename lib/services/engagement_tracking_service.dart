import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';

import 'firestore_service.dart';

/// Registra minutos de uso activo de la app por usuario autenticado.
class EngagementTrackingService with WidgetsBindingObserver {
  static final EngagementTrackingService _instance =
      EngagementTrackingService._internal();
  factory EngagementTrackingService() => _instance;
  EngagementTrackingService._internal();

  final FirestoreService _firestoreService = FirestoreService();

  String? _userId;
  Timer? _flushTimer;
  DateTime? _activeSince;
  bool _observerRegistered = false;
  bool _isFlushing = false;
  int _pendingMinutes = 0;

  Future<void> startTracking(String userId) async {
    if (_userId == userId && _flushTimer != null) return;

    await stopTracking();
    _userId = userId;

    if (!_observerRegistered) {
      WidgetsBinding.instance.addObserver(this);
      _observerRegistered = true;
    }

    _activeSince = DateTime.now();
    _flushTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      unawaited(
        _flushAccumulatedMinutes().catchError((error) {
          debugPrint('Error flushing engagement minutes: $error');
        }),
      );
    });
  }

  Future<void> stopTracking() async {
    await _flushAccumulatedMinutes();
    _flushTimer?.cancel();
    _flushTimer = null;
    _activeSince = null;
    _userId = null;
    _pendingMinutes = 0;

    if (_observerRegistered) {
      WidgetsBinding.instance.removeObserver(this);
      _observerRegistered = false;
    }
  }

  Future<void> _flushAccumulatedMinutes() async {
    if (_isFlushing) return;

    final userId = _userId;
    final activeSince = _activeSince;
    if (userId == null || activeSince == null) return;

    _isFlushing = true;
    try {
      final now = DateTime.now();
      final elapsed = now.difference(activeSince);
      final elapsedMinutes = elapsed.inMinutes;
      final totalMinutes = _pendingMinutes + elapsedMinutes;
      if (totalMinutes <= 0) return;

      _activeSince = now;
      final persisted = await _firestoreService.registrarActividadDiaria(
        userId,
        minutesToAdd: totalMinutes,
      );
      _pendingMinutes = persisted ? 0 : totalMinutes;
    } finally {
      _isFlushing = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _activeSince ??= DateTime.now();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        unawaited(
          _flushAccumulatedMinutes().catchError((error) {
            debugPrint('Error flushing engagement minutes on lifecycle: $error');
          }),
        );
        _activeSince = null;
        break;
    }
  }
}
