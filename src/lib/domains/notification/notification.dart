import 'package:another_me/domains/common/event.dart';
import 'package:another_me/domains/common/identifier.dart';
import 'package:another_me/domains/common/value_object.dart';
import 'package:another_me/domains/common/variant.dart';
import 'package:another_me/domains/profile/profile.dart';
import 'package:flutter/material.dart';
import 'package:ulid/ulid.dart';

enum TemplatePlaceholder {
  remainingMinutes('remainingMinutes'),
  remainingSeconds('remainingSeconds'),
  phaseName('phaseName'),
  trackTitle('trackTitle'),
  artistName('artistName');

  final String name;

  const TemplatePlaceholder(this.name);
}

class NotificationTemplate implements ValueObject {
  final String template;
  final Set<TemplatePlaceholder> requiredPlaceholders;

  NotificationTemplate({
    required this.template,
    required this.requiredPlaceholders,
  }) {
    Invariant.length(value: template, name: 'template', min: 1, max: 200);
    _validatePlaceholders();
  }

  void _validatePlaceholders() {
    final foundPlaceholders = _extractPlaceholders(template);

    for (final required in requiredPlaceholders) {
      if (!foundPlaceholders.contains(required.name)) {
        throw InvariantViolationError(
          'Required placeholder ${required.name} not found in template.',
        );
      }
    }
  }

  Set<String> _extractPlaceholders(String text) {
    final regex = RegExp(r'\{\{(\w+)\}\}');
    final matches = regex.allMatches(text);
    return matches.map((match) => match.group(1)!).toSet();
  }

  String render(NotificationContext context) {
    var result = template;

    for (final placeholder in requiredPlaceholders) {
      final value = context.getValue(placeholder);
      result = result.replaceAll('{{${placeholder.name}}}', value);
    }

    return result;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! NotificationTemplate) {
      return false;
    }

    return template == other.template &&
        _setEquals(requiredPlaceholders, other.requiredPlaceholders);
  }

  @override
  int get hashCode => Object.hash(template, requiredPlaceholders);

  bool _setEquals<T>(Set<T> a, Set<T> b) {
    if (a.length != b.length) {
      return false;
    }

    return a.every(b.contains);
  }
}

class NotificationContext implements ValueObject {
  final Map<String, String> values;

  NotificationContext({required this.values});

  factory NotificationContext.forPomodoroPhase({
    required int remainingMinutes,
    required int remainingSeconds,
    required String phaseName,
  }) {
    return NotificationContext(
      values: {
        'remainingMinutes': remainingMinutes.toString(),
        'remainingSeconds': remainingSeconds.toString(),
        'phaseName': phaseName,
        'totalMinutes': ((remainingMinutes * 60 + remainingSeconds) ~/ 60)
            .toString(),
      },
    );
  }

  factory NotificationContext.forTrackRegistered({
    required String trackTitle,
    required String artistName,
  }) {
    return NotificationContext(
      values: {'trackTitle': trackTitle, 'artistName': artistName},
    );
  }

  factory NotificationContext.empty() {
    return NotificationContext(values: {});
  }

  String getValue(TemplatePlaceholder placeholder) {
    final value = values[placeholder.name];

    if (value == null) {
      throw ArgumentError(
        'Placeholder ${placeholder.name} not found in context.',
      );
    }

    return value;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! NotificationContext) {
      return false;
    }

    if (values.length != other.values.length) {
      return false;
    }

    for (final entry in values.entries) {
      if (other.values[entry.key] != entry.value) {
        return false;
      }
    }

    return true;
  }

  @override
  int get hashCode {
    final sortedKeys = values.keys.toList()..sort();

    return Object.hashAll(
      sortedKeys.map((key) => Object.hash(key, values[key])),
    );
  }
}

abstract class NotificationEventType implements ValueObject {
  String get name;
  Set<TemplatePlaceholder> get requiredPlaceholders;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! NotificationEventType) {
      return false;
    }

    return name == other.name;
  }

  @override
  int get hashCode => name.hashCode;
}

