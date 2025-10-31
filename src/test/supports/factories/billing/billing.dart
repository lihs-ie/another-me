import 'package:another_me/domains/billing/billing.dart';
import 'package:another_me/domains/common/error.dart';
import 'package:another_me/domains/common/transaction.dart';
import 'package:another_me/domains/profile/profile.dart';
import 'package:logger/logger.dart';

import '../common.dart';
import '../common/identifier.dart';
import '../common/transaction.dart';
import '../enum.dart';
import '../logger.dart';
import '../profile/profile.dart';
import '../string.dart';

class PlanIdentifierFactory extends ULIDBasedIdentifierFactory<PlanIdentifier> {
  PlanIdentifierFactory() : super((value) => PlanIdentifier(value: value));
}

typedef PriceOverrides = ({double? amount});

class PriceFactory extends Factory<Price, PriceOverrides> {
  @override
  Price create({PriceOverrides? overrides, required int seed}) {
    final amount = overrides?.amount ?? (seed % 10000).toDouble();

    return Price.create(amount: amount);
  }

  @override
  Price duplicate(Price instance, PriceOverrides? overrides) {
    final amount = overrides?.amount ?? instance.amount;

    return Price.create(amount: amount);
  }
}

typedef CurrencyOverrides = ({String? code});

class CurrencyFactory extends Factory<Currency, CurrencyOverrides> {
  static final List<String> _currencyCodes = [
    'USD',
    'JPY',
    'EUR',
    'GBP',
    'AUD',
  ];

  @override
  Currency create({CurrencyOverrides? overrides, required int seed}) {
    final code =
        overrides?.code ?? _currencyCodes[seed % _currencyCodes.length];

    return Currency.create(code);
  }

  @override
  Currency duplicate(Currency instance, CurrencyOverrides? overrides) {
    final code = overrides?.code ?? instance.code;

    return Currency.create(code);
  }
}

typedef LimitOverrides = ({int? value, bool? unlimited});

class LimitFactory extends Factory<Limit, LimitOverrides> {
  @override
  Limit create({LimitOverrides? overrides, required int seed}) {
    if (overrides?.unlimited == true) {
      return Limit.unlimited();
    }

    final value = overrides?.value ?? ((seed % 100) + 1);

    return Limit.limited(value);
  }

  @override
  Limit duplicate(Limit instance, LimitOverrides? overrides) {
    if (overrides?.unlimited == true) {
      return Limit.unlimited();
    }

    if (overrides?.value != null) {
      return Limit.limited(overrides!.value!);
    }

    if (instance.isUnlimited) {
      return Limit.unlimited();
    }

    return Limit.limited(instance.value!);
  }
}

typedef PlanLimitOverrides = ({Limit? tracks, Limit? characters});

class PlanLimitFactory extends Factory<PlanLimit, PlanLimitOverrides> {
  @override
  PlanLimit create({PlanLimitOverrides? overrides, required int seed}) {
    final tracks =
        overrides?.tracks ?? Builder(LimitFactory()).buildWith(seed: seed);

    final characters =
        overrides?.characters ?? Builder(LimitFactory()).buildWith(seed: seed);

    return PlanLimit(tracks: tracks, characters: characters);
  }

  @override
  PlanLimit duplicate(PlanLimit instance, PlanLimitOverrides? overrides) {
    final tracks =
        overrides?.tracks ??
        Builder(
          LimitFactory(),
        ).duplicate(instance: instance.tracks, overrides: null);

    final characters =
        overrides?.characters ??
        Builder(
          LimitFactory(),
        ).duplicate(instance: instance.characters, overrides: null);

    return PlanLimit(tracks: tracks, characters: characters);
  }
}

class PlanStatusFactory extends EnumFactory<PlanStatus> {
  PlanStatusFactory() : super(PlanStatus.values);
}

typedef PlanOverrides = ({
  PlanIdentifier? identifier,
  String? name,
  PlanLimit? limits,
  Price? price,
  Currency? currency,
  PlanStatus? status,
});

