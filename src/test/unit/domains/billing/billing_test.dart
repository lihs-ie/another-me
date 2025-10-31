import 'package:another_me/domains/billing/billing.dart';
import 'package:another_me/domains/common/error.dart';
import 'package:another_me/domains/common/variant.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulid/ulid.dart';

import '../../../supports/factories/billing/billing.dart';
import '../../../supports/factories/common.dart';
import '../common/identifier.dart';
import '../common/value_object.dart';

void main() {
  group('Package domains/billing', () {
    ulidBasedIdentifierTest<PlanIdentifier, Ulid>(
      constructor: (Ulid value) => PlanIdentifier(value: value),
      generate: PlanIdentifier.generate,
      fromString: PlanIdentifier.fromString,
      fromBinary: PlanIdentifier.fromBinary,
    );

    ulidBasedIdentifierTest<SubscriptionIdentifier, Ulid>(
      constructor: (Ulid value) => SubscriptionIdentifier(value: value),
      generate: SubscriptionIdentifier.generate,
      fromString: SubscriptionIdentifier.fromString,
      fromBinary: SubscriptionIdentifier.fromBinary,
    );

    ulidBasedIdentifierTest<TransactionIdentifier, Ulid>(
      constructor: (Ulid value) => TransactionIdentifier(value: value),
      generate: TransactionIdentifier.generate,
      fromString: TransactionIdentifier.fromString,
      fromBinary: TransactionIdentifier.fromBinary,
    );

    ulidBasedIdentifierTest<EntitlementIdentifier, Ulid>(
      constructor: (Ulid value) => EntitlementIdentifier(value: value),
      generate: EntitlementIdentifier.generate,
      fromString: EntitlementIdentifier.fromString,
      fromBinary: EntitlementIdentifier.fromBinary,
    );

    group('PlanStatus', () {
      test('declares all defined enumerators.', () {
        expect(PlanStatus.active, isA<PlanStatus>());
        expect(PlanStatus.deprecated, isA<PlanStatus>());
      });
    });

    group('SubscriptionStatus', () {
      test('declares all defined enumerators.', () {
        expect(SubscriptionStatus.active, isA<SubscriptionStatus>());
        expect(SubscriptionStatus.expired, isA<SubscriptionStatus>());
        expect(SubscriptionStatus.grace, isA<SubscriptionStatus>());
        expect(SubscriptionStatus.canceled, isA<SubscriptionStatus>());
      });
    });

    group('EntitlementStatus', () {
      test('declares all defined enumerators.', () {
        expect(EntitlementStatus.active, isA<EntitlementStatus>());
        expect(EntitlementStatus.restricted, isA<EntitlementStatus>());
      });
    });

    group('OverLimitType', () {
      test('declares all defined enumerators.', () {
        expect(OverLimitType.tracks, isA<OverLimitType>());
        expect(OverLimitType.characters, isA<OverLimitType>());
      });
    });

    valueObjectTest<Price, ({double amount}), ({double amount})>(
      constructor: (props) => Price.create(amount: props.amount),
      generator: () => (amount: 100.0),
      variations: (props) => [(amount: 0.0), (amount: 500.0), (amount: 999.99)],
      invalids: (props) => [(amount: -1.0), (amount: -100.0)],
      additionalTests: () {
        group('free', () {
          test('creates price with amount 0.', () {
            final price = Price.free();
            expect(price.amount, equals(0.0));
          });
        });
      },
    );

    valueObjectTest<Currency, ({String code}), ({String code})>(
      constructor: (props) => Currency.create(props.code),
      generator: () => (code: 'USD'),
      variations: (props) => [(code: 'JPY'), (code: 'EUR'), (code: 'GBP')],
      invalids: (props) => [
        (code: ''),
        (code: 'US'),
        (code: 'USDA'),
        (code: 'usd'),
        (code: 'Us1'),
      ],
    );

    group('Limit', () {
      test('limited creates limit with value.', () {
        final limit = Limit.limited(5);

        expect(limit.value, equals(5));
        expect(limit.isUnlimited, isFalse);
      });

      test('unlimited creates limit without value.', () {
        final limit = Limit.unlimited();

        expect(limit.value, isNull);
        expect(limit.isUnlimited, isTrue);
      });

      test('allows returns true when current is below limit.', () {
        final limit = Limit.limited(5);

        expect(limit.allows(0), isTrue);
        expect(limit.allows(4), isTrue);
      });

      test('allows returns false when current equals or exceeds limit.', () {
        final limit = Limit.limited(5);

        expect(limit.allows(5), isFalse);
        expect(limit.allows(6), isFalse);
      });

      test('allows returns true for unlimited.', () {
        final limit = Limit.unlimited();

        expect(limit.allows(0), isTrue);
        expect(limit.allows(1000000), isTrue);
      });

      test('throws error for negative value.', () {
        expect(
          () => Limit.limited(-1),
          throwsA(isA<InvariantViolationError>()),
        );
      });

      test('equality works correctly.', () {
        final limit1 = Limit.limited(5);
        final limit2 = Limit.limited(5);
        final limit3 = Limit.limited(10);
        final unlimited1 = Limit.unlimited();
        final unlimited2 = Limit.unlimited();

        expect(limit1, equals(limit2));
        expect(limit1, isNot(equals(limit3)));
        expect(unlimited1, equals(unlimited2));
        expect(limit1, isNot(equals(unlimited1)));
      });
    });

    valueObjectTest<
      PlanLimit,
      ({Limit tracks, Limit characters}),
      ({Limit tracks, Limit characters})
    >(
      constructor: (props) =>
          PlanLimit(tracks: props.tracks, characters: props.characters),
      generator: () => (tracks: Limit.limited(3), characters: Limit.limited(2)),
      variations: (props) => [
        (tracks: Limit.limited(10), characters: props.characters),
        (tracks: props.tracks, characters: Limit.limited(5)),
        (tracks: Limit.unlimited(), characters: props.characters),
        (tracks: props.tracks, characters: Limit.unlimited()),
      ],
      invalids: (props) => [],
    );

    valueObjectTest<
      PurchaseReceipt,
      ({
        String provider,
        TransactionIdentifier transactionIdentifier,
        String signature,
      }),
      ({
        String provider,
        TransactionIdentifier transactionIdentifier,
        String signature,
      })
    >(
      constructor: (props) => PurchaseReceipt(
        provider: props.provider,
        transactionIdentifier: props.transactionIdentifier,
        signature: props.signature,
      ),
      generator: () => (
        provider: 'AppStore',
        transactionIdentifier: TransactionIdentifier.generate(),
        signature: 'base64signature',
      ),
      variations: (props) => [
        (
          provider: 'GooglePlay',
          transactionIdentifier: props.transactionIdentifier,
          signature: props.signature,
        ),
        (
          provider: props.provider,
          transactionIdentifier: TransactionIdentifier.generate(),
          signature: props.signature,
        ),
        (
          provider: props.provider,
          transactionIdentifier: props.transactionIdentifier,
          signature: 'different-signature',
        ),
      ],
      invalids: (props) => [
        (
          provider: '',
          transactionIdentifier: props.transactionIdentifier,
          signature: props.signature,
        ),
        (
          provider: 'a' * (PurchaseReceipt.maxProviderLength + 1),
          transactionIdentifier: props.transactionIdentifier,
          signature: props.signature,
        ),
        (
          provider: props.provider,
          transactionIdentifier: props.transactionIdentifier,
          signature: '',
        ),
      ],
    );

    valueObjectTest<OfflineGracePeriod, ({int days}), ({int days})>(
      constructor: (props) => OfflineGracePeriod.days(props.days),
      generator: () => (days: 7),
      variations: (props) => [(days: 1), (days: 15), (days: 30)],
      invalids: (props) => [(days: 0), (days: -1), (days: 31)],
    );

    valueObjectTest<
      EntitlementUsage,
      ({int tracks, int characters}),
      ({int tracks, int characters})
    >(
      constructor: (props) =>
          EntitlementUsage(tracks: props.tracks, characters: props.characters),
      generator: () => (tracks: 2, characters: 1),
      variations: (props) => [
        (tracks: 0, characters: props.characters),
        (tracks: props.tracks, characters: 0),
        (tracks: 10, characters: 5),
      ],
      invalids: (props) => [
        (tracks: -1, characters: props.characters),
        (tracks: props.tracks, characters: -1),
      ],
      additionalTests: () {
        group('adjust', () {
          test('adjusts usage correctly.', () {
            final usage = EntitlementUsage(tracks: 2, characters: 1);
            final adjusted = usage.adjust(tracksDelta: 1, charactersDelta: 2);

            expect(adjusted.tracks, equals(3));
            expect(adjusted.characters, equals(3));
          });

          test('throws error when adjusted value becomes negative.', () {
            final usage = EntitlementUsage(tracks: 2, characters: 1);

            expect(
              () => usage.adjust(tracksDelta: -3, charactersDelta: 0),
              throwsA(isA<InvariantViolationError>()),
            );

            expect(
              () => usage.adjust(tracksDelta: 0, charactersDelta: -2),
              throwsA(isA<InvariantViolationError>()),
            );
          });
        });
      },
    );

    group('Plan', () {
      test('can be created with valid properties.', () {
        final plan = Builder(PlanFactory()).build();

        expect(plan.identifier, isA<PlanIdentifier>());
        expect(plan.name, isNotEmpty);
        expect(plan.limits, isA<PlanLimit>());
        expect(plan.price, isA<Price>());
        expect(plan.currency, isA<Currency>());
        expect(plan.status, isA<PlanStatus>());
      });

      test('equality is based on identifier.', () {
        final identifier = PlanIdentifier.generate();
        final plan1 = Builder(PlanFactory()).build(
          overrides: (
            identifier: identifier,
            name: null,
            limits: null,
            price: null,
            currency: null,
            status: null,
          ),
        );
        final plan2 = Builder(PlanFactory()).build(
          overrides: (
            identifier: identifier,
            name: null,
            limits: null,
            price: null,
            currency: null,
            status: null,
          ),
        );
        final plan3 = Builder(PlanFactory()).build();

        expect(plan1, equals(plan2));
        expect(plan1, isNot(equals(plan3)));
      });
    });

    group('Subscription', () {
      test('can be created with valid properties.', () {
        final subscription = Builder(SubscriptionFactory()).build();

        expect(subscription.identifier, isA<SubscriptionIdentifier>());
        expect(subscription.plan, isA<PlanIdentifier>());
        expect(subscription.status, isA<SubscriptionStatus>());
        expect(subscription.expiresAt, isA<DateTime>());
        expect(subscription.offlineGracePeriod, isA<OfflineGracePeriod>());
        expect(subscription.receipt, isA<PurchaseReceipt>());
        expect(subscription.lastSyncedAt, isA<DateTime>());
      });

      test('throws error when gracePeriodEndsAt is before expiresAt.', () {
        final expiresAt = DateTime.now();
        final gracePeriodEndsAt = expiresAt.subtract(Duration(days: 1));

        expect(
          () => Builder(SubscriptionFactory()).build(
            overrides: (
              identifier: null,
              plan: null,
              status: null,
              expiresAt: expiresAt,
              gracePeriodEndsAt: gracePeriodEndsAt,
              offlineGracePeriod: null,
              receipt: null,
              lastSyncedAt: null,
            ),
          ),
          throwsA(isA<InvariantViolationError>()),
        );
      });

      test('updateStatus changes status.', () {
        final subscription = Builder(SubscriptionFactory()).build(
          overrides: (
            identifier: null,
            plan: null,
            status: SubscriptionStatus.active,
            expiresAt: null,
            gracePeriodEndsAt: null,
            offlineGracePeriod: null,
            receipt: null,
            lastSyncedAt: null,
          ),
        );

        subscription.updateStatus(SubscriptionStatus.expired);

        expect(subscription.status, equals(SubscriptionStatus.expired));
      });

      test('updateLastSyncedAt changes lastSyncedAt.', () {
        final subscription = Builder(SubscriptionFactory()).build();
        final newSyncedAt = DateTime.now();

        subscription.updateLastSyncedAt(newSyncedAt);

        expect(subscription.lastSyncedAt, equals(newSyncedAt));
      });
    });

    group('Entitlement', () {
      test('can be created with valid properties.', () {
        final entitlement = Builder(EntitlementFactory()).build();

        expect(entitlement.identifier, isA<EntitlementIdentifier>());
        expect(entitlement.plan, isA<PlanIdentifier>());
        expect(entitlement.version, isA<int>());
        expect(entitlement.lastProcessedSequenceNumber, isA<int>());
        expect(entitlement.limits, isA<PlanLimit>());
        expect(entitlement.usage, isA<EntitlementUsage>());
        expect(entitlement.status, isA<EntitlementStatus>());
      });

      test('syncWithPlan updates limits and version.', () {
        final entitlement = Builder(EntitlementFactory()).build(
          overrides: (
            identifier: null,
            profile: null,
            plan: null,
            subscription: null,
            version: 1,
            lastProcessedSequenceNumber: null,
            limits: PlanLimit(
              tracks: Limit.limited(3),
              characters: Limit.limited(2),
            ),
            usage: EntitlementUsage(tracks: 1, characters: 1),
            status: null,
          ),
        );

        final newLimits = PlanLimit(
          tracks: Limit.limited(10),
          characters: Limit.limited(5),
        );

        entitlement.syncWithPlan(
          planIdentifier: entitlement.plan,
          newLimits: newLimits,
        );

        expect(entitlement.limits, equals(newLimits));
        expect(entitlement.version, equals(2));
        expect(entitlement.status, equals(EntitlementStatus.active));
      });

      test('syncWithPlan sets status to restricted when over limit.', () {
        final entitlement = Builder(EntitlementFactory()).build(
          overrides: (
            identifier: null,
            profile: null,
            plan: null,
            subscription: null,
            version: null,
            lastProcessedSequenceNumber: null,
            limits: PlanLimit(
              tracks: Limit.limited(10),
              characters: Limit.limited(5),
            ),
            usage: EntitlementUsage(tracks: 5, characters: 2),
            status: null,
          ),
        );

        final newLimits = PlanLimit(
          tracks: Limit.limited(3),
          characters: Limit.limited(2),
        );

        entitlement.syncWithPlan(
          planIdentifier: entitlement.plan,
          newLimits: newLimits,
        );

        expect(entitlement.status, equals(EntitlementStatus.restricted));

        final events = entitlement.events();
        expect(events.whereType<EntitlementRestricted>().length, equals(1));
      });

      test('adjustUsage updates usage and version.', () {
        final entitlement = Builder(EntitlementFactory()).build(
          overrides: (
            identifier: null,
            profile: null,
            plan: null,
            subscription: null,
            version: 1,
            lastProcessedSequenceNumber: 100,
            limits: PlanLimit(
              tracks: Limit.limited(10),
              characters: Limit.limited(5),
            ),
            usage: EntitlementUsage(tracks: 1, characters: 1),
            status: null,
          ),
        );

        entitlement.adjustUsage(
          tracksDelta: 2,
          charactersDelta: 1,
          sequenceNumber: 101,
        );

        expect(entitlement.usage.tracks, equals(3));
        expect(entitlement.usage.characters, equals(2));
        expect(entitlement.version, equals(2));
        expect(entitlement.lastProcessedSequenceNumber, equals(101));
      });

      test('adjustUsage ignores old sequence numbers.', () {
        final entitlement = Builder(EntitlementFactory()).build(
          overrides: (
            identifier: null,
            profile: null,
            plan: null,
            subscription: null,
            version: 1,
            lastProcessedSequenceNumber: 100,
            limits: null,
            usage: EntitlementUsage(tracks: 1, characters: 1),
            status: null,
          ),
        );

        entitlement.adjustUsage(
          tracksDelta: 2,
          charactersDelta: 1,
          sequenceNumber: 99,
        );

        expect(entitlement.usage.tracks, equals(1));
        expect(entitlement.usage.characters, equals(1));
        expect(entitlement.version, equals(1));
        expect(entitlement.lastProcessedSequenceNumber, equals(100));
      });

      test('adjustUsage sets status to restricted when over limit.', () {
        final entitlement = Builder(EntitlementFactory()).build(
          overrides: (
            identifier: null,
            profile: null,
            plan: null,
            subscription: null,
            version: null,
            lastProcessedSequenceNumber: 100,
            limits: PlanLimit(
              tracks: Limit.limited(3),
              characters: Limit.limited(2),
            ),
            usage: EntitlementUsage(tracks: 2, characters: 1),
            status: null,
          ),
        );

        entitlement.adjustUsage(
          tracksDelta: 2,
          charactersDelta: 0,
          sequenceNumber: 101,
        );

        expect(entitlement.status, equals(EntitlementStatus.restricted));

        final events = entitlement.events();
        expect(events.whereType<EntitlementRestricted>().length, equals(1));
      });
    });

    group('PlanRepository', () {
      test('find returns plan by identifier.', () async {
        final plan = Builder(PlanFactory()).build();
        final repository = Builder(
          PlanRepositoryFactory(),
        ).build(overrides: (instances: [plan], onPersist: null));

        final found = await repository.find(plan.identifier);

        expect(found, equals(plan));
      });

      test(
        'find throws AggregateNotFoundError for non-existent identifier.',
        () async {
          final repository = Builder(
            PlanRepositoryFactory(),
          ).build(overrides: (instances: [], onPersist: null));

          expect(
            () => repository.find(PlanIdentifier.generate()),
            throwsA(isA<AggregateNotFoundError>()),
          );
        },
      );

      test('all returns all plans.', () async {
        final plans = Builder(PlanFactory()).buildList(count: 3);
        final repository = Builder(
          PlanRepositoryFactory(),
        ).build(overrides: (instances: plans, onPersist: null));

        final all = await repository.all();

        expect(all.length, equals(3));
        expect(all, containsAll(plans));
      });

      test('persist saves plan.', () async {
        final repository = Builder(
          PlanRepositoryFactory(),
        ).build(overrides: (instances: [], onPersist: null));
        final plan = Builder(PlanFactory()).build();

        await repository.persist(plan);

        final found = await repository.find(plan.identifier);
        expect(found, equals(plan));
      });

      test('persist calls onPersist callback.', () async {
        Plan? persisted;
        final repository = Builder(PlanRepositoryFactory()).build(
          overrides: (instances: [], onPersist: (plan) => persisted = plan),
        );
        final plan = Builder(PlanFactory()).build();

        await repository.persist(plan);

        expect(persisted, equals(plan));
      });
    });

    group('SubscriptionRepository', () {
      test('find returns subscription by identifier.', () async {
        final subscription = Builder(SubscriptionFactory()).build();
        final repository = Builder(
          SubscriptionRepositoryFactory(),
        ).build(overrides: (instances: [subscription], onPersist: null));

        final found = await repository.find(subscription.identifier);

        expect(found, equals(subscription));
      });

      test('persist saves subscription.', () async {
        final repository = Builder(
          SubscriptionRepositoryFactory(),
        ).build(overrides: (instances: [], onPersist: null));
        final subscription = Builder(SubscriptionFactory()).build();

        await repository.persist(subscription);

        final found = await repository.find(subscription.identifier);
        expect(found, equals(subscription));
      });
    });

    group('EntitlementRepository', () {
      test('find returns entitlement by identifier.', () async {
        final entitlement = Builder(EntitlementFactory()).build();
        final repository = Builder(
          EntitlementRepositoryFactory(),
        ).build(overrides: (instances: [entitlement], onPersist: null));

        final found = await repository.find(entitlement.identifier);

        expect(found, equals(entitlement));
      });

      test('persist saves entitlement.', () async {
        final repository = Builder(
          EntitlementRepositoryFactory(),
        ).build(overrides: (instances: [], onPersist: null));
        final entitlement = Builder(EntitlementFactory()).build();

        await repository.persist(entitlement);

        final found = await repository.find(entitlement.identifier);
        expect(found, equals(entitlement));
      });
    });
  });
}
