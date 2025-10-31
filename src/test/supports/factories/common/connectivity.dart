import 'package:another_me/domains/common/connectivity.dart';

import '../common.dart';

typedef NetworkConnectivityServiceOverrides = ({bool? isOnline});

class _NetworkConnectivityService implements NetworkConnectivityService {
  final bool _isOnline;

  _NetworkConnectivityService({required bool isOnline}) : _isOnline = isOnline;

  @override
  Future<bool> isOnline() {
    return Future.value(_isOnline);
  }

  @override
  Future<bool> isOffline() {
    return Future.value(!_isOnline);
  }
}

class NetworkConnectivityServiceFactory
    extends
        Factory<
          NetworkConnectivityService,
          NetworkConnectivityServiceOverrides
        > {
  @override
  NetworkConnectivityService create({
    NetworkConnectivityServiceOverrides? overrides,
    required int seed,
  }) {
    final isOnline = overrides?.isOnline ?? (seed % 2 == 0);

    return _NetworkConnectivityService(isOnline: isOnline);
  }

  @override
  NetworkConnectivityService duplicate(
    NetworkConnectivityService instance,
    NetworkConnectivityServiceOverrides? overrides,
  ) {
    throw UnimplementedError();
  }
}