class PlanFactory extends Factory<Plan, PlanOverrides> {
  @override
  Plan create({PlanOverrides? overrides, required int seed}) {
    final identifier =
        overrides?.identifier ??
        Builder(PlanIdentifierFactory()).buildWith(seed: seed);

    final name =
        overrides?.name ?? StringFactory.create(seed: seed, min: 1, max: 50);

    final limits =
        overrides?.limits ?? Builder(PlanLimitFactory()).buildWith(seed: seed);

    final price =
        overrides?.price ?? Builder(PriceFactory()).buildWith(seed: seed);

    final currency =
        overrides?.currency ?? Builder(CurrencyFactory()).buildWith(seed: seed);

    final status =
        overrides?.status ?? Builder(PlanStatusFactory()).buildWith(seed: seed);

    return Plan(
      identifier: identifier,
      name: name,
      limits: limits,
      price: price,
      currency: currency,
      status: status,
    );
  }

  @override
  Plan duplicate(Plan instance, PlanOverrides? overrides) {
    final identifier =
        overrides?.identifier ??
        Builder(
          PlanIdentifierFactory(),
        ).duplicate(instance: instance.identifier, overrides: null);

    final name = overrides?.name ?? instance.name;

    final limits =
        overrides?.limits ??
        Builder(
          PlanLimitFactory(),
        ).duplicate(instance: instance.limits, overrides: null);

    final price =
        overrides?.price ??
        Builder(
          PriceFactory(),
        ).duplicate(instance: instance.price, overrides: null);

    final currency =
        overrides?.currency ??
        Builder(
          CurrencyFactory(),
        ).duplicate(instance: instance.currency, overrides: null);

    final status = overrides?.status ?? instance.status;

    return Plan(
      identifier: identifier,
      name: name,
      limits: limits,
      price: price,
      currency: currency,
      status: status,
    );
  }
}

class SubscriptionIdentifierFactory
    extends ULIDBasedIdentifierFactory<SubscriptionIdentifier> {
  SubscriptionIdentifierFactory()
    : super((value) => SubscriptionIdentifier(value: value));
}

class TransactionIdentifierFactory
    extends ULIDBasedIdentifierFactory<TransactionIdentifier> {
  TransactionIdentifierFactory()
    : super((value) => TransactionIdentifier(value: value));
}

typedef PurchaseReceiptOverrides = ({
  String? provider,
  TransactionIdentifier? transactionIdentifier,
  String? signature,
});

class PurchaseReceiptFactory
    extends Factory<PurchaseReceipt, PurchaseReceiptOverrides> {
  @override
  PurchaseReceipt create({
    PurchaseReceiptOverrides? overrides,
    required int seed,
  }) {
    final provider =
        overrides?.provider ??
        StringFactory.create(
          seed: seed,
          min: 1,
          max: PurchaseReceipt.maxProviderLength,
        );

    final transactionIdentifier =
        overrides?.transactionIdentifier ??
        Builder(TransactionIdentifierFactory()).buildWith(seed: seed);

    final signature =
        overrides?.signature ??
        StringFactory.create(seed: seed, min: 1, max: 500);

    return PurchaseReceipt(
      provider: provider,
      transactionIdentifier: transactionIdentifier,
      signature: signature,
    );
  }

  @override
  PurchaseReceipt duplicate(
    PurchaseReceipt instance,
    PurchaseReceiptOverrides? overrides,
  ) {
    final provider = overrides?.provider ?? instance.provider;

    final transactionIdentifier =
        overrides?.transactionIdentifier ??
        Builder(
          TransactionIdentifierFactory(),
        ).duplicate(instance: instance.transactionIdentifier, overrides: null);

    final signature = overrides?.signature ?? instance.signature;

    return PurchaseReceipt(
      provider: provider,
      transactionIdentifier: transactionIdentifier,
      signature: signature,
    );
  }
}

class SubscriptionStatusFactory extends EnumFactory<SubscriptionStatus> {
  SubscriptionStatusFactory() : super(SubscriptionStatus.values);
}

typedef OfflineGracePeriodOverrides = ({int? days});

class OfflineGracePeriodFactory
    extends Factory<OfflineGracePeriod, OfflineGracePeriodOverrides> {
  @override
  OfflineGracePeriod create({
    OfflineGracePeriodOverrides? overrides,
    required int seed,
  }) {
    final days = overrides?.days ?? ((seed % 30) + 1);

    return OfflineGracePeriod.days(days);
  }

  @override
  OfflineGracePeriod duplicate(
    OfflineGracePeriod instance,
    OfflineGracePeriodOverrides? overrides,
  ) {
    final days = overrides?.days ?? instance.days;

    return OfflineGracePeriod.days(days);
  }
}

