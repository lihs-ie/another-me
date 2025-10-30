import 'package:another_me/domains/notification/notification.dart';
import 'package:another_me/domains/profile/profile.dart';
import 'package:flutter/material.dart' hide Builder;
import 'package:ulid/ulid.dart';

import '../common.dart';
import '../common/error.dart';
import '../common/identifier.dart';
import '../enum.dart';
import '../profile/profile.dart';
import '../string.dart';

class NotificationRuleIdentifierFactory
    extends ULIDBasedIdentifierFactory<NotificationRuleIdentifier> {
  NotificationRuleIdentifierFactory()
    : super((Ulid value) => NotificationRuleIdentifier(value: value));
}

typedef NotificationTemplateOverrides = ({
  String? template,
  Set<TemplatePlaceholder>? requiredPlaceholders,
});

class NotificationTemplateFactory
    extends Factory<NotificationTemplate, NotificationTemplateOverrides> {
  @override
  NotificationTemplate create({
    NotificationTemplateOverrides? overrides,
    required int seed,
  }) {
    final requiredPlaceholders =
        overrides?.requiredPlaceholders ??
        {
          if (seed % 3 == 0) TemplatePlaceholder.phaseName,
          if (seed % 3 == 1) TemplatePlaceholder.trackTitle,
          if (seed % 3 == 2) TemplatePlaceholder.remainingMinutes,
        };

    final template =
        overrides?.template ??
        _generateTemplateWithPlaceholders(seed, requiredPlaceholders);

    return NotificationTemplate(
      template: template,
      requiredPlaceholders: requiredPlaceholders,
    );
  }

  String _generateTemplateWithPlaceholders(
    int seed,
    Set<TemplatePlaceholder> placeholders,
  ) {
    if (placeholders.isEmpty) {
      return StringFactory.create(seed: seed, min: 1, max: 100);
    }

    final buffer = StringBuffer();

    for (final placeholder in placeholders) {
      buffer.write('{{${placeholder.name}}} ');
    }

    buffer.write(StringFactory.create(seed: seed, min: 1, max: 50));

    return buffer.toString();
  }

  @override
  NotificationTemplate duplicate(
    NotificationTemplate instance,
    NotificationTemplateOverrides? overrides,
  ) {
    final template = overrides?.template ?? instance.template;

    final requiredPlaceholders =
        overrides?.requiredPlaceholders ?? instance.requiredPlaceholders;

    return NotificationTemplate(
      template: template,
      requiredPlaceholders: requiredPlaceholders,
    );
  }
}

typedef NotificationContextOverrides = ({Map<String, String>? values});

class NotificationContextFactory
    extends Factory<NotificationContext, NotificationContextOverrides> {
  @override
  NotificationContext create({
    NotificationContextOverrides? overrides,
    required int seed,
  }) {
    final values =
        overrides?.values ??
        {
          'remainingMinutes': ((seed % 60) + 1).toString(),
          'remainingSeconds': (seed % 60).toString(),
          'phaseName': 'Phase ${seed % 10}',
          'trackTitle': 'Track ${seed % 100}',
          'artistName': 'Artist ${seed % 50}',
        };

    return NotificationContext(values: values);
  }

  @override
  NotificationContext duplicate(
    NotificationContext instance,
    NotificationContextOverrides? overrides,
  ) {
    final values = overrides?.values ?? instance.values;

    return NotificationContext(values: values);
  }
}

class PomodoroPhaseStartedEventFactory
    extends Factory<PomodoroPhaseStartedEvent, void> {
  @override
  PomodoroPhaseStartedEvent create({void overrides, required int seed}) {
    return PomodoroPhaseStartedEvent();
  }

  @override
  PomodoroPhaseStartedEvent duplicate(
    PomodoroPhaseStartedEvent instance,
    void overrides,
  ) {
    return PomodoroPhaseStartedEvent();
  }
}

