import 'package:flutter_test/flutter_test.dart';

import '../../../supports/factories/common.dart';
import '../../../supports/factories/common/connectivity.dart';

void main() {
  group('Package domains/common/connectivity', () {
    group('NetworkConnectivityService', () {
      test('returns online status when configured as online.', () async {
        final service = Builder(
          NetworkConnectivityServiceFactory(),
        ).buildWith(overrides: (isOnline: true), seed: 1);

        final isOnline = await service.isOnline();
        final isOffline = await service.isOffline();

        expect(isOnline, isTrue);
        expect(isOffline, isFalse);
      });

      test('returns offline status when configured as offline.', () async {
        final service = Builder(
          NetworkConnectivityServiceFactory(),
        ).buildWith(overrides: (isOnline: false), seed: 1);

        final isOnline = await service.isOnline();
        final isOffline = await service.isOffline();

        expect(isOnline, isFalse);
        expect(isOffline, isTrue);
      });

      test('isOffline returns negation of isOnline.', () async {
        final service = Builder(
          NetworkConnectivityServiceFactory(),
        ).buildWith(overrides: (isOnline: true), seed: 1);

        final isOnline = await service.isOnline();
        final isOffline = await service.isOffline();

        expect(isOffline, equals(!isOnline));
      });

      test('generates online status based on seed when no override.', () async {
        final serviceEvenSeed = Builder(
          NetworkConnectivityServiceFactory(),
        ).buildWith(seed: 2);

        final serviceOddSeed = Builder(
          NetworkConnectivityServiceFactory(),
        ).buildWith(seed: 3);

        final isOnlineEven = await serviceEvenSeed.isOnline();
        final isOnlineOdd = await serviceOddSeed.isOnline();

        expect(isOnlineEven, isTrue);
        expect(isOnlineOdd, isFalse);
      });
    });
  });
}