typedef SubscriptionOverrides = ({
  SubscriptionIdentifier? identifier,
  PlanIdentifier? plan,
  SubscriptionStatus? status,
  DateTime? expiresAt,
  DateTime? gracePeriodEndsAt,
  OfflineGracePeriod? offlineGracePeriod,
  PurchaseReceipt? receipt,
  DateTime? lastSyncedAt,
});

class SubscriptionFactory extends Factory<Subscription, SubscriptionOverrides> {
  @override
  Subscription create({SubscriptionOverrides? overrides, required int seed}) {
    final identifier =
        overrides?.identifier ??
        Builder(SubscriptionIdentifierFactory()).buildWith(seed: seed);

    final plan =
        overrides?.plan ??
        Builder(PlanIdentifierFactory()).buildWith(seed: seed);

    final status =
        overrides?.status ??
        Builder(SubscriptionStatusFactory()).buildWith(seed: seed);

    final expiresAt =
        overrides?.expiresAt ??
        DateTime.now().add(Duration(days: (seed % 365) + 1));

    final gracePeriodEndsAt =
        overrides?.gracePeriodEndsAt ??
        (seed % 2 == 0 ? expiresAt.add(Duration(days: 7)) : null);

    final offlineGracePeriod =
        overrides?.offlineGracePeriod ??
        Builder(OfflineGracePeriodFactory()).buildWith(seed: seed);

    final receipt =
        overrides?.receipt ??
        Builder(PurchaseReceiptFactory()).buildWith(seed: seed);

    final lastSyncedAt =
        overrides?.lastSyncedAt ??
        DateTime.now().subtract(Duration(hours: seed % 24));

    return Subscription(
      identifier: identifier,
      plan: plan,
      status: status,
      expiresAt: expiresAt,
      gracePeriodEndsAt: gracePeriodEndsAt,
      offlineGracePeriod: offlineGracePeriod,
      receipt: receipt,
      lastSyncedAt: lastSyncedAt,
    );
  }

  @override
  Subscription duplicate(
    Subscription instance,
    SubscriptionOverrides? overrides,
  ) {
    final identifier =
        overrides?.identifier ??
        Builder(
          SubscriptionIdentifierFactory(),
        ).duplicate(instance: instance.identifier, overrides: null);

    final plan =
        overrides?.plan ??
        Builder(
          PlanIdentifierFactory(),
        ).duplicate(instance: instance.plan, overrides: null);

    final status = overrides?.status ?? instance.status;

    final expiresAt = overrides?.expiresAt ?? instance.expiresAt;

    final gracePeriodEndsAt =
        overrides?.gracePeriodEndsAt ?? instance.gracePeriodEndsAt;

    final offlineGracePeriod =
        overrides?.offlineGracePeriod ??
        Builder(
          OfflineGracePeriodFactory(),
        ).duplicate(instance: instance.offlineGracePeriod, overrides: null);

    final receipt =
        overrides?.receipt ??
        Builder(
          PurchaseReceiptFactory(),
        ).duplicate(instance: instance.receipt, overrides: null);

    final lastSyncedAt = overrides?.lastSyncedAt ?? instance.lastSyncedAt;

    return Subscription(
      identifier: identifier,
      plan: plan,
      status: status,
      expiresAt: expiresAt,
      gracePeriodEndsAt: gracePeriodEndsAt,
      offlineGracePeriod: offlineGracePeriod,
      receipt: receipt,
      lastSyncedAt: lastSyncedAt,
    );
  }
}

class EntitlementIdentifierFactory
    extends ULIDBasedIdentifierFactory<EntitlementIdentifier> {
  EntitlementIdentifierFactory()
    : super((value) => EntitlementIdentifier(value: value));
}

typedef EntitlementUsageOverrides = ({int? tracks, int? characters});

class EntitlementUsageFactory
    extends Factory<EntitlementUsage, EntitlementUsageOverrides> {
  @override
  EntitlementUsage create({
    EntitlementUsageOverrides? overrides,
    required int seed,
  }) {
    final tracks = overrides?.tracks ?? (seed % 10);

    final characters = overrides?.characters ?? (seed % 5);

    return EntitlementUsage(tracks: tracks, characters: characters);
  }

  @override
  EntitlementUsage duplicate(
    EntitlementUsage instance,
    EntitlementUsageOverrides? overrides,
  ) {
    final tracks = overrides?.tracks ?? instance.tracks;

    final characters = overrides?.characters ?? instance.characters;

    return EntitlementUsage(tracks: tracks, characters: characters);
  }
}