class PomodoroSessionCompletedEventFactory
    extends Factory<PomodoroSessionCompletedEvent, void> {
  @override
  PomodoroSessionCompletedEvent create({void overrides, required int seed}) {
    return PomodoroSessionCompletedEvent();
  }

  @override
  PomodoroSessionCompletedEvent duplicate(
    PomodoroSessionCompletedEvent instance,
    void overrides,
  ) {
    return PomodoroSessionCompletedEvent();
  }
}

class TrackRegisteredEventFactory extends Factory<TrackRegisteredEvent, void> {
  @override
  TrackRegisteredEvent create({void overrides, required int seed}) {
    return TrackRegisteredEvent();
  }

  @override
  TrackRegisteredEvent duplicate(
    TrackRegisteredEvent instance,
    void overrides,
  ) {
    return TrackRegisteredEvent();
  }
}

class TrackDeprecatedEventFactory extends Factory<TrackDeprecatedEvent, void> {
  @override
  TrackDeprecatedEvent create({void overrides, required int seed}) {
    return TrackDeprecatedEvent();
  }

  @override
  TrackDeprecatedEvent duplicate(
    TrackDeprecatedEvent instance,
    void overrides,
  ) {
    return TrackDeprecatedEvent();
  }
}

class DayPeriodChangedEventFactory
    extends Factory<DayPeriodChangedEvent, void> {
  @override
  DayPeriodChangedEvent create({void overrides, required int seed}) {
    return DayPeriodChangedEvent();
  }

  @override
  DayPeriodChangedEvent duplicate(
    DayPeriodChangedEvent instance,
    void overrides,
  ) {
    return DayPeriodChangedEvent();
  }
}

class NotificationChannelFactory extends EnumFactory<NotificationChannel> {
  NotificationChannelFactory() : super(NotificationChannel.values);
}

typedef QuietHoursOverrides = ({TimeOfDay? startTime, TimeOfDay? endTime});

class QuietHoursFactory extends Factory<QuietHours, QuietHoursOverrides> {
  @override
  QuietHours create({QuietHoursOverrides? overrides, required int seed}) {
    final startHour = (seed % 24);

    final startTime =
        overrides?.startTime ?? TimeOfDay(hour: startHour, minute: 0);

    final endHour = (startHour + 1 + (seed % 12)) % 24;

    final endTime = overrides?.endTime ?? TimeOfDay(hour: endHour, minute: 0);

    return QuietHours(startTime: startTime, endTime: endTime);
  }

  @override
  QuietHours duplicate(QuietHours instance, QuietHoursOverrides? overrides) {
    final startTime = overrides?.startTime ?? instance.startTime;

    final endTime = overrides?.endTime ?? instance.endTime;

    return QuietHours(startTime: startTime, endTime: endTime);
  }
}

typedef NotificationChannelSettingOverrides = ({
  NotificationEventType? eventType,
  Set<NotificationChannel>? channels,
  NotificationTemplate? template,
});

class NotificationChannelSettingFactory
    extends
        Factory<
          NotificationChannelSetting,
          NotificationChannelSettingOverrides
        > {
  @override
  NotificationChannelSetting create({
    NotificationChannelSettingOverrides? overrides,
    required int seed,
  }) {
    final eventType =
        overrides?.eventType ??
        Builder(PomodoroPhaseStartedEventFactory()).buildWith(seed: seed);

    final channels =
        overrides?.channels ??
        {
          if (seed % 2 == 0) NotificationChannel.desktop,
          if (seed % 3 == 0) NotificationChannel.menuBar,
          if (seed % 5 == 0) NotificationChannel.sound,
        }.where((element) => true).toSet();

    final channelsNonEmpty = channels.isEmpty
        ? {NotificationChannel.desktop}
        : channels;

    final template =
        overrides?.template ??
        Builder(NotificationTemplateFactory()).buildWith(
          seed: seed,
          overrides: (
            template: null,
            requiredPlaceholders: eventType.requiredPlaceholders,
          ),
        );

    return NotificationChannelSetting(
      eventType: eventType,
      channels: channelsNonEmpty,
      template: template,
    );
  }

  @override
  NotificationChannelSetting duplicate(
    NotificationChannelSetting instance,
    NotificationChannelSettingOverrides? overrides,
  ) {
    final eventType = overrides?.eventType ?? instance.eventType;

    final channels = overrides?.channels ?? instance.channels;

    final template = overrides?.template ?? instance.template;

    return NotificationChannelSetting(
      eventType: eventType,
      channels: channels,
      template: template,
    );
  }
}

