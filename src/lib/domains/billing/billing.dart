import 'dart:typed_data';

import 'package:another_me/domains/common/event.dart';
import 'package:another_me/domains/common/identifier.dart';
import 'package:another_me/domains/common/value_object.dart';
import 'package:another_me/domains/common/variant.dart';
import 'package:ulid/ulid.dart';

class Price implements ValueObject {
  final double amount;

  Price._({required this.amount}) {
    Invariant.range(value: amount, name: 'amount', min: 0.0);
  }

  factory Price.create({required double amount}) => Price._(amount: amount);

  factory Price.free() => Price._(amount: 0.0);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! Price) {
      return false;
    }

    return amount == other.amount;
  }

  @override
  int get hashCode => amount.hashCode;
}

class Currency implements ValueObject {
  final String code;

  Currency._({required this.code}) {
    Invariant.length(value: code, name: 'code', min: 3, max: 3);

    Invariant.pattern(value: code, name: 'code', pattern: r'^[A-Z]{3}$');
  }

  factory Currency.create(String code) => Currency._(code: code);

  @override
  String toString() => code;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! Currency) {
      return false;
    }

    return code == other.code;
  }

  @override
  int get hashCode => code.hashCode;
}

class Limit implements ValueObject {
  final int? _value;

  Limit._({required int? value}) : _value = value {
    if (value != null) {
      Invariant.range(value: value, name: 'value', min: 0);
    }
  }

  factory Limit.limited(int value) => Limit._(value: value);

  factory Limit.unlimited() => Limit._(value: null);

  bool get isUnlimited => _value == null;

  bool allows(int current) {
    if (isUnlimited) {
      return true;
    }

    return current < _value!;
  }

  int? get value => _value;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! Limit) {
      return false;
    }

    return _value == other._value;
  }

  @override
  int get hashCode => _value.hashCode;
}

class PlanLimit implements ValueObject {
  final Limit tracks;
  final Limit characters;

  PlanLimit({required this.tracks, required this.characters});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! PlanLimit) {
      return false;
    }

    return tracks == other.tracks && characters == other.characters;
  }

  @override
  int get hashCode => Object.hash(tracks, characters);
}

class PlanIdentifier extends ULIDBasedIdentifier {
  PlanIdentifier({required Ulid value}) : super(value);

  factory PlanIdentifier.generate() => PlanIdentifier(value: Ulid());

  factory PlanIdentifier.fromString(String value) =>
      PlanIdentifier(value: Ulid.parse(value));

  factory PlanIdentifier.fromBinary(Uint8List bytes) =>
      PlanIdentifier(value: Ulid.fromBytes(bytes));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! PlanIdentifier) {
      return false;
    }

    return value == other.value;
  }

  @override
  int get hashCode => value.hashCode;
}

enum PlanStatus { active, deprecated }

class Plan with Publishable<PlanEvent> {
  final PlanIdentifier identifier;
  final String name;
  final PlanLimit limits;
  final Price price;
  final Currency currency;
  final PlanStatus status;

  Plan({
    required this.identifier,
    required this.name,
    required this.limits,
    required this.price,
    required this.currency,
    required this.status,
  }) {
    if (price.amount == 0.0) {}
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! Plan) {
      return false;
    }

    return identifier == other.identifier;
  }

  @override
  int get hashCode => identifier.hashCode;
}

class SubscriptionIdentifier extends ULIDBasedIdentifier {
  SubscriptionIdentifier({required Ulid value}) : super(value);

  factory SubscriptionIdentifier.generate() =>
      SubscriptionIdentifier(value: Ulid());

  factory SubscriptionIdentifier.fromString(String value) =>
      SubscriptionIdentifier(value: Ulid.parse(value));

  factory SubscriptionIdentifier.fromBinary(Uint8List bytes) =>
      SubscriptionIdentifier(value: Ulid.fromBytes(bytes));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! SubscriptionIdentifier) {
      return false;
    }

    return value == other.value;
  }

  @override
  int get hashCode => value.hashCode;
}

class TransactionIdentifier extends ULIDBasedIdentifier {
  TransactionIdentifier({required Ulid value}) : super(value);

  factory TransactionIdentifier.generate() =>
      TransactionIdentifier(value: Ulid());

  factory TransactionIdentifier.fromString(String value) =>
      TransactionIdentifier(value: Ulid.parse(value));

  factory TransactionIdentifier.fromBinary(Uint8List bytes) =>
      TransactionIdentifier(value: Ulid.fromBytes(bytes));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! TransactionIdentifier) {
      return false;
    }

    return value == other.value;
  }

  @override
  int get hashCode => value.hashCode;
}

class PurchaseReceipt implements ValueObject {
  static const int maxProviderLength = 50;

  final String provider;
  final TransactionIdentifier transactionIdentifier;
  final String signature;

  PurchaseReceipt({
    required this.provider,
    required this.transactionIdentifier,
    required this.signature,
  }) {
    Invariant.length(
      value: provider,
      name: 'provider',
      min: 1,
      max: maxProviderLength,
    );

    Invariant.length(value: signature, name: 'signature', min: 1);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! PurchaseReceipt) {
      return false;
    }