class PomodoroPhaseStartedEvent extends NotificationEventType {
  @override
  String get name => 'PomodoroPhaseStarted';

  @override
  Set<TemplatePlaceholder> get requiredPlaceholders => {
    TemplatePlaceholder.phaseName,
    TemplatePlaceholder.remainingMinutes,
    TemplatePlaceholder.remainingSeconds,
  };
}

class PomodoroSessionCompletedEvent extends NotificationEventType {
  @override
  String get name => 'PomodoroSessionCompleted';

  @override
  Set<TemplatePlaceholder> get requiredPlaceholders => {
    TemplatePlaceholder.phaseName,
  };
}

class TrackRegisteredEvent extends NotificationEventType {
  @override
  String get name => 'TrackRegistered';

  @override
  Set<TemplatePlaceholder> get requiredPlaceholders => {
    TemplatePlaceholder.trackTitle,
    TemplatePlaceholder.artistName,
  };
}

class TrackDeprecatedEvent extends NotificationEventType {
  @override
  String get name => 'TrackDeprecated';

  @override
  Set<TemplatePlaceholder> get requiredPlaceholders => {
    TemplatePlaceholder.trackTitle,
  };
}

class DayPeriodChangedEvent extends NotificationEventType {
  @override
  String get name => 'DayPeriodChanged';

  @override
  Set<TemplatePlaceholder> get requiredPlaceholders => {};
}

enum NotificationChannel { desktop, menuBar, sound }

class QuietHours implements ValueObject {
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool spansMidnight;

  QuietHours({required this.startTime, required this.endTime})
    : spansMidnight = _calculateSpansMidnight(startTime, endTime) {
    if (startTime == endTime) {
      throw InvariantViolationError(
        'startTime and endTime cannot be the same.',
      );
    }
  }

  static bool _calculateSpansMidnight(TimeOfDay start, TimeOfDay end) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    return startMinutes > endMinutes;
  }

  bool isQuietTime(DateTime now) {
    final currentTime = TimeOfDay.fromDateTime(now);
    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    if (spansMidnight) {
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    } else {
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! QuietHours) {
      return false;
    }

    return startTime == other.startTime && endTime == other.endTime;
  }

  @override
  int get hashCode => Object.hash(startTime, endTime);
}

class NotificationChannelSetting implements ValueObject {
  final NotificationEventType eventType;
  final Set<NotificationChannel> channels;
  final NotificationTemplate template;

  NotificationChannelSetting({
    required this.eventType,
    required this.channels,
    required this.template,
  }) {
    if (channels.isEmpty) {
      throw InvariantViolationError('channels cannot be empty.');
    }

    _validateTemplateCompatibility();
  }

  void _validateTemplateCompatibility() {
    final requiredForEvent = eventType.requiredPlaceholders;

    if (!template.requiredPlaceholders.containsAll(requiredForEvent)) {
      throw InvariantViolationError(
        'Template missing required placeholders for ${eventType.name}.',
      );
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! NotificationChannelSetting) {
      return false;
    }

    return eventType == other.eventType &&
        _setEquals(channels, other.channels) &&
        template == other.template;
  }

  @override
  int get hashCode => Object.hash(eventType, channels, template);

  bool _setEquals<T>(Set<T> a, Set<T> b) {
    if (a.length != b.length) {
      return false;
    }

    return a.every(b.contains);
  }
}

class NotificationHistory implements ValueObject {
  final Map<String, DateTime> _lastSentTimes;

  NotificationHistory._({required Map<String, DateTime> lastSentTimes})
    : _lastSentTimes = Map.unmodifiable(lastSentTimes);

  factory NotificationHistory.empty() {
    return NotificationHistory._(lastSentTimes: {});
  }

