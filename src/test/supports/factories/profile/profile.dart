import 'package:another_me/domains/avatar/avatar.dart';
import 'package:another_me/domains/common/locale.dart';
import 'package:another_me/domains/common/playback.dart';
import 'package:another_me/domains/common/range.dart';
import 'package:another_me/domains/common/theme.dart';
import 'package:another_me/domains/common/transaction.dart';
import 'package:another_me/domains/profile/profile.dart';
import 'package:another_me/domains/scene/scene.dart';
import 'package:logger/logger.dart';
import 'package:ulid/ulid.dart';

import '../avatar/character.dart';
import '../common.dart';
import '../common/common.dart';
import '../common/date.dart';
import '../common/identifier.dart';
import '../common/locale.dart';
import '../common/playback.dart';
import '../common/theme.dart';
import '../enum.dart';
import '../random.dart';
import '../scene/scene.dart';

class ProfileIdentifierFactory
    extends ULIDBasedIdentifierFactory<ProfileIdentifier> {
  ProfileIdentifierFactory()
    : super((Ulid value) => ProfileIdentifier(value: value));
}

class OutputDeviceIdentifierFactory
    extends ULIDBasedIdentifierFactory<OutputDeviceIdentifier> {
  OutputDeviceIdentifierFactory()
    : super((Ulid value) => OutputDeviceIdentifier(value: value));
}

class OutfitModeFactory extends EnumFactory<OutfitMode> {
  OutfitModeFactory() : super(OutfitMode.values);
}

typedef AppearanceSettingsOverrides = ({
  CharacterIdentifier? character,
  SceneIdentifier? scene,
  ThemeMode? theme,
  OutfitMode? outfitMode,
});

class AppearanceSettingsFactory
    extends Factory<AppearanceSettings, AppearanceSettingsOverrides> {
  @override
  AppearanceSettings create({
    AppearanceSettingsOverrides? overrides,
    required int seed,
  }) {
    final character =
        overrides?.character ??
        Builder(CharacterIdentifierFactory()).buildWith(seed: seed);
    final scene =
        overrides?.scene ??
        Builder(SceneIdentifierFactory()).buildWith(seed: seed);
    final theme =
        overrides?.theme ?? Builder(ThemeModeFactory()).buildWith(seed: seed);
    final outfitMode =
        overrides?.outfitMode ??
        Builder(OutfitModeFactory()).buildWith(seed: seed);

    return AppearanceSettings(
      character: character,
      scene: scene,
      theme: theme,
      outfitMode: outfitMode,
    );
  }

  @override
  AppearanceSettings duplicate(
    AppearanceSettings instance,
    AppearanceSettingsOverrides? overrides,
  ) {
    final character =
        overrides?.character ??
        Builder(
          CharacterIdentifierFactory(),
        ).duplicate(instance: instance.character, overrides: null);
    final scene =
        overrides?.scene ??
        Builder(
          SceneIdentifierFactory(),
        ).duplicate(instance: instance.scene, overrides: null);
    final theme =
        overrides?.theme ??
        Builder(
          ThemeModeFactory(),
        ).duplicate(instance: instance.theme, overrides: null);
    final outfitMode =
        overrides?.outfitMode ??
        Builder(
          OutfitModeFactory(),
        ).duplicate(instance: instance.outfitMode, overrides: null);

    return AppearanceSettings(
      character: character,
      scene: scene,
      theme: theme,
      outfitMode: outfitMode,
    );
  }
}

typedef PlaybackSettingsOverrides = ({
  LoopMode? loopMode,
  FadeDuration? fade,
  VolumeLevel? volume,
  bool? mute,
  OutputDeviceIdentifier? outputDevice,
});