typedef NotificationHistoryOverrides = ({Map<String, DateTime>? lastSentTimes});

class NotificationHistoryFactory
    extends Factory<NotificationHistory, NotificationHistoryOverrides> {
  @override
  NotificationHistory create({
    NotificationHistoryOverrides? overrides,
    required int seed,
  }) {
    if (overrides?.lastSentTimes != null) {
      return _createFromMap(overrides!.lastSentTimes!);
    }

    final history = NotificationHistory.empty();

    if (seed % 2 == 0) {
      return history;
    }

    var result = history;

    final eventTypes = <NotificationEventType>[
      PomodoroPhaseStartedEvent(),
      TrackRegisteredEvent(),
    ];

    for (var i = 0; i < (seed % 3); i++) {
      final eventType = eventTypes[i % eventTypes.length];

      result = result.recordSent(
        eventType: eventType,
        sentAt: DateTime(2025, 1, 1).add(Duration(minutes: seed + i)),
      );
    }

    return result;
  }

  NotificationHistory _createFromMap(Map<String, DateTime> lastSentTimes) {
    var history = NotificationHistory.empty();

    for (final entry in lastSentTimes.entries) {
      final eventType = _eventTypeFromName(entry.key);

      history = history.recordSent(eventType: eventType, sentAt: entry.value);
    }

    return history;
  }

  NotificationEventType _eventTypeFromName(String name) {
    switch (name) {
      case 'PomodoroPhaseStarted':
        return PomodoroPhaseStartedEvent();
      case 'PomodoroSessionCompleted':
        return PomodoroSessionCompletedEvent();
      case 'TrackRegistered':
        return TrackRegisteredEvent();
      case 'TrackDeprecated':
        return TrackDeprecatedEvent();
      case 'DayPeriodChanged':
        return DayPeriodChangedEvent();
      default:
        throw ArgumentError('Unknown event type: $name');
    }
  }

  @override
  NotificationHistory duplicate(
    NotificationHistory instance,
    NotificationHistoryOverrides? overrides,
  ) {
    if (overrides?.lastSentTimes != null) {
      return _createFromMap(overrides!.lastSentTimes!);
    }

    final eventTypes = <NotificationEventType>[
      PomodoroPhaseStartedEvent(),
      TrackRegisteredEvent(),
    ];

    var result = NotificationHistory.empty();

    for (final eventType in eventTypes) {
      final elapsed = instance.elapsedSince(
        eventType: eventType,
        now: DateTime.now(),
      );

      if (elapsed != null) {
        final sentAt = DateTime.now().subtract(elapsed);

        result = result.recordSent(eventType: eventType, sentAt: sentAt);
      }
    }

    return result;
  }
}

typedef NotificationRuleOverrides = ({
  NotificationRuleIdentifier? identifier,
  ProfileIdentifier? profile,
  Map<String, NotificationChannelSetting>? channelSettings,
  QuietHours? quietHours,
  bool? dndEnabled,
  NotificationHistory? history,
  Duration? minimumNotificationInterval,
});