class EntitlementStatusFactory extends EnumFactory<EntitlementStatus> {
  EntitlementStatusFactory() : super(EntitlementStatus.values);
}

class OverLimitTypeFactory extends EnumFactory<OverLimitType> {
  OverLimitTypeFactory() : super(OverLimitType.values);
}

typedef EntitlementOverrides = ({
  EntitlementIdentifier? identifier,
  ProfileIdentifier? profile,
  PlanIdentifier? plan,
  SubscriptionIdentifier? subscription,
  int? version,
  int? lastProcessedSequenceNumber,
  PlanLimit? limits,
  EntitlementUsage? usage,
  EntitlementStatus? status,
});

class EntitlementFactory extends Factory<Entitlement, EntitlementOverrides> {
  @override
  Entitlement create({EntitlementOverrides? overrides, required int seed}) {
    final identifier =
        overrides?.identifier ??
        Builder(EntitlementIdentifierFactory()).buildWith(seed: seed);

    final profile =
        overrides?.profile ??
        Builder(ProfileIdentifierFactory()).buildWith(seed: seed);

    final plan =
        overrides?.plan ??
        Builder(PlanIdentifierFactory()).buildWith(seed: seed);

    final subscription =
        overrides?.subscription ??
        (seed % 2 == 0
            ? Builder(SubscriptionIdentifierFactory()).buildWith(seed: seed)
            : null);

    final version = overrides?.version ?? (seed % 100);

    final lastProcessedSequenceNumber =
        overrides?.lastProcessedSequenceNumber ?? (seed % 10000);

    final limits =
        overrides?.limits ?? Builder(PlanLimitFactory()).buildWith(seed: seed);

    final usage =
        overrides?.usage ??
        Builder(EntitlementUsageFactory()).buildWith(seed: seed);

    final status =
        overrides?.status ??
        Builder(EntitlementStatusFactory()).buildWith(seed: seed);

    return Entitlement(
      identifier: identifier,
      profile: profile,
      plan: plan,
      subscription: subscription,
      version: version,
      lastProcessedSequenceNumber: lastProcessedSequenceNumber,
      limits: limits,
      usage: usage,
      status: status,
    );
  }

  @override
  Entitlement duplicate(Entitlement instance, EntitlementOverrides? overrides) {
    final identifier =
        overrides?.identifier ??
        Builder(
          EntitlementIdentifierFactory(),
        ).duplicate(instance: instance.identifier, overrides: null);

    final profile =
        overrides?.profile ??
        Builder(
          ProfileIdentifierFactory(),
        ).duplicate(instance: instance.profile, overrides: null);

    final plan =
        overrides?.plan ??
        Builder(
          PlanIdentifierFactory(),
        ).duplicate(instance: instance.plan, overrides: null);

    final subscription =
        overrides?.subscription ??
        (instance.subscription != null
            ? Builder(
                SubscriptionIdentifierFactory(),
              ).duplicate(instance: instance.subscription!, overrides: null)
            : null);

    final version = overrides?.version ?? instance.version;

    final lastProcessedSequenceNumber =
        overrides?.lastProcessedSequenceNumber ??
        instance.lastProcessedSequenceNumber;

    final limits =
        overrides?.limits ??
        Builder(
          PlanLimitFactory(),
        ).duplicate(instance: instance.limits, overrides: null);

    final usage =
        overrides?.usage ??
        Builder(
          EntitlementUsageFactory(),
        ).duplicate(instance: instance.usage, overrides: null);

    final status = overrides?.status ?? instance.status;

    return Entitlement(
      identifier: identifier,
      profile: profile,
      plan: plan,
      subscription: subscription,
      version: version,
      lastProcessedSequenceNumber: lastProcessedSequenceNumber,
      limits: limits,
      usage: usage,
      status: status,
    );
  }
}

typedef PlanRepositoryOverrides = ({
  List<Plan>? instances,
  void Function(Plan)? onPersist,
});

class _PlanRepository implements PlanRepository {
  final Map<PlanIdentifier, Plan> _instances;
  final void Function(Plan)? _onPersist;

  _PlanRepository({
    required List<Plan> instances,
    void Function(Plan)? onPersist,
  }) : _instances = {
         for (final instance in instances) instance.identifier: instance,
       },
       _onPersist = onPersist;

