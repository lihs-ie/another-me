# library パッケージ（AssetCatalog / AnimationSpec）

## 永続化戦略

| データ             | ストア                 | 保存形式                                        |
|--------------------|------------------------|-------------------------------------------------|
| AssetCatalog        | JSON (`catalog.json`)  | 公式カタログをまるごと保持                     |
| AnimationSpec       | JSON (`animation_spec.json`) | AssetCatalog とは別にキャッシュ（任意）|
| ダウンロード済みパッケージ | Firebase Storage / ローカルFS | `assets/{packageIdentifier}/...` |

- catalog.json は library パッケージの同期処理で取得し、アプリ固有ディレクトリに保存。
- ビジュアル/オーディオ問わず同一バージョンの AssetCatalog を扱う。

## catalog.json の構造（例）

```json
{
  "catalogIdentifier": "official-v1.2.0",
  "version": "1.2.0",
  "publishedAt": "2025-10-22T10:00:00Z",
  "packages": [
    {
      "packageIdentifier": "char_a",
      "type": "Character",
      "files": [{"path": "characters/char_a/atlas.png", "sizeBytes": 1234567}],
      "checksum": "sha256:abcd...",
      "animationSpecVersion": "1.0"
    },
    {
      "packageIdentifier": "track_lofi_001",
      "type": "Track",
      "files": [{"path": "tracks/track_lofi_001.m4a", "sizeBytes": 4321987}],
      "checksum": "sha256:efgh...",
      "trackCatalogMetadata": {
        "trackIdentifier": "lofi_chill_piano_001",
        "title": "Rainy Day Study",
        "artist": "Lo-Fi Artist",
        "durationMs": 180000,
        "audioFormat": "aac",
        "downloadUrl": "https://firebasestorage.googleapis.com/...",
        "audioChecksum": "sha256:xxx...",
        "licenseMetadata": {
          "licenseName": "CC BY 4.0",
          "licenseUrl": "https://creativecommons.org/licenses/by/4.0/",
          "attributionText": "Rainy Day Study by Lo-Fi Artist",
          "allowOffline": true,
          "licenseFileChecksum": "sha256:yyy..."
        }
      }
    }
  ]
}
```

## リポジトリ実装

- `AssetCatalogRepository`
  - `latest()` → catalog.json を読み込み、`version` を返す。
  - `find(catalogIdentifier)` → catalog.json が複数世代ある場合に参照。
  - `persist(catalog)` → 同期成功時に JSON を上書き。

- `AnimationSpecRepository`
  - ごく少数であれば catalog.json からインライン読み込みでも可。パフォーマンス次第で別 JSON にキャッシュ。

## Firebase Storage ACL

- `FirebaseStorageClient`
  - `downloadPackage(packageIdentifier, files, checksum)`
  - キャッシュディレクトリ：`assets/{packageIdentifier}/...`
  - チェックサム検証後に展開。

- `TrackCatalogUpdated` イベントを発火し、楽曲差分を media / licensing に通知。

## 追加メモ

- カタログ同期処理は UC14（Catalog Sync）で定義。HTTPS（TLS）経由で catalog.json を取得し、バージョン差分を確認。
- 将来、楽曲カタログを分離する際は trackCatalogMetadata セクションを MusicCatalog に移せば良いように設計。

## トランザクション境界 / バージョン管理

- catalog.json は整合性を保つため、一時ファイルへダウンロード→チェックサム検証→置き換えの順に実施。
- バージョン差分を算出し、`TrackCatalogUpdated` では追加/削除/更新のリストを一括通知。
- 将来的に MusicCatalog を分離する場合でも、同一の差分ロジックを流用できるよう `TrackCatalogMetadata` を独立した値オブジェクトとして保持。

## マイグレーション

- catalog.json のスキーマ変更時は `catalog_version` フィールドを追加し、複数世代を保持しつつ移行処理を実装する。

## AssetValidator（アセット検証サービス）