class PlaybackSettingsFactory
    extends Factory<PlaybackSettings, PlaybackSettingsOverrides> {
  @override
  PlaybackSettings create({
    PlaybackSettingsOverrides? overrides,
    required int seed,
  }) {
    final loopMode =
        overrides?.loopMode ?? Builder(LoopModeFactory()).buildWith(seed: seed);
    final fade =
        overrides?.fade ?? Builder(FadeDurationFactory()).buildWith(seed: seed);
    final volume =
        overrides?.volume ??
        Builder(VolumeLevelFactory()).buildWith(seed: seed);
    final mute = overrides?.mute ?? (seed % 2 == 0);
    final outputDevice = overrides?.outputDevice;

    return PlaybackSettings(
      loopMode: loopMode,
      fade: fade,
      volume: volume,
      mute: mute,
      outputDevice: outputDevice,
    );
  }

  @override
  PlaybackSettings duplicate(
    PlaybackSettings instance,
    PlaybackSettingsOverrides? overrides,
  ) {
    final loopMode =
        overrides?.loopMode ??
        Builder(
          LoopModeFactory(),
        ).duplicate(instance: instance.loopMode, overrides: null);
    final fade =
        overrides?.fade ??
        Builder(
          FadeDurationFactory(),
        ).duplicate(instance: instance.fade, overrides: null);
    final volume =
        overrides?.volume ??
        Builder(
          VolumeLevelFactory(),
        ).duplicate(instance: instance.volume, overrides: null);
    final mute = overrides?.mute ?? instance.mute;
    final outputDevice =
        overrides?.outputDevice ??
        (instance.outputDevice != null
            ? Builder(
                OutputDeviceIdentifierFactory(),
              ).duplicate(instance: instance.outputDevice!, overrides: null)
            : null);

    return PlaybackSettings(
      loopMode: loopMode,
      fade: fade,
      volume: volume,
      mute: mute,
      outputDevice: outputDevice,
    );
  }
}

typedef PomodoroPolicyOverrides = ({
  int? workMinutes,
  int? breakMinutes,
  int? longBreakMinutes,
  int? longBreakEvery,
});

class PomodoroPolicyFactory
    extends Factory<PomodoroPolicy, PomodoroPolicyOverrides> {
  @override
  PomodoroPolicy create({
    PomodoroPolicyOverrides? overrides,
    required int seed,
  }) {
    final workMinutes = overrides?.workMinutes ?? ((seed % 120) + 1);
    final breakMinutes = overrides?.breakMinutes ?? ((seed % 30) + 1);
    final longBreakMinutes = overrides?.longBreakMinutes ?? ((seed % 60) + 1);
    final longBreakEvery = overrides?.longBreakEvery ?? ((seed % 10) + 1);

    return PomodoroPolicy(
      workMinutes: workMinutes,
      breakMinutes: breakMinutes,
      longBreakMinutes: longBreakMinutes,
      longBreakEvery: longBreakEvery,
    );
  }

  @override
  PomodoroPolicy duplicate(
    PomodoroPolicy instance,
    PomodoroPolicyOverrides? overrides,
  ) {
    final workMinutes = overrides?.workMinutes ?? instance.workMinutes;
    final breakMinutes = overrides?.breakMinutes ?? instance.breakMinutes;
    final longBreakMinutes =
        overrides?.longBreakMinutes ?? instance.longBreakMinutes;
    final longBreakEvery = overrides?.longBreakEvery ?? instance.longBreakEvery;

    return PomodoroPolicy(
      workMinutes: workMinutes,
      breakMinutes: breakMinutes,
      longBreakMinutes: longBreakMinutes,
      longBreakEvery: longBreakEvery,
    );
  }
}

typedef NotificationPreferenceOverrides = ({
  bool? enableDesktop,
  bool? enableMenuBar,
  Range<DateTime>? quietHours,
});