  @override
  Future<Plan> find(PlanIdentifier identifier) {
    final instance = _instances[identifier];

    if (instance == null) {
      throw AggregateNotFoundError(
        'Plan with identifier ${identifier.value} not found.',
      );
    }

    return Future.value(instance);
  }

  @override
  Future<Plan> findDefault() {
    final defaultPlan = _instances.values.firstWhere(
      (plan) => plan.price.amount == 0.0,
      orElse: () => throw AggregateNotFoundError('Default plan not found.'),
    );

    return Future.value(defaultPlan);
  }

  @override
  Future<List<Plan>> all() {
    return Future.value(_instances.values.toList());
  }

  @override
  Future<void> persist(Plan plan) {
    _instances[plan.identifier] = plan;

    if (_onPersist != null) {
      _onPersist(plan);
    }

    return Future.value();
  }
}

class PlanRepositoryFactory
    extends Factory<PlanRepository, PlanRepositoryOverrides> {
  @override
  PlanRepository create({
    PlanRepositoryOverrides? overrides,
    required int seed,
  }) {
    final instances =
        overrides?.instances ??
        Builder(
          PlanFactory(),
        ).buildListWith(count: (seed % 10) + 1, seed: seed);

    return _PlanRepository(
      instances: instances,
      onPersist: overrides?.onPersist,
    );
  }

  @override
  PlanRepository duplicate(
    PlanRepository instance,
    PlanRepositoryOverrides? overrides,
  ) {
    throw UnimplementedError();
  }
}

typedef SubscriptionRepositoryOverrides = ({
  List<Subscription>? instances,
  void Function(Subscription)? onPersist,
});

class _SubscriptionRepository implements SubscriptionRepository {
  final Map<SubscriptionIdentifier, Subscription> _instances;
  final void Function(Subscription)? _onPersist;

  _SubscriptionRepository({
    required List<Subscription> instances,
    void Function(Subscription)? onPersist,
  }) : _instances = {
         for (final instance in instances) instance.identifier: instance,
       },
       _onPersist = onPersist;

  @override
  Future<Subscription> find(SubscriptionIdentifier identifier) {
    final instance = _instances[identifier];

    if (instance == null) {
      throw AggregateNotFoundError(
        'Subscription with identifier ${identifier.value} not found.',
      );
    }

    return Future.value(instance);
  }

  @override
  Future<void> persist(Subscription subscription) {
    _instances[subscription.identifier] = subscription;

    if (_onPersist != null) {
      _onPersist(subscription);
    }

    return Future.value();
  }
}

class SubscriptionRepositoryFactory
    extends Factory<SubscriptionRepository, SubscriptionRepositoryOverrides> {
  @override
  SubscriptionRepository create({
    SubscriptionRepositoryOverrides? overrides,
    required int seed,
  }) {
    final instances =
        overrides?.instances ??
        Builder(
          SubscriptionFactory(),
        ).buildListWith(count: (seed % 10) + 1, seed: seed);

    return _SubscriptionRepository(
      instances: instances,
      onPersist: overrides?.onPersist,
    );
  }

  @override
  SubscriptionRepository duplicate(
    SubscriptionRepository instance,
    SubscriptionRepositoryOverrides? overrides,
  ) {
    throw UnimplementedError();
  }
}

typedef EntitlementRepositoryOverrides = ({
  List<Entitlement>? instances,
  void Function(Entitlement)? onPersist,
});

class _EntitlementRepository implements EntitlementRepository {
  final Map<EntitlementIdentifier, Entitlement> _instances;
  final void Function(Entitlement)? _onPersist;

  _EntitlementRepository({
    required List<Entitlement> instances,
    void Function(Entitlement)? onPersist,
  }) : _instances = {
         for (final instance in instances) instance.identifier: instance,
       },
       _onPersist = onPersist;

  @override
  Future<Entitlement> find(EntitlementIdentifier identifier) {
    final instance = _instances[identifier];

    if (instance == null) {
      throw AggregateNotFoundError(
        'Entitlement with identifier ${identifier.value} not found.',
      );
    }

    return Future.value(instance);
  }