### 目的

AnimationSpec と AssetPackage の整合性を検証するためのドメインサービス。
JSON アトラスのパース、PNG メタデータの読み取りなど、I/O を伴う処理をインフラ層で実装する。

### 契約（ドメイン層で定義）

```dart
/// AssetPackage の検証結果
class ValidationResult {
  final bool isValid;
  final String? reason;

  const ValidationResult.valid()
      : isValid = true,
        reason = null;

  const ValidationResult.invalid(this.reason) : isValid = false;
}

abstract interface class AssetValidator {
  /// AnimationSpec に対して単一の AssetPackage を検証
  ///
  /// 以下の項目を検証：
  /// - JSON アトラスの fps が AnimationSpec.fps と一致するか
  /// - JSON アトラスの総フレーム数が AnimationSpec.frames と一致するか
  /// - JSON アトラスの pivot 座標が AnimationSpec.pivot と一致するか
  /// - PNG 画像の余白が AnimationSpec.safetyMargin 以上確保されているか
  Future<ValidationResult> validate(
    AssetPackage package,
    AnimationSpec spec,
  );

  /// AnimationSpec に対して複数の AssetPackage を検証
  ///
  /// いずれかのパッケージで不整合が見つかった時点で失敗を返す（fail-fast）
  Future<ValidationResult> validateAll(
    List<AssetPackage> packages,
    AnimationSpec spec,
  );
}
```

### 実装戦略（インフラ層）

#### 検証メソッドの実装

```dart
class AssetValidatorImpl implements AssetValidator {
  final FileSystem _fileSystem;

  AssetValidatorImpl({required FileSystem fileSystem})
    : _fileSystem = fileSystem;

  @override
  Future<ValidationResult> validate(
    AssetPackage package,
    AnimationSpec spec,
  ) async {
    try {
      // 1. FPS の検証
      final packageFps = await _extractFps(package);
      if (packageFps != spec.fps) {
        return ValidationResult.invalid(
          'FPS 不一致: 期待値=${spec.fps.value}, 実際値=${packageFps.value}',
        );
      }

      // 2. フレーム数の検証
      final packageFrames = await _extractFrameCount(package);
      if (packageFrames != spec.frames) {
        return ValidationResult.invalid(
          'フレーム数不一致: 期待値=${spec.frames}, 実際値=$packageFrames',
        );
      }

      // 3. ピボット座標の検証
      final packagePivot = await _extractPivot(package);
      if (packagePivot != spec.pivot) {
        return ValidationResult.invalid(
          'ピボット不一致: 期待値=(${spec.pivot.x}, ${spec.pivot.y}), 実際値=(${packagePivot.x}, ${packagePivot.y})',
        );
      }

      // 4. 余白の検証
      final packageMargin = await _extractSafetyMargin(package);
      if (packageMargin < spec.safetyMargin) {
        return ValidationResult.invalid(
          '余白不足: 期待値=${spec.safetyMargin}px以上, 実際値=${packageMargin}px',
        );
      }

      return const ValidationResult.valid();
    } catch (e) {
      return ValidationResult.invalid('検証中にエラーが発生: $e');
    }
  }

  @override
  Future<ValidationResult> validateAll(
    List<AssetPackage> packages,
    AnimationSpec spec,
  ) async {
    for (final package in packages) {
      final result = await validate(package, spec);
      if (!result.isValid) {
        return result; // fail-fast: 最初の不整合で終了
      }
    }
    return const ValidationResult.valid();
  }

  // プライベートヘルパーメソッド

  Future<FramesPerSecond> _extractFps(AssetPackage package) async {
    final jsonFile = _findJsonFile(package);
    final json = await _readJsonFile(jsonFile);
    final fps = json['meta']['fps'] as int;
    return FramesPerSecond.fromValue(fps);
  }

  Future<int> _extractFrameCount(AssetPackage package) async {
    final jsonFile = _findJsonFile(package);
    final json = await _readJsonFile(jsonFile);
    final frames = json['meta']['frames'] as int?
        ?? (json['frames'] as List).length;
    return frames;
  }

  Future<Pivot> _extractPivot(AssetPackage package) async {
    final jsonFile = _findJsonFile(package);
    final json = await _readJsonFile(jsonFile);
    final pivotData = json['meta']['pivot'] as Map<String, dynamic>;
    final x = pivotData['x'] as int;
    final y = pivotData['y'] as int;
    final gridSize = GridSize(value: pivotData['gridSize'] as int);
    return Pivot(x: x, y: y, gridSize: gridSize);
  }

  Future<int> _extractSafetyMargin(AssetPackage package) async {
    final pngFile = _findPngFile(package);
    final image = await _decodePngImage(pngFile);

    final topMargin = _scanTopMargin(image);
    final bottomMargin = _scanBottomMargin(image);
    final leftMargin = _scanLeftMargin(image);
    final rightMargin = _scanRightMargin(image);

    return [topMargin, bottomMargin, leftMargin, rightMargin].reduce(min);
  }

  FileResource _findJsonFile(AssetPackage package) {
    return package.resources.firstWhere(
      (resource) => resource.path.value.endsWith('.json'),
      orElse: () => throw StateError('JSON ファイルが見つかりません'),
    );
  }

  FileResource _findPngFile(AssetPackage package) {
    return package.resources.firstWhere(
      (resource) => resource.path.value.endsWith('.png'),
      orElse: () => throw StateError('PNG ファイルが見つかりません'),
    );
  }

  Future<Map<String, dynamic>> _readJsonFile(FileResource file) async {
    final content = await _fileSystem.file(file.path.value).readAsString();
    return jsonDecode(content) as Map<String, dynamic>;
  }

  Future<Image> _decodePngImage(FileResource file) async {
    final bytes = await _fileSystem.file(file.path.value).readAsBytes();
    return decodeImage(bytes)!;
  }

  int _scanTopMargin(Image image) {
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        if (pixel.a > 0) return y;
      }
    }
    return image.height;
  }

  // _scanBottomMargin, _scanLeftMargin, _scanRightMargin も同様に実装
}
```