    return provider == other.provider &&
        transactionIdentifier == other.transactionIdentifier &&
        signature == other.signature;
  }

  @override
  int get hashCode => Object.hash(provider, transactionIdentifier, signature);
}

enum SubscriptionStatus { active, expired, grace, canceled }

class OfflineGracePeriod implements ValueObject {
  final int days;

  OfflineGracePeriod._({required this.days}) {
    Invariant.range(value: days, name: 'days', min: 1, max: 30);
  }

  factory OfflineGracePeriod.days(int days) => OfflineGracePeriod._(days: days);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! OfflineGracePeriod) {
      return false;
    }

    return days == other.days;
  }

  @override
  int get hashCode => days.hashCode;
}

class Subscription with Publishable<SubscriptionEvent> {
  final SubscriptionIdentifier identifier;
  final PlanIdentifier plan;
  SubscriptionStatus status;
  final DateTime expiresAt;
  final DateTime? gracePeriodEndsAt;
  final OfflineGracePeriod offlineGracePeriod;
  final PurchaseReceipt receipt;
  DateTime lastSyncedAt;

  Subscription({
    required this.identifier,
    required this.plan,
    required this.status,
    required this.expiresAt,
    this.gracePeriodEndsAt,
    required this.offlineGracePeriod,
    required this.receipt,
    required this.lastSyncedAt,
  }) {
    if (gracePeriodEndsAt != null) {
      Invariant.greaterThanRight(
        left: gracePeriodEndsAt!,
        right: expiresAt,
        leftName: 'gracePeriodEndsAt',
        rightName: 'expiresAt',
        orEqualTo: true,
      );
    }
  }

  void updateStatus(SubscriptionStatus newStatus) {
    status = newStatus;
  }

  void updateLastSyncedAt(DateTime syncedAt) {
    lastSyncedAt = syncedAt;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! Subscription) {
      return false;
    }

    return identifier == other.identifier;
  }

  @override
  int get hashCode => identifier.hashCode;
}

class EntitlementIdentifier extends ULIDBasedIdentifier {
  EntitlementIdentifier({required Ulid value}) : super(value);

  factory EntitlementIdentifier.generate() =>
      EntitlementIdentifier(value: Ulid());

  factory EntitlementIdentifier.fromString(String value) =>
      EntitlementIdentifier(value: Ulid.parse(value));

  factory EntitlementIdentifier.fromBinary(Uint8List bytes) =>
      EntitlementIdentifier(value: Ulid.fromBytes(bytes));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! EntitlementIdentifier) {
      return false;
    }

    return value == other.value;
  }

  @override
  int get hashCode => value.hashCode;
}

class EntitlementUsage implements ValueObject {
  final int tracks;
  final int characters;

  EntitlementUsage({required this.tracks, required this.characters}) {
    Invariant.range(value: tracks, name: 'tracks', min: 0);

    Invariant.range(value: characters, name: 'characters', min: 0);
  }

  EntitlementUsage adjust({
    required int tracksDelta,
    required int charactersDelta,
  }) {
    final newTracks = tracks + tracksDelta;
    final newCharacters = characters + charactersDelta;

    Invariant.range(value: newTracks, name: 'adjusted tracks', min: 0);

    Invariant.range(value: newCharacters, name: 'adjusted characters', min: 0);

    return EntitlementUsage(tracks: newTracks, characters: newCharacters);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! EntitlementUsage) {
      return false;
    }

    return tracks == other.tracks && characters == other.characters;
  }

  @override
  int get hashCode => Object.hash(tracks, characters);
}

enum EntitlementStatus { active, restricted }

enum OverLimitType { tracks, characters }

class Entitlement with Publishable<EntitlementEvent> {
  final EntitlementIdentifier identifier;
  final PlanIdentifier plan;
  final SubscriptionIdentifier? subscription;
  int version;
  int lastProcessedSequenceNumber;
  PlanLimit limits;
  EntitlementUsage usage;
  EntitlementStatus status;

  Entitlement({
    required this.identifier,
    required this.plan,
    this.subscription,
    required this.version,
    required this.lastProcessedSequenceNumber,
    required this.limits,
    required this.usage,
    required this.status,
  });

  void syncWithPlan({
    required PlanIdentifier planIdentifier,
    required PlanLimit newLimits,
  }) {
    limits = newLimits;
    version++;

    if (!limits.tracks.allows(usage.tracks)) {
      status = EntitlementStatus.restricted;
      publish(
        EntitlementRestricted(
          entitlement: identifier,
          overLimitType: OverLimitType.tracks,
          currentUsage: usage,
          limits: limits,
          occurredAt: DateTime.now(),
        ),
      );
    } else if (!limits.characters.allows(usage.characters)) {
      status = EntitlementStatus.restricted;
      publish(
        EntitlementRestricted(
          entitlement: identifier,
          overLimitType: OverLimitType.characters,
          currentUsage: usage,
          limits: limits,
          occurredAt: DateTime.now(),
        ),
      );
    } else {
      status = EntitlementStatus.active;
    }

    publish(
      EntitlementUpdated(
        entitlement: identifier,
        limits: limits,
        usage: usage,
        status: status,
        occurredAt: DateTime.now(),
      ),
    );
  }

