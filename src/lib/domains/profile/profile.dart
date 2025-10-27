import 'dart:typed_data';

import 'package:another_me/domains/avatar/avatar.dart';
import 'package:another_me/domains/common/date.dart';
import 'package:another_me/domains/common/event.dart';
import 'package:another_me/domains/common/identifier.dart';
import 'package:another_me/domains/common/locale.dart';
import 'package:another_me/domains/common/playback.dart';
import 'package:another_me/domains/common/range.dart';
import 'package:another_me/domains/common/theme.dart';
import 'package:another_me/domains/common/transaction.dart';
import 'package:another_me/domains/common/value_object.dart';
import 'package:another_me/domains/common/variant.dart';
import 'package:another_me/domains/scene/scene.dart';
import 'package:logger/logger.dart';
import 'package:ulid/ulid.dart';

class ProfileIdentifier extends ULIDBasedIdentifier {
  ProfileIdentifier({required Ulid value}) : super(value);

  factory ProfileIdentifier.generate() => ProfileIdentifier(value: Ulid());

  factory ProfileIdentifier.fromString(String value) =>
      ProfileIdentifier(value: Ulid.parse(value));

  factory ProfileIdentifier.fromBinary(Uint8List bytes) =>
      ProfileIdentifier(value: Ulid.fromBytes(bytes));
}

class OutputDeviceIdentifier extends ULIDBasedIdentifier {
  OutputDeviceIdentifier({required Ulid value}) : super(value);

  factory OutputDeviceIdentifier.generate() =>
      OutputDeviceIdentifier(value: Ulid());

  factory OutputDeviceIdentifier.fromString(String value) =>
      OutputDeviceIdentifier(value: Ulid.parse(value));

  factory OutputDeviceIdentifier.fromBinary(Uint8List bytes) =>
      OutputDeviceIdentifier(value: Ulid.fromBytes(bytes));
}

class AppearanceSettings implements ValueObject {
  final CharacterIdentifier character;
  final SceneIdentifier scene;
  final ThemeMode theme;
  final OutfitMode outfitMode;

  AppearanceSettings({
    required this.character,
    required this.scene,
    required this.theme,
    required this.outfitMode,
  });

  AppearanceSettings changeCharacter(CharacterIdentifier next) {
    return AppearanceSettings(
      character: next,
      scene: scene,
      theme: theme,
      outfitMode: outfitMode,
    );
  }

  AppearanceSettings changeScene(SceneIdentifier next) {
    return AppearanceSettings(
      character: character,
      scene: next,
      theme: theme,
      outfitMode: outfitMode,
    );
  }

  AppearanceSettings changeTheme(ThemeMode next) {
    return AppearanceSettings(
      character: character,
      scene: scene,
      theme: next,
      outfitMode: outfitMode,
    );
  }

  AppearanceSettings changeOutfit(OutfitMode next) {
    return AppearanceSettings(
      character: character,
      scene: scene,
      theme: theme,
      outfitMode: next,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! AppearanceSettings) {
      return false;
    }

    if (character != other.character) {
      return false;
    }

    if (scene != other.scene) {
      return false;
    }

    if (theme != other.theme) {
      return false;
    }

    if (outfitMode != other.outfitMode) {
      return false;
    }

    return true;
  }
}

class PlaybackSettings implements ValueObject {
  final LoopMode loopMode;
  final FadeDuration fade;
  final VolumeLevel volume;
  final bool mute;
  final OutputDeviceIdentifier? outputDevice;

  PlaybackSettings({
    required this.loopMode,
    required this.fade,
    required this.volume,
    required this.mute,
    this.outputDevice,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! PlaybackSettings) {
      return false;
    }

    if (loopMode != other.loopMode) {
      return false;
    }

    if (fade != other.fade) {
      return false;
    }

    if (volume != other.volume) {
      return false;
    }

    if (mute != other.mute) {
      return false;
    }

    if (outputDevice != other.outputDevice) {
      return false;
    }

    return true;
  }
}

class PomodoroPolicy implements ValueObject {
  final int workMinutes;
  final int breakMinutes;
  final int longBreakMinutes;
  final int longBreakEvery;

  PomodoroPolicy({
    required this.workMinutes,
    required this.breakMinutes,
    required this.longBreakMinutes,
    required this.longBreakEvery,
  }) {
    Invariant.range(value: workMinutes, name: 'workMinutes', min: 1, max: 120);
    Invariant.range(
      value: breakMinutes,
      name: 'breakMinutes',
      min: 1,
      max: 120,
    );
    Invariant.range(
      value: longBreakMinutes,
      name: 'longBreakMinutes',
      min: 1,
      max: 120,
    );
    Invariant.range(value: longBreakEvery, name: 'longBreakEvery', min: 1);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! PomodoroPolicy) {
      return false;
    }

    if (workMinutes != other.workMinutes) {
      return false;
    }

    if (breakMinutes != other.breakMinutes) {
      return false;
    }

    if (longBreakMinutes != other.longBreakMinutes) {
      return false;
    }

    if (longBreakEvery != other.longBreakEvery) {
      return false;
    }

    return true;
  }

  @override
  int get hashCode =>
      Object.hash(workMinutes, breakMinutes, longBreakMinutes, longBreakEvery);
}

class NotificationPreference implements ValueObject {
  final bool enableDesktop;
  final bool enableMenuBar;
  final Range<DateTime> quietHours;

