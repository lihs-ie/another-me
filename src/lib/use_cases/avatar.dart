import 'package:another_me/domains/avatar.dart' as avatar_domain;
import 'package:another_me/domains/billing/billing.dart' as billing_domain;
import 'package:another_me/domains/common.dart' as common_domain;
import 'package:another_me/domains/media/media.dart' as media_domain;
import 'package:another_me/domains/profile/profile.dart' as profile_domain;
import 'package:another_me/domains/scene/scene.dart' as scene_domain;

class CharacterCustomization {
  final avatar_domain.CharacterRepository _characterRepository;
  final scene_domain.SceneRepository _sceneRepository;
  final profile_domain.UserProfileRepository _userProfileRepository;
  final billing_domain.EntitlementService _entitlementService;
  final common_domain.Transaction _transaction;

  CharacterCustomization({
    required avatar_domain.CharacterRepository characterRepository,
    required scene_domain.SceneRepository sceneRepository,
    required profile_domain.UserProfileRepository userProfileRepository,
    required billing_domain.EntitlementService entitlementService,
    required common_domain.Transaction transaction,
  }) : _characterRepository = characterRepository,
       _sceneRepository = sceneRepository,
       _userProfileRepository = userProfileRepository,
       _entitlementService = entitlementService,
       _transaction = transaction;

  Future<void> selectCharacter({
    required avatar_domain.CharacterIdentifier characterIdentifier,
    required profile_domain.ProfileIdentifier profile,
  }) async {
    return await _transaction.execute(() async {
      final character = await _characterRepository.find(characterIdentifier);

      if (character.status != avatar_domain.CharacterStatus.active) {
        throw common_domain.InvariantViolationError(
          'Cannot select deprecated or locked character: ${characterIdentifier.value}',
        );
      }

      final currentCount = 1;

      final canUse = await _entitlementService.canUseCharacter(currentCount);

      if (!canUse) {
        throw media_domain.EntitlementLimitExceededError(
          'Character usage limit exceeded',
        );
      }

      final userProfile = await _userProfileRepository.find(profile);

      userProfile.changeCharacter(characterIdentifier);

      await _userProfileRepository.persist(userProfile);
    });
  }

  Future<void> selectScene({
    required scene_domain.SceneIdentifier sceneIdentifier,
    required profile_domain.ProfileIdentifier profile,
  }) async {
    return await _transaction.execute(() async {
      final scene = await _sceneRepository.find(sceneIdentifier);

      if (scene.status != scene_domain.SceneStatus.active) {
        throw StateError(
          'Cannot select deprecated scene: ${sceneIdentifier.value}',
        );
      }

      final userProfile = await _userProfileRepository.find(profile);

      userProfile.changeScene(sceneIdentifier);

      await _userProfileRepository.persist(userProfile);
    });
  }

  Future<void> changeOutfitMode({
    required avatar_domain.OutfitMode outfitMode,
    required profile_domain.ProfileIdentifier profile,
  }) async {
    return await _transaction.execute(() async {
      final userProfile = await _userProfileRepository.find(profile);

      userProfile.changeOutfit(outfitMode);

      await _userProfileRepository.persist(userProfile);
    });
  }
}