  @override
  Future<Entitlement> findByProfile(ProfileIdentifier profile) {
    final instance = _instances.values.firstWhere(
      (entitlement) => entitlement.profile == profile,
      orElse: () => throw AggregateNotFoundError(
        'Entitlement for profile ${profile.value} not found.',
      ),
    );

    return Future.value(instance);
  }

  @override
  Future<List<Entitlement>> all() {
    return Future.value(_instances.values.toList());
  }

  @override
  Future<void> persist(Entitlement entitlement) {
    _instances[entitlement.identifier] = entitlement;

    if (_onPersist != null) {
      _onPersist(entitlement);
    }

    return Future.value();
  }
}

class EntitlementRepositoryFactory
    extends Factory<EntitlementRepository, EntitlementRepositoryOverrides> {
  @override
  EntitlementRepository create({
    EntitlementRepositoryOverrides? overrides,
    required int seed,
  }) {
    final instances =
        overrides?.instances ??
        Builder(
          EntitlementFactory(),
        ).buildListWith(count: (seed % 10) + 1, seed: seed);

    return _EntitlementRepository(
      instances: instances,
      onPersist: overrides?.onPersist,
    );
  }

  @override
  EntitlementRepository duplicate(
    EntitlementRepository instance,
    EntitlementRepositoryOverrides? overrides,
  ) {
    throw UnimplementedError();
  }
}

typedef SubscriptionSyncSubscriberOverrides = ({
  SubscriptionRepository? subscriptionRepository,
  PlanRepository? planRepository,
  EntitlementRepository? entitlementRepository,
  Transaction? transaction,
  Logger? logger,
});

class SubscriptionSyncSubscriberFactory
    extends
        Factory<
          SubscriptionSyncSubscriber,
          SubscriptionSyncSubscriberOverrides
        > {
  @override
  SubscriptionSyncSubscriber create({
    SubscriptionSyncSubscriberOverrides? overrides,
    required int seed,
  }) {
    final subscriptionRepository =
        overrides?.subscriptionRepository ??
        Builder(SubscriptionRepositoryFactory()).buildWith(seed: seed);

    final planRepository =
        overrides?.planRepository ??
        Builder(PlanRepositoryFactory()).buildWith(seed: seed);

    final entitlementRepository =
        overrides?.entitlementRepository ??
        Builder(EntitlementRepositoryFactory()).buildWith(seed: seed);

    final transaction =
        overrides?.transaction ??
        Builder(TransactionFactory()).buildWith(seed: seed);

    final logger =
        overrides?.logger ?? Builder(LoggerFactory()).buildWith(seed: seed);

    return SubscriptionSyncSubscriber(
      subscriptionRepository: subscriptionRepository,
      planRepository: planRepository,
      entitlementRepository: entitlementRepository,
      transaction: transaction,
      logger: logger,
    );
  }

  @override
  SubscriptionSyncSubscriber duplicate(
    SubscriptionSyncSubscriber instance,
    SubscriptionSyncSubscriberOverrides? overrides,
  ) {
    throw UnimplementedError();
  }
}

typedef PlanManagementSubscriberOverrides = ({
  PlanRepository? planRepository,
  EntitlementRepository? entitlementRepository,
  Transaction? transaction,
  Logger? logger,
});

class PlanManagementSubscriberFactory
    extends
        Factory<PlanManagementSubscriber, PlanManagementSubscriberOverrides> {
  @override
  PlanManagementSubscriber create({
    PlanManagementSubscriberOverrides? overrides,
    required int seed,
  }) {
    final planRepository =
        overrides?.planRepository ??
        Builder(PlanRepositoryFactory()).buildWith(seed: seed);

    final entitlementRepository =
        overrides?.entitlementRepository ??
        Builder(EntitlementRepositoryFactory()).buildWith(seed: seed);

    final transaction =
        overrides?.transaction ??
        Builder(TransactionFactory()).buildWith(seed: seed);

    final logger =
        overrides?.logger ?? Builder(LoggerFactory()).buildWith(seed: seed);

    return PlanManagementSubscriber(
      planRepository: planRepository,
      entitlementRepository: entitlementRepository,
      transaction: transaction,
      logger: logger,
    );
  }

  @override
  PlanManagementSubscriber duplicate(
    PlanManagementSubscriber instance,
    PlanManagementSubscriberOverrides? overrides,
  ) {
    throw UnimplementedError();
  }
}

typedef MediaUsageSubscriberOverrides = ({
  EntitlementRepository? entitlementRepository,
  Transaction? transaction,
  Logger? logger,
});

