import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityHelper {
  ConnectivityHelper._();
  static final ConnectivityHelper instance = ConnectivityHelper._();

  final Connectivity _connectivity = Connectivity();

  /// Check if the device currently has an internet connection.
  Future<bool> hasInternetConnection() async {
    final results = await _connectivity.checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }

  /// Stream that emits `true` when online, `false` when offline.
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map(
      (results) => !results.contains(ConnectivityResult.none),
    );
  }
}
