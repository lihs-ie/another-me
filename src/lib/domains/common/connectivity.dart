abstract interface class NetworkConnectivityService {
  Future<bool> isOnline();

  Future<bool> isOffline();
}
