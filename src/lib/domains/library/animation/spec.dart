import 'package:another_me/domains/common/event.dart';
import 'package:another_me/domains/common/frame_rate.dart';
import 'package:another_me/domains/common/value_object.dart';
import 'package:another_me/domains/common/variant.dart';
import 'package:another_me/domains/library/asset.dart';
import 'package:another_me/domains/library/animation/common.dart';

class AnimationSpecIdentifier implements ValueObject {
  final String name;

  AnimationSpecIdentifier({required this.name}) {
    Invariant.length(value: name, name: 'name', min: 1, max: 100);

    if (!_isValidFormat(name)) {
      throw InvariantViolationError(
        'name must match pattern: lowercase letters, numbers, underscores',
      );
    }
  }

  bool _isValidFormat(String name) {
    return RegExp(r'^[a-z_][a-z0-9_]*$').hasMatch(name);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! AnimationSpecIdentifier) {
      return false;
    }

    return name == other.name;
  }

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => name;
}

abstract class AnimationSpecEvent extends BaseEvent {
  AnimationSpecEvent(super.occurredAt);
}

class AnimationSpecRegistered extends AnimationSpecEvent {
  final AnimationSpecIdentifier animationSpec;
  final FramesPerSecond fps;
  final int frames;

  AnimationSpecRegistered({
    required DateTime occurredAt,
    required this.animationSpec,
    required this.fps,
    required this.frames,
  }) : super(occurredAt);
}

class AnimationSpecDeprecated extends AnimationSpecEvent {
  final AnimationSpecIdentifier animationSpec;
  final String reason;

  AnimationSpecDeprecated({
    required DateTime occurredAt,
    required this.animationSpec,
    required this.reason,
  }) : super(occurredAt);
}

class AnimationSpec with Publishable<AnimationSpecEvent> {
  final AnimationSpecIdentifier identifier;
  final FramesPerSecond fps;
  final int frames;
  final String next;
  final Pivot pivot;
  final List<Hitbox> hitboxes;
  final int safetyMargin;

  AnimationSpec({
    required this.identifier,
    required this.fps,
    required this.frames,
    required this.next,
    required this.pivot,
    required this.hitboxes,
    required this.safetyMargin,
  }) {
    Invariant.range(value: safetyMargin, name: 'safetyMargin', min: 8);
    Invariant.range(value: frames, name: 'frames', min: 1);

    if (frames % fps.value != 0) {
      throw InvariantViolationError(
        'frames must be a multiple of fps (${fps.value})',
      );
    }
  }

  String get name => identifier.name;

  void register() {
    publish(
      AnimationSpecRegistered(
        occurredAt: DateTime.now(),
        animationSpec: identifier,
        fps: fps,
        frames: frames,
      ),
    );
  }

  void deprecate(String reason) {
    publish(
      AnimationSpecDeprecated(
        occurredAt: DateTime.now(),
        animationSpec: identifier,
        reason: reason,
      ),
    );
  }
}

abstract interface class AnimationSpecRepository {
  Future<AnimationSpec> find(AnimationSpecIdentifier identifier);
  Future<void> persist(AnimationSpec spec);
  Future<List<AnimationSpec>> all();
}

class ValidationResult {
  final bool isValid;
  final String? reason;

  const ValidationResult.valid() : isValid = true, reason = null;

  const ValidationResult.invalid(this.reason) : isValid = false;
}

abstract interface class AssetValidator {
  Future<ValidationResult> validate(AssetPackage package, AnimationSpec spec);
  Future<ValidationResult> validateAll(
    List<AssetPackage> packages,
    AnimationSpec spec,
  );
}

class SpecComplianceSubscriber implements EventSubscriber {
  final AnimationSpecRepository _animationSpecRepository;
  final AssetCatalogRepository _assetCatalogRepository;
  final AssetValidator _assetValidator;

  SpecComplianceSubscriber({
    required AnimationSpecRepository animationSpecRepository,
    required AssetCatalogRepository assetCatalogRepository,
    required AssetValidator assetValidator,
  }) : _animationSpecRepository = animationSpecRepository,
       _assetCatalogRepository = assetCatalogRepository,
       _assetValidator = assetValidator;

  @override
  void subscribe(EventBroker broker) {
    broker.listen<AnimationSpecRegistered>(_onAnimationSpecRegistered(broker));
  }

  void Function(AnimationSpecRegistered event) _onAnimationSpecRegistered(
    EventBroker broker,
  ) {
    return (AnimationSpecRegistered event) async {
      final spec = await _animationSpecRepository.find(event.animationSpec);
      final catalog = await _assetCatalogRepository.findLatest();
      final targetPackages = catalog.packages
          .where(
            (package) =>
                package.animationSpecVersion == event.animationSpec.name,
          )
          .toList();

      if (targetPackages.isEmpty) {
        return;
      }

      final result = await _assetValidator.validateAll(targetPackages, spec);

      if (!result.isValid) {
        catalog.deprecate(
          'AnimationSpec "${event.animationSpec.name}" has issues: ${result.reason}',
        );

        broker.publishAll(catalog.events());

        await _assetCatalogRepository.persist(catalog);

        broker.deliver();
      }
    };
  }
}