  bool shouldSuppress({
    required NotificationEventType eventType,
    required DateTime now,
    required Duration minimumInterval,
  }) {
    final lastSent = _lastSentTimes[eventType.name];

    if (lastSent == null) {
      return false;
    }

    final elapsed = now.difference(lastSent);
    return elapsed < minimumInterval;
  }

  NotificationHistory recordSent({
    required NotificationEventType eventType,
    required DateTime sentAt,
  }) {
    final updated = Map<String, DateTime>.from(_lastSentTimes);
    updated[eventType.name] = sentAt;

    return NotificationHistory._(lastSentTimes: updated);
  }

  Duration? elapsedSince({
    required NotificationEventType eventType,
    required DateTime now,
  }) {
    final lastSent = _lastSentTimes[eventType.name];

    if (lastSent == null) {
      return null;
    }

    return now.difference(lastSent);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! NotificationHistory) {
      return false;
    }

    if (_lastSentTimes.length != other._lastSentTimes.length) {
      return false;
    }

    for (final entry in _lastSentTimes.entries) {
      if (other._lastSentTimes[entry.key] != entry.value) {
        return false;
      }
    }

    return true;
  }

  @override
  int get hashCode => Object.hashAll(_lastSentTimes.entries);
}

class NotificationRuleIdentifier extends ULIDBasedIdentifier {
  NotificationRuleIdentifier({required Ulid value}) : super(value);

  factory NotificationRuleIdentifier.generate() {
    return NotificationRuleIdentifier(value: Ulid());
  }
}

abstract class NotificationEvent extends BaseEvent {
  NotificationEvent(super.occurredAt);
}

class NotificationRuleCreated extends NotificationEvent {
  final NotificationRuleIdentifier identifier;
  final ProfileIdentifier profile;

  NotificationRuleCreated({
    required this.identifier,
    required this.profile,
    required DateTime occurredAt,
  }) : super(occurredAt);
}

class NotificationRuleUpdated extends NotificationEvent {
  final NotificationRuleIdentifier identifier;
  final ProfileIdentifier profile;
  final bool dndEnabled;

  NotificationRuleUpdated({
    required this.identifier,
    required this.profile,
    required this.dndEnabled,
    required DateTime occurredAt,
  }) : super(occurredAt);
}

class NotificationRequested extends NotificationEvent {
  final NotificationRuleIdentifier identifier;
  final NotificationEventType eventType;
  final NotificationContext context;
  final Set<NotificationChannel> channels;
  final String renderedMessage;

  NotificationRequested({
    required this.identifier,
    required this.eventType,
    required this.context,
    required this.channels,
    required this.renderedMessage,
    required DateTime occurredAt,
  }) : super(occurredAt);
}

class NotificationSuppressed extends NotificationEvent {
  final NotificationRuleIdentifier identifier;
  final NotificationEventType eventType;
  final String reason;

  NotificationSuppressed({
    required this.identifier,
    required this.eventType,
    required this.reason,
    required DateTime occurredAt,
  }) : super(occurredAt);
}

class NotificationResult {
  final bool sent;
  final String? message;

  NotificationResult._({required this.sent, this.message});

  factory NotificationResult.sentResult(String message) {
    return NotificationResult._(sent: true, message: message);
  }

  factory NotificationResult.suppressed(String reason) {
    return NotificationResult._(sent: false, message: reason);
  }
}

class NotificationRule with Publishable<NotificationEvent> {
  final NotificationRuleIdentifier identifier;
  final ProfileIdentifier profile;
  final Map<String, NotificationChannelSetting> _channelSettings;
  QuietHours quietHours;
  bool dndEnabled;
  NotificationHistory _history;
  Duration minimumNotificationInterval;

  NotificationRule({
    required this.identifier,
    required this.profile,
    required Map<String, NotificationChannelSetting> channelSettings,
    required this.quietHours,
    required this.dndEnabled,
    required NotificationHistory history,
    required this.minimumNotificationInterval,
  }) : _channelSettings = channelSettings,
       _history = history {
    Invariant.range(
      value: minimumNotificationInterval.inSeconds,
      name: 'minimumNotificationInterval',
      min: 1,
    );
  }

