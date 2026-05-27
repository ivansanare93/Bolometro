import 'dart:async';

import 'package:flutter/widgets.dart';

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
      _flushAccumulatedMinutes();
    });
  }

  Future<void> stopTracking() async {
    await _flushAccumulatedMinutes();
    _flushTimer?.cancel();
    _flushTimer = null;
    _activeSince = null;
    _userId = null;

    if (_observerRegistered) {
      WidgetsBinding.instance.removeObserver(this);
      _observerRegistered = false;
    }
  }

  Future<void> _flushAccumulatedMinutes() async {
    final userId = _userId;
    final activeSince = _activeSince;
    if (userId == null || activeSince == null) return;

    final now = DateTime.now();
    final elapsed = now.difference(activeSince);
    final elapsedMinutes = elapsed.inMinutes;
    if (elapsedMinutes <= 0) return;

    _activeSince = activeSince.add(Duration(minutes: elapsedMinutes));
    await _firestoreService.registrarActividadDiaria(
      userId,
      minutesToAdd: elapsedMinutes,
    );
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
        _flushAccumulatedMinutes();
        _activeSince = null;
        break;
    }
  }
}