  NotificationPreference({
    required this.enableDesktop,
    required this.enableMenuBar,
    required this.quietHours,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! NotificationPreference) {
      return false;
    }

    if (enableDesktop != other.enableDesktop) {
      return false;
    }

    if (enableMenuBar != other.enableMenuBar) {
      return false;
    }

    if (quietHours != other.quietHours) {
      return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(enableDesktop, enableMenuBar, quietHours);
}

class UserProfile {
  final ProfileIdentifier identifier;
  final bool isDefault;
  AppearanceSettings _appearance;
  final Language language;
  final PlaybackSettings playback;
  final PomodoroPolicy pomodoro;
  final bool restoreOnLaunch;
  final NotificationPreference notification;

  UserProfile({
    required this.identifier,
    required this.isDefault,
    required AppearanceSettings appearance,
    required this.language,
    required this.playback,
    required this.pomodoro,
    required this.restoreOnLaunch,
    required this.notification,
  }) : _appearance = appearance;

  void changeCharacter(CharacterIdentifier next) {
    _appearance = _appearance.changeCharacter(next);
  }

  void changeScene(SceneIdentifier next) {
    _appearance = _appearance.changeScene(next);
  }

  void changeTheme(ThemeMode next) {
    _appearance = _appearance.changeTheme(next);
  }

  void changeOutfit(OutfitMode next) {
    _appearance = _appearance.changeOutfit(next);
  }

  AppearanceSettings get appearance => _appearance;
}

abstract interface class UserProfileRepository {
  Future<UserProfile> getDefault();
  Future<void> persist(UserProfile profile);
  Stream<UserProfile> observe(ProfileIdentifier identifier);
}

abstract class UserProfileEvent extends BaseEvent {
  UserProfileEvent({required DateTime occurredAt}) : super(occurredAt);
}

class UserProfileUpdated extends UserProfileEvent {
  final ProfileIdentifier identifier;

  UserProfileUpdated({required super.occurredAt, required this.identifier});
}

class PomodoroPolicyChanged extends UserProfileEvent {
  final ProfileIdentifier profile;
  final PomodoroPolicy policy;

  PomodoroPolicyChanged({
    required super.occurredAt,
    required this.profile,
    required this.policy,
  });
}

class PlaybackSettingsChanged extends UserProfileEvent {
  final ProfileIdentifier profile;
  final PlaybackSettings settings;

  PlaybackSettingsChanged({
    required super.occurredAt,
    required this.profile,
    required this.settings,
  });
}

class ThemeChanged extends UserProfileEvent {
  final ProfileIdentifier profile;
  final ThemeMode mode;

  ThemeChanged({
    required super.occurredAt,
    required this.profile,
    required this.mode,
  });
}

class DayPeriodChanged extends UserProfileEvent {
  final ProfileIdentifier profile;
  final DayPeriod period;

  DayPeriodChanged({
    required super.occurredAt,
    required this.profile,
    required this.period,
  });
}

class ProfileQuotaAdjusted extends UserProfileEvent {
  final ProfileIdentifier profile;
  final Map<String, Object> adjustments;

  ProfileQuotaAdjusted({
    required super.occurredAt,
    required this.profile,
    required this.adjustments,
  });
}

class CharacterLifecycleSubscriber implements EventSubscriber {
  final UserProfileRepository userProfileRepository;
  final CharacterRepository characterRepository;
  final Transaction transaction;
  final Logger logger;

  CharacterLifecycleSubscriber({
    required this.userProfileRepository,
    required this.characterRepository,
    required this.transaction,
    required this.logger,
  });

  @override
  void subscribe(EventBroker broker) {
    broker.listen<CharacterUpdated>(_onCharacterUpdated);
    broker.listen<CharacterDeprecated>(_onCharacterDeprecated(broker));
    broker.listen<CharacterUnlocked>(_onCharacterUnlocked);
  }

  void _onCharacterUpdated(CharacterUpdated event) async {
    logger.d('Character ${event.character} has been updated.');
  }

  void Function(CharacterDeprecated event) _onCharacterDeprecated(
    EventBroker broker,
  ) {
    return (CharacterDeprecated event) async {
      transaction.execute(() async {
        final profile = await userProfileRepository.getDefault();

        if (event.character != profile.appearance.character) {
          logger.i(
            'Character ${event.character} is deprecated, but not used in the default profile.',
          );
          return;
        }

        final characters = await characterRepository.search(
          CharacterSearchCriteria(statuses: {CharacterStatus.active}),
        );

        if (characters.isEmpty) {
          logger.w(
            'No active characters available to switch after deprecation of character ${event.character}.',
          );
          return;
        }

        profile.changeCharacter(characters.first.identifier);
        await userProfileRepository.persist(profile);

        broker.publish(
          UserProfileUpdated(
            occurredAt: DateTime.now(),
            identifier: profile.identifier,
          ),
        );
      });
    };
  }

  void _onCharacterUnlocked(CharacterUnlocked event) async {
    logger.d('Character ${event.character} has been unlocked.');
  }
}

class SceneLifecycleSubscriber implements EventSubscriber {
  @override
  void subscribe(EventBroker broker) {}
}

class EntitlementPolicySubscriber implements EventSubscriber {
  @override
  void subscribe(EventBroker broker) {}
}

class PomodoroSessionSubscriber implements EventSubscriber {
  @override
  void subscribe(EventBroker broker) {}
}