  factory NotificationRule.create({
    required ProfileIdentifier profile,
    required Map<NotificationEventType, NotificationChannelSetting>
    channelSettings,
    required QuietHours quietHours,
  }) {
    final identifier = NotificationRuleIdentifier.generate();

    final mappedSettings = <String, NotificationChannelSetting>{};

    for (final entry in channelSettings.entries) {
      mappedSettings[entry.key.name] = entry.value;
    }

    final rule = NotificationRule(
      identifier: identifier,
      profile: profile,
      channelSettings: mappedSettings,
      quietHours: quietHours,
      dndEnabled: false,
      history: NotificationHistory.empty(),
      minimumNotificationInterval: const Duration(minutes: 5),
    );

    rule.publish(
      NotificationRuleCreated(
        identifier: identifier,
        profile: profile,
        occurredAt: DateTime.now(),
      ),
    );

    return rule;
  }

  NotificationResult evaluateNotification({
    required NotificationEventType eventType,
    required NotificationContext context,
    required DateTime now,
  }) {
    if (dndEnabled) {
      publish(
        NotificationSuppressed(
          identifier: identifier,
          eventType: eventType,
          reason: 'DND is enabled',
          occurredAt: now,
        ),
      );

      return NotificationResult.suppressed('DND is enabled');
    }

    if (quietHours.isQuietTime(now)) {
      publish(
        NotificationSuppressed(
          identifier: identifier,
          eventType: eventType,
          reason: 'Quiet hours active',
          occurredAt: now,
        ),
      );

      return NotificationResult.suppressed('Quiet hours active');
    }

    if (_history.shouldSuppress(
      eventType: eventType,
      now: now,
      minimumInterval: minimumNotificationInterval,
    )) {
      publish(
        NotificationSuppressed(
          identifier: identifier,
          eventType: eventType,
          reason: 'Sent too recently',
          occurredAt: now,
        ),
      );

      return NotificationResult.suppressed('Sent too recently');
    }

    final setting = _channelSettings[eventType.name];

    if (setting == null) {
      return NotificationResult.suppressed('No channel setting for event type');
    }

    final renderedMessage = setting.template.render(context);

    _history = _history.recordSent(eventType: eventType, sentAt: now);

    publish(
      NotificationRequested(
        identifier: identifier,
        eventType: eventType,
        context: context,
        channels: setting.channels,
        renderedMessage: renderedMessage,
        occurredAt: now,
      ),
    );

    return NotificationResult.sentResult(renderedMessage);
  }

  void toggleDnd(bool enabled) {
    dndEnabled = enabled;

    publish(
      NotificationRuleUpdated(
        identifier: identifier,
        profile: profile,
        dndEnabled: dndEnabled,
        occurredAt: DateTime.now(),
      ),
    );
  }

  void updateQuietHours(QuietHours newQuietHours) {
    quietHours = newQuietHours;

    publish(
      NotificationRuleUpdated(
        identifier: identifier,
        profile: profile,
        dndEnabled: dndEnabled,
        occurredAt: DateTime.now(),
      ),
    );
  }

  void updateChannelSetting({
    required NotificationEventType eventType,
    required NotificationChannelSetting setting,
  }) {
    _channelSettings[eventType.name] = setting;

    publish(
      NotificationRuleUpdated(
        identifier: identifier,
        profile: profile,
        dndEnabled: dndEnabled,
        occurredAt: DateTime.now(),
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! NotificationRule) {
      return false;
    }

    return identifier == other.identifier;
  }

  @override
  int get hashCode => identifier.hashCode;
}

abstract class NotificationRuleRepository {
  Future<NotificationRule> find(ProfileIdentifier identifier);
  Future<void> persist(NotificationRule rule);
}