#### JSON アトラスの構造例

```json
{
  "meta": {
    "fps": 30,
    "frames": 96,
    "pivot": {"x": 16, "y": 32, "gridSize": 16}
  },
  "frames": [...]
}
```

### 依存パッケージ

- **dart:io** - ファイルシステムアクセス
- **dart:convert** - JSON パース
- **image** パッケージ - PNG デコード（`pub.dev/packages/image`）

### パフォーマンス考慮事項

1. **キャッシュ**: 同一 AssetPackage の検証結果をメモリキャッシュして重複検証を避ける
2. **並列処理**: 複数パッケージの検証を `Future.wait` で並列実行
3. **遅延読み込み**: PNG デコードは高コストなので、他の検証（JSON パース）で早期に失敗させる

### エラーハンドリング

- **ファイル不在**: `StateError` を throw（SpecComplianceSubscriber の `catch` で不整合判定）
- **JSON パースエラー**: `FormatException` を throw
- **画像デコードエラー**: `ImageException` を throw

### テスト戦略

1. **ユニットテスト**: モック FileSystem を使用して各メソッドを個別テスト
2. **統合テスト**: 実際の PNG/JSON ファイルを用意して End-to-End 検証
3. **エラーケース**: 不正な JSON、破損した PNG、ファイル不在などをテスト

### 使用例

```dart
// DI コンテナでの登録
container.registerSingleton<AssetValidator>(
  AssetValidatorImpl(fileSystem: LocalFileSystem()),
);

// SpecComplianceSubscriber での使用
final subscriber = SpecComplianceSubscriber(
  animationSpecRepository: animationSpecRepository,
  assetCatalogRepository: assetCatalogRepository,
  assetValidator: assetValidator, // 注入される
);
```