  void adjustUsage({
    required int tracksDelta,
    required int charactersDelta,
    required int sequenceNumber,
  }) {
    if (sequenceNumber <= lastProcessedSequenceNumber) {
      return;
    }

    usage = usage.adjust(
      tracksDelta: tracksDelta,
      charactersDelta: charactersDelta,
    );
    lastProcessedSequenceNumber = sequenceNumber;
    version++;

    if (!limits.tracks.allows(usage.tracks)) {
      status = EntitlementStatus.restricted;
      publish(
        EntitlementRestricted(
          entitlement: identifier,
          overLimitType: OverLimitType.tracks,
          currentUsage: usage,
          limits: limits,
          occurredAt: DateTime.now(),
        ),
      );
    } else if (!limits.characters.allows(usage.characters)) {
      status = EntitlementStatus.restricted;
      publish(
        EntitlementRestricted(
          entitlement: identifier,
          overLimitType: OverLimitType.characters,
          currentUsage: usage,
          limits: limits,
          occurredAt: DateTime.now(),
        ),
      );
    }

    publish(
      EntitlementUpdated(
        entitlement: identifier,
        limits: limits,
        usage: usage,
        status: status,
        occurredAt: DateTime.now(),
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! Entitlement) {
      return false;
    }

    return identifier == other.identifier;
  }

  @override
  int get hashCode => identifier.hashCode;
}

abstract class PlanEvent extends BaseEvent {
  PlanEvent(super.occurredAt);
}

class PlanUpdated extends PlanEvent {
  final PlanIdentifier plan;
  final PlanLimit limits;

  PlanUpdated({
    required this.plan,
    required this.limits,
    required DateTime occurredAt,
  }) : super(occurredAt);
}

abstract class SubscriptionEvent extends BaseEvent {
  SubscriptionEvent(super.occurredAt);
}

class SubscriptionActivated extends SubscriptionEvent {
  final SubscriptionIdentifier subscription;
  final PlanIdentifier plan;
  final DateTime expiresAt;

  SubscriptionActivated({
    required this.subscription,
    required this.plan,
    required this.expiresAt,
    required DateTime occurredAt,
  }) : super(occurredAt);
}

class SubscriptionExpired extends SubscriptionEvent {
  final SubscriptionIdentifier subscription;

  SubscriptionExpired({
    required this.subscription,
    required DateTime occurredAt,
  }) : super(occurredAt);
}

class SubscriptionGraceEntered extends SubscriptionEvent {
  final SubscriptionIdentifier subscription;
  final DateTime gracePeriodEndsAt;

  SubscriptionGraceEntered({
    required this.subscription,
    required this.gracePeriodEndsAt,
    required DateTime occurredAt,
  }) : super(occurredAt);
}

abstract class EntitlementEvent extends BaseEvent {
  EntitlementEvent(super.occurredAt);
}

class EntitlementUpdated extends EntitlementEvent {
  final EntitlementIdentifier entitlement;
  final PlanLimit limits;
  final EntitlementUsage usage;
  final EntitlementStatus status;

  EntitlementUpdated({
    required this.entitlement,
    required this.limits,
    required this.usage,
    required this.status,
    required DateTime occurredAt,
  }) : super(occurredAt);
}

class EntitlementRestricted extends EntitlementEvent {
  final EntitlementIdentifier entitlement;
  final OverLimitType overLimitType;
  final EntitlementUsage currentUsage;
  final PlanLimit limits;

  EntitlementRestricted({
    required this.entitlement,
    required this.overLimitType,
    required this.currentUsage,
    required this.limits,
    required DateTime occurredAt,
  }) : super(occurredAt);
}

class EntitlementQuotaAdjusted extends EntitlementEvent {
  final EntitlementIdentifier entitlement;
  final PlanLimit limits;

  EntitlementQuotaAdjusted({
    required this.entitlement,
    required this.limits,
    required DateTime occurredAt,
  }) : super(occurredAt);
}

abstract class PlanRepository {
  Future<Plan> find(PlanIdentifier identifier);
  Future<List<Plan>> all();
  Future<void> persist(Plan plan);
}

abstract class SubscriptionRepository {
  Future<Subscription> find(SubscriptionIdentifier identifier);
  Future<void> persist(Subscription subscription);
}

abstract class EntitlementRepository {
  Future<Entitlement> find(EntitlementIdentifier identifier);
  Future<void> persist(Entitlement entitlement);
}

abstract class EntitlementService {
  Future<bool> canAddTrack(int currentTrackCount);
  Future<bool> canUseCharacter(int currentCharacterCount);
  Future<int> getTrackLimit();
  Future<int> getCharacterLimit();
}