class MediaUsageSubscriberFactory
    extends Factory<MediaUsageSubscriber, MediaUsageSubscriberOverrides> {
  @override
  MediaUsageSubscriber create({
    MediaUsageSubscriberOverrides? overrides,
    required int seed,
  }) {
    final entitlementRepository =
        overrides?.entitlementRepository ??
        Builder(EntitlementRepositoryFactory()).buildWith(seed: seed);

    final transaction =
        overrides?.transaction ??
        Builder(TransactionFactory()).buildWith(seed: seed);

    final logger =
        overrides?.logger ?? Builder(LoggerFactory()).buildWith(seed: seed);

    return MediaUsageSubscriber(
      entitlementRepository: entitlementRepository,
      transaction: transaction,
      logger: logger,
    );
  }

  @override
  MediaUsageSubscriber duplicate(
    MediaUsageSubscriber instance,
    MediaUsageSubscriberOverrides? overrides,
  ) {
    throw UnimplementedError();
  }
}

typedef AvatarUsageSubscriberOverrides = ({
  EntitlementRepository? entitlementRepository,
  Transaction? transaction,
  Logger? logger,
});

class AvatarUsageSubscriberFactory
    extends Factory<AvatarUsageSubscriber, AvatarUsageSubscriberOverrides> {
  @override
  AvatarUsageSubscriber create({
    AvatarUsageSubscriberOverrides? overrides,
    required int seed,
  }) {
    final entitlementRepository =
        overrides?.entitlementRepository ??
        Builder(EntitlementRepositoryFactory()).buildWith(seed: seed);

    final transaction =
        overrides?.transaction ??
        Builder(TransactionFactory()).buildWith(seed: seed);

    final logger =
        overrides?.logger ?? Builder(LoggerFactory()).buildWith(seed: seed);

    return AvatarUsageSubscriber(
      entitlementRepository: entitlementRepository,
      transaction: transaction,
      logger: logger,
    );
  }

  @override
  AvatarUsageSubscriber duplicate(
    AvatarUsageSubscriber instance,
    AvatarUsageSubscriberOverrides? overrides,
  ) {
    throw UnimplementedError();
  }
}

typedef EntitlementServiceOverrides = ({
  Future<bool> Function(int)? canAddTrack,
  Future<bool> Function(int)? canUseCharacter,
  int? trackLimit,
  int? characterLimit,
});

class _EntitlementService implements EntitlementService {
  final Future<bool> Function(int) _canAddTrack;
  final Future<bool> Function(int) _canUseCharacter;
  final int _trackLimit;
  final int _characterLimit;

  _EntitlementService({
    required Future<bool> Function(int) canAddTrack,
    required Future<bool> Function(int) canUseCharacter,
    required int trackLimit,
    required int characterLimit,
  }) : _canAddTrack = canAddTrack,
       _canUseCharacter = canUseCharacter,
       _trackLimit = trackLimit,
       _characterLimit = characterLimit;

  @override
  Future<bool> canAddTrack(int currentTrackCount) {
    return _canAddTrack(currentTrackCount);
  }

  @override
  Future<bool> canUseCharacter(int currentCharacterCount) {
    return _canUseCharacter(currentCharacterCount);
  }

  @override
  Future<int> getTrackLimit() {
    return Future.value(_trackLimit);
  }

  @override
  Future<int> getCharacterLimit() {
    return Future.value(_characterLimit);
  }
}

class EntitlementServiceFactory
    extends Factory<EntitlementService, EntitlementServiceOverrides> {
  @override
  EntitlementService create({
    EntitlementServiceOverrides? overrides,
    required int seed,
  }) {
    final canAddTrack =
        overrides?.canAddTrack ?? (int count) => Future.value(count < 100);

    final canUseCharacter =
        overrides?.canUseCharacter ?? (int count) => Future.value(count < 10);

    final trackLimit = overrides?.trackLimit ?? 100;

    final characterLimit = overrides?.characterLimit ?? 10;

    return _EntitlementService(
      canAddTrack: canAddTrack,
      canUseCharacter: canUseCharacter,
      trackLimit: trackLimit,
      characterLimit: characterLimit,
    );
  }

  @override
  EntitlementService duplicate(
    EntitlementService instance,
    EntitlementServiceOverrides? overrides,
  ) {
    throw UnimplementedError();
  }
}
