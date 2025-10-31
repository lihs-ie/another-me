import 'package:another_me/domains/avatar.dart' as avatar_domain;
import 'package:another_me/domains/common/error.dart';
import 'package:another_me/domains/common/variant.dart';
import 'package:another_me/domains/media/media.dart' as media_domain;
import 'package:another_me/domains/scene/scene.dart' as scene_domain;
import 'package:another_me/use_cases/avatar.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../supports/factories/avatar/character.dart' as character_factory;
import '../../supports/factories/billing/billing.dart' as billing_factory;
import '../../supports/factories/common.dart';
import '../../supports/factories/common/transaction.dart'
    as transaction_factory;
import '../../supports/factories/profile/profile.dart' as profile_factory;
import '../../supports/factories/scene/scene.dart' as scene_factory;

void main() {
  group('CharacterCustomization', () {
    group('selectCharacter', () {
      test('selects active character successfully.', () async {
        final characterIdentifier = Builder(
          character_factory.CharacterIdentifierFactory(),
        ).build();

        final profileIdentifier = Builder(
          profile_factory.ProfileIdentifierFactory(),
        ).build();

        final character = Builder(character_factory.CharacterFactory()).build(
          overrides: (
            identifier: characterIdentifier,
            displayName: null,
            bindings: null,
            wardrobes: null,
            palette: null,
            status: avatar_domain.CharacterStatus.active,
          ),
        );

        final userProfile = Builder(profile_factory.UserProfileFactory()).build(
          overrides: (
            identifier: profileIdentifier,
            isDefault: true,
            appearance: null,
            language: null,
            playback: null,
            pomodoro: null,
            restoreOnLaunch: null,
            notification: null,
          ),
        );

        var persistCallCount = 0;

        final characterRepository = Builder(
          character_factory.CharacterRepositoryFactory(),
        ).build(overrides: (instances: [character], onPersist: null));

        final userProfileRepository =
            Builder(profile_factory.UserProfileRepositoryFactory()).build(
              overrides: (
                instances: [userProfile],
                onPersist: (_) {
                  persistCallCount++;
                },
              ),
            );

        final entitlementService =
            Builder(billing_factory.EntitlementServiceFactory()).build(
              overrides: (
                canAddTrack: null,
                trackLimit: null,
                canUseCharacter: (_) => Future.value(true),
                characterLimit: 10,
              ),
            );

        final useCase = CharacterCustomization(
          characterRepository: characterRepository,
          sceneRepository: Builder(
            scene_factory.SceneRepositoryFactory(),
          ).buildWith(seed: 1),
          userProfileRepository: userProfileRepository,
          entitlementService: entitlementService,
          transaction: Builder(
            transaction_factory.TransactionFactory(),
          ).build(),
        );

        await useCase.selectCharacter(
          characterIdentifier: characterIdentifier,
          profile: profileIdentifier,
        );

        expect(persistCallCount, equals(1));
        expect(userProfile.appearance.character, equals(characterIdentifier));
      });

      test(
        'throws InvariantViolationError when character is deprecated.',
        () async {
          final characterIdentifier = Builder(
            character_factory.CharacterIdentifierFactory(),
          ).build();

          final profileIdentifier = Builder(
            profile_factory.ProfileIdentifierFactory(),
          ).build();

          final character = Builder(character_factory.CharacterFactory())
              .buildWith(
                seed: 1,
                overrides: (
                  identifier: characterIdentifier,
                  displayName: null,
                  bindings: null,
                  wardrobes: null,
                  palette: null,
                  status: avatar_domain.CharacterStatus.deprecated,
                ),
              );

          final userProfile = Builder(profile_factory.UserProfileFactory())
              .buildWith(
                seed: 1,
                overrides: (
                  identifier: profileIdentifier,
                  isDefault: true,
                  appearance: null,
                  language: null,
                  playback: null,
                  pomodoro: null,
                  restoreOnLaunch: null,
                  notification: null,
                ),
              );

          final characterRepository =
              Builder(character_factory.CharacterRepositoryFactory()).buildWith(
                seed: 1,
                overrides: (instances: [character], onPersist: null),
              );

          final userProfileRepository =
              Builder(profile_factory.UserProfileRepositoryFactory()).buildWith(
                seed: 1,
                overrides: (instances: [userProfile], onPersist: null),
              );

          final useCase = CharacterCustomization(
            characterRepository: characterRepository,
            sceneRepository: Builder(
              scene_factory.SceneRepositoryFactory(),
            ).buildWith(seed: 1),
            userProfileRepository: userProfileRepository,
            entitlementService: Builder(
              billing_factory.EntitlementServiceFactory(),
            ).buildWith(seed: 1),
            transaction: Builder(
              transaction_factory.TransactionFactory(),
            ).build(),
          );

          expect(
            () async => await useCase.selectCharacter(
              characterIdentifier: characterIdentifier,
              profile: profileIdentifier,
            ),
            throwsA(isA<InvariantViolationError>()),
          );
        },
      );

      test(
        'throws EntitlementLimitExceededError when limit reached.',
        () async {
          final characterIdentifier = Builder(
            character_factory.CharacterIdentifierFactory(),
          ).build();

          final profileIdentifier = Builder(
            profile_factory.ProfileIdentifierFactory(),
          ).build();

          final character = Builder(character_factory.CharacterFactory())
              .buildWith(
                seed: 1,
                overrides: (
                  identifier: characterIdentifier,
                  displayName: null,
                  bindings: null,
                  wardrobes: null,
                  palette: null,
                  status: avatar_domain.CharacterStatus.active,
                ),
              );

          final userProfile = Builder(profile_factory.UserProfileFactory())
              .buildWith(
                seed: 1,
                overrides: (
                  identifier: profileIdentifier,
                  isDefault: true,
                  appearance: null,
                  language: null,
                  playback: null,
                  pomodoro: null,
                  restoreOnLaunch: null,
                  notification: null,
                ),
              );

          final characterRepository =
              Builder(character_factory.CharacterRepositoryFactory()).buildWith(
                seed: 1,
                overrides: (instances: [character], onPersist: null),
              );

          final userProfileRepository =
              Builder(profile_factory.UserProfileRepositoryFactory()).buildWith(
                seed: 1,
                overrides: (instances: [userProfile], onPersist: null),
              );

          final entitlementService =
              Builder(billing_factory.EntitlementServiceFactory()).buildWith(
                seed: 1,
                overrides: (
                  canAddTrack: null,
                  trackLimit: null,
                  canUseCharacter: (_) => Future.value(false),
                  characterLimit: 0,
                ),
              );

          final useCase = CharacterCustomization(
            characterRepository: characterRepository,
            sceneRepository: Builder(
              scene_factory.SceneRepositoryFactory(),
            ).buildWith(seed: 1),
            userProfileRepository: userProfileRepository,
            entitlementService: entitlementService,
            transaction: Builder(
              transaction_factory.TransactionFactory(),
            ).build(),
          );

          expect(
            () async => await useCase.selectCharacter(
              characterIdentifier: characterIdentifier,
              profile: profileIdentifier,
            ),
            throwsA(isA<media_domain.EntitlementLimitExceededError>()),
          );
        },
      );

      test('throws AggregateNotFoundError when character not found.', () async {
        final characterIdentifier = Builder(
          character_factory.CharacterIdentifierFactory(),
        ).build();

        final profileIdentifier = Builder(
          profile_factory.ProfileIdentifierFactory(),
        ).build();

        final characterRepository = Builder(
          character_factory.CharacterRepositoryFactory(),
        ).buildWith(seed: 1, overrides: (instances: [], onPersist: null));

        final userProfileRepository = Builder(
          profile_factory.UserProfileRepositoryFactory(),
        ).buildWith(seed: 1, overrides: (instances: null, onPersist: null));

        final useCase = CharacterCustomization(
          characterRepository: characterRepository,
          sceneRepository: Builder(
            scene_factory.SceneRepositoryFactory(),
          ).buildWith(seed: 1),
          userProfileRepository: userProfileRepository,
          entitlementService: Builder(
            billing_factory.EntitlementServiceFactory(),
          ).buildWith(seed: 1),
          transaction: Builder(
            transaction_factory.TransactionFactory(),
          ).build(),
        );

        expect(
          () async => await useCase.selectCharacter(
            characterIdentifier: characterIdentifier,
            profile: profileIdentifier,
          ),
          throwsA(isA<AggregateNotFoundError>()),
        );
      });
    });

    group('selectScene', () {
      test('selects active scene successfully.', () async {
        final sceneIdentifier = Builder(
          scene_factory.SceneIdentifierFactory(),
        ).build();

        final profileIdentifier = Builder(
          profile_factory.ProfileIdentifierFactory(),
        ).build();

        final sceneAnimationBinding = Builder(
          scene_factory.SceneAnimationBindingFactory(),
        ).buildWith(seed: 1);
        final characterAnchor = Builder(
          scene_factory.SceneAnchorFactory(),
        ).buildWith(seed: 1);
        final lightingProfile = Builder(
          scene_factory.LightingProfileFactory(),
        ).buildWith(seed: 1);

        final scene = scene_domain.Scene(
          identifier: sceneIdentifier,
          name: 'Test Scene',
          type: scene_domain.SceneType.room,
          animationBinding: sceneAnimationBinding,
          parallaxLayers: [],
          characterAnchor: characterAnchor,
          effects: {},
          lightingProfile: lightingProfile,
          status: scene_domain.SceneStatus.active,
        );

        final userProfile = Builder(profile_factory.UserProfileFactory()).build(
          overrides: (
            identifier: profileIdentifier,
            isDefault: true,
            appearance: null,
            language: null,
            playback: null,
            pomodoro: null,
            restoreOnLaunch: null,
            notification: null,
          ),
        );

        var persistCallCount = 0;

        final sceneRepository = Builder(
          scene_factory.SceneRepositoryFactory(),
        ).buildWith(seed: 1, overrides: (instances: [scene], onPersist: null));

        final userProfileRepository =
            Builder(profile_factory.UserProfileRepositoryFactory()).build(
              overrides: (
                instances: [userProfile],
                onPersist: (_) {
                  persistCallCount++;
                },
              ),
            );

        final useCase = CharacterCustomization(
          characterRepository: Builder(
            character_factory.CharacterRepositoryFactory(),
          ).buildWith(seed: 1),
          sceneRepository: sceneRepository,
          userProfileRepository: userProfileRepository,
          entitlementService: Builder(
            billing_factory.EntitlementServiceFactory(),
          ).buildWith(seed: 1),
          transaction: Builder(
            transaction_factory.TransactionFactory(),
          ).build(),
        );

        await useCase.selectScene(
          sceneIdentifier: sceneIdentifier,
          profile: profileIdentifier,
        );

        expect(persistCallCount, equals(1));
        expect(userProfile.appearance.scene, equals(sceneIdentifier));
      });

      test(
        'throws InvariantViolationError when scene is deprecated.',
        () async {
          final sceneIdentifier = Builder(
            scene_factory.SceneIdentifierFactory(),
          ).build();

          final profileIdentifier = Builder(
            profile_factory.ProfileIdentifierFactory(),
          ).build();

          final sceneAnimationBinding = Builder(
            scene_factory.SceneAnimationBindingFactory(),
          ).buildWith(seed: 1);
          final characterAnchor = Builder(
            scene_factory.SceneAnchorFactory(),
          ).buildWith(seed: 1);
          final lightingProfile = Builder(
            scene_factory.LightingProfileFactory(),
          ).buildWith(seed: 1);

          final scene = scene_domain.Scene(
            identifier: sceneIdentifier,
            name: 'Deprecated Scene',
            type: scene_domain.SceneType.room,
            animationBinding: sceneAnimationBinding,
            parallaxLayers: [],
            characterAnchor: characterAnchor,
            effects: {},
            lightingProfile: lightingProfile,
            status: scene_domain.SceneStatus.deprecated,
          );

          final userProfile = Builder(profile_factory.UserProfileFactory())
              .buildWith(
                seed: 1,
                overrides: (
                  identifier: profileIdentifier,
                  isDefault: true,
                  appearance: null,
                  language: null,
                  playback: null,
                  pomodoro: null,
                  restoreOnLaunch: null,
                  notification: null,
                ),
              );

          final sceneRepository =
              Builder(scene_factory.SceneRepositoryFactory()).buildWith(
                seed: 1,
                overrides: (instances: [scene], onPersist: null),
              );

          final userProfileRepository =
              Builder(profile_factory.UserProfileRepositoryFactory()).buildWith(
                seed: 1,
                overrides: (instances: [userProfile], onPersist: null),
              );

          final useCase = CharacterCustomization(
            characterRepository: Builder(
              character_factory.CharacterRepositoryFactory(),
            ).buildWith(seed: 1),
            sceneRepository: sceneRepository,
            userProfileRepository: userProfileRepository,
            entitlementService: Builder(
              billing_factory.EntitlementServiceFactory(),
            ).buildWith(seed: 1),
            transaction: Builder(
              transaction_factory.TransactionFactory(),
            ).build(),
          );

          expect(
            () async => await useCase.selectScene(
              sceneIdentifier: sceneIdentifier,
              profile: profileIdentifier,
            ),
            throwsA(isA<StateError>()),
          );
        },
      );

      test('throws AggregateNotFoundError when scene not found.', () async {
        final sceneIdentifier = Builder(
          scene_factory.SceneIdentifierFactory(),
        ).build();

        final profileIdentifier = Builder(
          profile_factory.ProfileIdentifierFactory(),
        ).build();

        final sceneRepository = Builder(
          scene_factory.SceneRepositoryFactory(),
        ).buildWith(seed: 1, overrides: (instances: [], onPersist: null));

        final userProfileRepository = Builder(
          profile_factory.UserProfileRepositoryFactory(),
        ).buildWith(seed: 1, overrides: (instances: null, onPersist: null));

        final useCase = CharacterCustomization(
          characterRepository: Builder(
            character_factory.CharacterRepositoryFactory(),
          ).buildWith(seed: 1),
          sceneRepository: sceneRepository,
          userProfileRepository: userProfileRepository,
          entitlementService: Builder(
            billing_factory.EntitlementServiceFactory(),
          ).buildWith(seed: 1),
          transaction: Builder(
            transaction_factory.TransactionFactory(),
          ).build(),
        );

        expect(
          () async => await useCase.selectScene(
            sceneIdentifier: sceneIdentifier,
            profile: profileIdentifier,
          ),
          throwsA(isA<AggregateNotFoundError>()),
        );
      });
    });

    group('changeOutfitMode', () {
      test('changes outfit mode successfully.', () async {
        final profileIdentifier = Builder(
          profile_factory.ProfileIdentifierFactory(),
        ).build();

        final userProfile = Builder(profile_factory.UserProfileFactory()).build(
          overrides: (
            identifier: profileIdentifier,
            isDefault: true,
            appearance: null,
            language: null,
            playback: null,
            pomodoro: null,
            restoreOnLaunch: null,
            notification: null,
          ),
        );

        var persistCallCount = 0;

        final userProfileRepository =
            Builder(profile_factory.UserProfileRepositoryFactory()).build(
              overrides: (
                instances: [userProfile],
                onPersist: (_) {
                  persistCallCount++;
                },
              ),
            );

        final useCase = CharacterCustomization(
          characterRepository: Builder(
            character_factory.CharacterRepositoryFactory(),
          ).buildWith(seed: 1),
          sceneRepository: Builder(
            scene_factory.SceneRepositoryFactory(),
          ).buildWith(seed: 1),
          userProfileRepository: userProfileRepository,
          entitlementService: Builder(
            billing_factory.EntitlementServiceFactory(),
          ).buildWith(seed: 1),
          transaction: Builder(
            transaction_factory.TransactionFactory(),
          ).build(),
        );

        await useCase.changeOutfitMode(
          outfitMode: avatar_domain.OutfitMode.manual,
          profile: profileIdentifier,
        );

        expect(persistCallCount, equals(1));
        expect(
          userProfile.appearance.outfitMode,
          equals(avatar_domain.OutfitMode.manual),
        );
      });

      test('throws AggregateNotFoundError when profile not found.', () async {
        final profileIdentifier = Builder(
          profile_factory.ProfileIdentifierFactory(),
        ).build();

        final userProfileRepository = Builder(
          profile_factory.UserProfileRepositoryFactory(),
        ).buildWith(seed: 1, overrides: (instances: null, onPersist: null));

        final useCase = CharacterCustomization(
          characterRepository: Builder(
            character_factory.CharacterRepositoryFactory(),
          ).buildWith(seed: 1),
          sceneRepository: Builder(
            scene_factory.SceneRepositoryFactory(),
          ).buildWith(seed: 1),
          userProfileRepository: userProfileRepository,
          entitlementService: Builder(
            billing_factory.EntitlementServiceFactory(),
          ).buildWith(seed: 1),
          transaction: Builder(
            transaction_factory.TransactionFactory(),
          ).build(),
        );

        expect(
          () async => await useCase.changeOutfitMode(
            outfitMode: avatar_domain.OutfitMode.auto,
            profile: profileIdentifier,
          ),
          throwsA(isA<AggregateNotFoundError>()),
        );
      });
    });
  });
}