class NotificationRuleFactory
    extends Factory<NotificationRule, NotificationRuleOverrides> {
  @override
  NotificationRule create({
    NotificationRuleOverrides? overrides,
    required int seed,
  }) {
    final identifier =
        overrides?.identifier ??
        Builder(NotificationRuleIdentifierFactory()).buildWith(seed: seed);

    final profile =
        overrides?.profile ??
        Builder(ProfileIdentifierFactory()).buildWith(seed: seed);

    final channelSettings =
        overrides?.channelSettings ??
        {
          'PomodoroPhaseStarted': Builder(NotificationChannelSettingFactory())
              .buildWith(
                seed: seed,
                overrides: (
                  eventType: PomodoroPhaseStartedEvent(),
                  channels: null,
                  template: null,
                ),
              ),
          'TrackRegistered': Builder(NotificationChannelSettingFactory())
              .buildWith(
                seed: seed + 1,
                overrides: (
                  eventType: TrackRegisteredEvent(),
                  channels: null,
                  template: null,
                ),
              ),
        };

    final quietHours =
        overrides?.quietHours ??
        Builder(QuietHoursFactory()).buildWith(seed: seed);

    final dndEnabled = overrides?.dndEnabled ?? (seed % 4 == 0);

    final history =
        overrides?.history ??
        Builder(NotificationHistoryFactory()).buildWith(seed: seed);

    final minimumNotificationInterval =
        overrides?.minimumNotificationInterval ??
        Duration(minutes: (seed % 30) + 1);

    return NotificationRule(
      identifier: identifier,
      profile: profile,
      channelSettings: channelSettings,
      quietHours: quietHours,
      dndEnabled: dndEnabled,
      history: history,
      minimumNotificationInterval: minimumNotificationInterval,
    );
  }

  @override
  NotificationRule duplicate(
    NotificationRule instance,
    NotificationRuleOverrides? overrides,
  ) {
    final identifier = overrides?.identifier ?? instance.identifier;

    final profile = overrides?.profile ?? instance.profile;

    final channelSettings = overrides?.channelSettings ?? {};

    final quietHours =
        overrides?.quietHours ??
        Builder(
          QuietHoursFactory(),
        ).duplicate(instance: instance.quietHours, overrides: null);

    final dndEnabled = overrides?.dndEnabled ?? instance.dndEnabled;

    final history = overrides?.history ?? NotificationHistory.empty();

    final minimumNotificationInterval =
        overrides?.minimumNotificationInterval ??
        instance.minimumNotificationInterval;

    return NotificationRule(
      identifier: identifier,
      profile: profile,
      channelSettings: channelSettings,
      quietHours: quietHours,
      dndEnabled: dndEnabled,
      history: history,
      minimumNotificationInterval: minimumNotificationInterval,
    );
  }
}

typedef NotificationRuleRepositoryOverrides = ({
  List<NotificationRule>? instances,
  void Function(NotificationRule)? onPersist,
});

class _NotificationRuleRepository implements NotificationRuleRepository {
  final Map<ProfileIdentifier, NotificationRule> _instances;
  final void Function(NotificationRule)? _onPersist;

  _NotificationRuleRepository({
    required List<NotificationRule> instances,
    void Function(NotificationRule)? onPersist,
  }) : _instances = {
         for (final instance in instances) instance.profile: instance,
       },
       _onPersist = onPersist;

  @override
  Future<NotificationRule> find(ProfileIdentifier identifier) {
    final instance = _instances[identifier];

    if (instance == null) {
      throw AggregateNotFoundError(
        'NotificationRule with profile identifier ${identifier.value} not found.',
      );
    }

    return Future.value(instance);
  }

  @override
  Future<void> persist(NotificationRule rule) {
    _instances[rule.profile] = rule;

    if (_onPersist != null) {
      _onPersist(rule);
    }

    return Future.value();
  }
}

class NotificationRuleRepositoryFactory
    extends
        Factory<
          NotificationRuleRepository,
          NotificationRuleRepositoryOverrides
        > {
  @override
  NotificationRuleRepository create({
    NotificationRuleRepositoryOverrides? overrides,
    required int seed,
  }) {
    final instances =
        overrides?.instances ??
        Builder(
          NotificationRuleFactory(),
        ).buildListWith(count: (seed % 5) + 1, seed: seed);

    return _NotificationRuleRepository(
      instances: instances,
      onPersist: overrides?.onPersist,
    );
  }

  @override
  NotificationRuleRepository duplicate(
    NotificationRuleRepository instance,
    NotificationRuleRepositoryOverrides? overrides,
  ) {
    throw UnimplementedError();
  }
}