class NotificationPreferenceFactory
    extends Factory<NotificationPreference, NotificationPreferenceOverrides> {
  @override
  NotificationPreference create({
    NotificationPreferenceOverrides? overrides,
    required int seed,
  }) {
    final enableDesktop = overrides?.enableDesktop ?? (seed % 2 == 0);
    final enableMenuBar = overrides?.enableMenuBar ?? (seed % 3 == 0);
    final quietHours =
        overrides?.quietHours ??
        Range<DateTime>(
          start: Builder(DateTimeFactory()).buildWith(seed: seed),
          end: Builder(DateTimeFactory()).buildWith(seed: seed),
        );

    return NotificationPreference(
      enableDesktop: enableDesktop,
      enableMenuBar: enableMenuBar,
      quietHours: quietHours,
    );
  }

  @override
  NotificationPreference duplicate(
    NotificationPreference instance,
    NotificationPreferenceOverrides? overrides,
  ) {
    final enableDesktop = overrides?.enableDesktop ?? instance.enableDesktop;
    final enableMenuBar = overrides?.enableMenuBar ?? instance.enableMenuBar;
    final quietHours = overrides?.quietHours ?? instance.quietHours;

    return NotificationPreference(
      enableDesktop: enableDesktop,
      enableMenuBar: enableMenuBar,
      quietHours: quietHours,
    );
  }
}

typedef UserProfileOverrides = ({
  ProfileIdentifier? identifier,
  AppearanceSettings? appearance,
  Language? language,
  PlaybackSettings? playback,
  PomodoroPolicy? pomodoro,
  bool? restoreOnLaunch,
  NotificationPreference? notification,
  bool? isDefault,
});

class UserProfileFactory extends Factory<UserProfile, UserProfileOverrides> {
  @override
  UserProfile create({UserProfileOverrides? overrides, required int seed}) {
    final identifier =
        overrides?.identifier ??
        Builder(ProfileIdentifierFactory()).buildWith(seed: seed);
    final appearance =
        overrides?.appearance ??
        Builder(AppearanceSettingsFactory()).buildWith(seed: seed);
    final language =
        overrides?.language ?? Builder(LanguageFactory()).buildWith(seed: seed);
    final playback =
        overrides?.playback ??
        Builder(PlaybackSettingsFactory()).buildWith(seed: seed);
    final pomodoro =
        overrides?.pomodoro ??
        Builder(PomodoroPolicyFactory()).buildWith(seed: seed);
    final restoreOnLaunch = overrides?.restoreOnLaunch ?? (seed % 2 == 0);
    final notification =
        overrides?.notification ??
        Builder(NotificationPreferenceFactory()).buildWith(seed: seed);
    final isDefault = overrides?.isDefault ?? (seed % 2 == 0);

    return UserProfile(
      identifier: identifier,
      isDefault: isDefault,
      appearance: appearance,
      language: language,
      playback: playback,
      pomodoro: pomodoro,
      restoreOnLaunch: restoreOnLaunch,
      notification: notification,
    );
  }

  @override
  UserProfile duplicate(UserProfile instance, UserProfileOverrides? overrides) {
    final identifier =
        overrides?.identifier ??
        Builder(
          ProfileIdentifierFactory(),
        ).duplicate(instance: instance.identifier, overrides: null);
    final appearance =
        overrides?.appearance ??
        Builder(
          AppearanceSettingsFactory(),
        ).duplicate(instance: instance.appearance, overrides: null);
    final language =
        overrides?.language ??
        Builder(
          LanguageFactory(),
        ).duplicate(instance: instance.language, overrides: null);
    final playback =
        overrides?.playback ??
        Builder(
          PlaybackSettingsFactory(),
        ).duplicate(instance: instance.playback, overrides: null);
    final pomodoro =
        overrides?.pomodoro ??
        Builder(
          PomodoroPolicyFactory(),
        ).duplicate(instance: instance.pomodoro, overrides: null);
    final restoreOnLaunch =
        overrides?.restoreOnLaunch ?? instance.restoreOnLaunch;
    final notification =
        overrides?.notification ??
        Builder(
          NotificationPreferenceFactory(),
        ).duplicate(instance: instance.notification, overrides: null);

    final isDefault = overrides?.isDefault ?? instance.isDefault;

    return UserProfile(
      identifier: identifier,
      appearance: appearance,
      language: language,
      playback: playback,
      pomodoro: pomodoro,
      restoreOnLaunch: restoreOnLaunch,
      notification: notification,
      isDefault: isDefault,
    );
  }
}

