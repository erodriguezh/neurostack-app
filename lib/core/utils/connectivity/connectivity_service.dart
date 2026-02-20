import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

enum NetworkStatus { online, offline }

class ConnectivityService {
  ConnectivityService(this._connectivity);

  final Connectivity _connectivity;
  final ValueNotifier<NetworkStatus> status = ValueNotifier<NetworkStatus>(
    NetworkStatus.online,
  );

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Future<void> init() async {
    final initial = await _connectivity.checkConnectivity();
    _updateStatus(initial);
    _subscription?.cancel();
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void dispose() {
    _subscription?.cancel();
    status.dispose();
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final nextStatus =
        results.isEmpty || results.contains(ConnectivityResult.none)
        ? NetworkStatus.offline
        : NetworkStatus.online;
    if (status.value != nextStatus) {
      status.value = nextStatus;
    }
  }
}