class _UserProfileRepository implements UserProfileRepository {
  final Map<ProfileIdentifier, UserProfile> _instances;
  final void Function(UserProfile)? _onPersist;
  final Map<ProfileIdentifier, int> _versions = {};

  _UserProfileRepository({
    required List<UserProfile> instances,
    void Function(UserProfile)? onPersist,
  }) : _instances = {
         for (final instance in instances) instance.identifier: instance,
       },
       _onPersist = onPersist;

  @override
  Future<UserProfile> getDefault() {
    final target = _instances.values.firstWhere(
      (instance) => instance.isDefault,
    );

    return Future.value(target);
  }

  @override
  Future<void> persist(UserProfile profile) {
    final currentVersion = _versions[profile.identifier] ?? 0;

    _instances[profile.identifier] = profile;
    _versions[profile.identifier] = currentVersion + 1;

    _onPersist?.call(profile);

    return Future.value();
  }

  @override
  Stream<UserProfile> observe(ProfileIdentifier identifier) {
    if (!_instances.containsKey(identifier)) {
      throw ArgumentError('Profile not found: $identifier');
    }

    return Stream<UserProfile>.periodic(
      const Duration(milliseconds: 100),
      (_) => _instances[identifier]!,
    ).distinct();
  }
}

typedef UserProfileRepositoryOverrides = ({
  List<UserProfile>? instances,
  void Function(UserProfile)? onPersist,
});

class UserProfileRepositoryFactory
    extends Factory<UserProfileRepository, UserProfileRepositoryOverrides> {
  @override
  UserProfileRepository create({
    UserProfileRepositoryOverrides? overrides,
    required int seed,
  }) {
    final seeds = Randomizer.uniqueNumbers(count: 5).toSet();

    final defaultProfile =
        overrides?.instances?.firstWhere((instance) => instance.isDefault) ??
        Builder(UserProfileFactory()).buildWith(
          seed: seed,
          overrides: (
            isDefault: true,
            identifier: null,
            appearance: null,
            language: null,
            playback: null,
            pomodoro: null,
            restoreOnLaunch: null,
            notification: null,
          ),
        );

    if (seeds.contains(seed)) {
      seeds.remove(seed);
    }

    final instances = seeds
        .map((int seed) => Builder(UserProfileFactory()).buildWith(seed: seed))
        .toList();
    instances.add(defaultProfile);

    final onPersist = overrides?.onPersist;

    return _UserProfileRepository(instances: instances, onPersist: onPersist);
  }

  @override
  UserProfileRepository duplicate(
    UserProfileRepository instance,
    UserProfileRepositoryOverrides? overrides,
  ) {
    throw UnimplementedError();
  }
}

typedef CharacterLifecycleSubscriberOverrides = ({
  UserProfileRepository? userProfileRepository,
  CharacterRepository? characterRepository,
  Transaction? transaction,
});

class CharacterLifecycleSubscriberFactory
    extends
        Factory<
          CharacterLifecycleSubscriber,
          CharacterLifecycleSubscriberOverrides
        > {
  @override
  CharacterLifecycleSubscriber create({
    CharacterLifecycleSubscriberOverrides? overrides,
    required int seed,
  }) {
    final userProfileRepository =
        overrides?.userProfileRepository ??
        Builder(UserProfileRepositoryFactory()).buildWith(seed: seed);
    final characterRepository =
        overrides?.characterRepository ??
        Builder(CharacterRepositoryFactory()).buildWith(seed: seed);
    final transaction =
        overrides?.transaction ??
        Builder(TransactionFactory()).buildWith(seed: seed);

    return CharacterLifecycleSubscriber(
      userProfileRepository: userProfileRepository,
      characterRepository: characterRepository,
      transaction: transaction,
      logger: Logger(),
    );
  }

  @override
  CharacterLifecycleSubscriber duplicate(
    CharacterLifecycleSubscriber instance,
    CharacterLifecycleSubscriberOverrides? overrides,
  ) {
    throw UnimplementedError();
  }
}
