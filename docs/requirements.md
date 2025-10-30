# Lo‑Fi Workmate — 要件定義 v1.0（確定）

> 目的：作業中に lo‑fi 音楽とドット絵の相棒（“もう一人の自分”）が伴走する没入体験を、軽量・省リソースで提供する。

---

## 0. 用語
- **アプリ**：本プロダクト。
- **相棒キャラ**：画面内で作業をともにするドット絵キャラクター。
- **シーン**：背景セット（自室/会社/カフェ/コワーキング 等）。
- **セッション**：ポモドーロ1サイクル中の連続した再生/アニメーション状態。

---

## 1. スコープ
- **対応 OS**：初期は macOS（Apple Silicon/Intel 両対応）。
- **将来拡張**：Windows / iOS / Android（レンダリング/入出力層は移植可能な抽象で設計）。
- **配布**：初期は開発者配布（DMG）→ 署名/公証（notarization）対応。
- **技術スタック（確定）**：**Flutter（Dart） +（必要に応じて）Flame + Skia**。

---

## 2. 機能要件（FRD）

### 2.0 実装優先度（MoSCoW）
- **Must**（MVP αで必須）
  - 相棒キャラの 30fps タイピング/コーヒー演出、背景 24fps（自室）
  - ローカル楽曲再生（単曲ループ）、音量/ミュート、フェード 500ms
  - ポモドーロ 25/5、通知、メニューバー残り時間表示
  - 設定保存/復元（SQLite/JSON）、ライセンスメタ保存
- **Should**（βで優先）
  - プレイリスト CRUD、長休憩、夜間ダークニング、自動服装切替
  - シーン追加（会社/カフェ）、BGM出力デバイス選択
- **Could**（将来候補）
- 公式カタログからのダウンロードフロー（ライセンス同梱自動化）
  - アバウト画面の自動クレジット生成、軽量テレメトリ（オプトイン）
- **Won’t（今はやらない）**
  - 自動アップデート、プラグイン/Mod 仕組み、スマホ連携（初版範囲外）

### 2.1 相棒キャラ体験
- [FR‑CHR‑01] 相棒キャラを 30 FPS で描画する。
- [FR‑CHR‑02] 作業中は「PC に向かってタイピング」モーションをループ再生する。
- [FR‑CHR‑03] 作業中にランダム（例：90–150 秒間隔、重み付け）で「コーヒーを飲む」モーションを挿入できる。
- [FR‑CHR‑04] 服装は時間帯（朝 4:00–11:59 / 昼 12:00–17:59 / 夜 18:00–3:59）で自動切替。手動上書き可。
- [FR‑CHR‑05] 初期キャラは 2 種類（例：A/B）。ユーザーが選択できる。

### 2.2 背景シーン
- [FR‑BG‑01] 背景を 24 FPS で描画する（相棒とは別レイヤ）。
- [FR‑BG‑02] シーン差し替え可能（初期 3 種：自室/会社/カフェ）。
- [FR‑BG‑03] シーン固有の演出（例：カフェ＝通行人/湯気、オフィス＝プリンタ稼働、部屋＝窓外の雲流れ）。
- [FR‑BG‑04] 明度/彩度の「夜間ダークニング」適用（自動/手動）。
- [FR‑BG‑05] ウィンドウサイズに応じて背景と相棒キャラを整数スケールで拡縮し、シーンごとのアンカー/オフセットを再計算して構図を保つ。

### 2.3 音楽再生
- [FR‑AUD‑01] ローカル保存した lo‑fi 楽曲の再生（aac/mp3/wav）。
- [FR‑AUD‑02] 公式カタログからの楽曲ダウンロード（メタデータ・ライセンス自動適用）。
- [FR‑AUD‑03] プレイリストの CRUD（作成/編集/削除/並び替え）。
- [FR‑AUD‑04] 単曲再生時はループ再生。
- [FR‑AUD‑05] フェードイン/アウト（デフォルト 500ms、可変）。
- [FR‑AUD‑06] 音量・ミュート、出力デバイス選択（macOS API）。

### 2.4 ポモドーロタイマー
- [FR‑POM‑01] デフォルト 25 分作業 / 5 分休憩。
- [FR‑POM‑02] 作業・休憩時間は 1–120 分の範囲でカスタム可能。
- [FR‑POM‑03] 作業→休憩→作業…の自動遷移。スキップ/一時停止/再開。
- [FR‑POM‑04] 長休憩オプション（例：4 セット後 15 分）有効/無効。
- [FR‑POM‑05] 遷移時の SFX/音量/フェード制御とアニメーション cue。

### 2.5 設定・永続化
- [FR‑SET‑01] 設定画面：キャラ/シーン/服装/タイマー/音量/起動時動作等。
- [FR‑SET‑02] 設定・プレイリスト・履歴はローカル保存（SQLite/JSON）。
- [FR‑SET‑03] 起動時に前回状態へ復元（任意）。

### 2.6 通知/ステータス
- [FR‑NOT‑01] セッション切替時にデスクトップ通知（許可制）。
- [FR‑NOT‑02] メニューバー（ステータスバー）に残り時間表示/クイック操作。

---

## 3. 非機能要件（NFR）
- [NFR‑PERF‑01] 1080p Canvas/ウィンドウで CPU 使用率 平均 < 12%（M1/M2 クラス目安）。
- [NFR‑PERF‑02] メモリ常駐 < 400 MB（平均）。
- [NFR‑RES‑01] 画面解像度スケール 1x/2x に対応（ピクセルアートはニアレスト隣接補間）。
- [NFR‑A11Y‑01] 文字サイズ/コントラスト調整、通知の読み上げ（macOS VoiceOver 連携）。
- [NFR‑I18N‑01] 国際化対応（初期は日本語/英語）。
- [NFR‑SEC‑01] ネットワークは外部素材取得時のみ。外部通信は明示許可＆TLS 必須。
- [NFR‑PRV‑01] 個人情報を収集しない。匿名使用。任意の使用統計は **明示オプトイン**。
- [NFR‑UPD‑01] 自動更新は将来対応（初期は手動）。

---

## 4. ライセンス/素材ポリシー
- 公式カタログに登録する楽曲は、提供者が事前に「商用可」「クレジット条件」「再配布可否」を確認し、**曲ごとにライセンスメモ**を付与する。
- メタデータ：`title`, `artist`, `catalog_track_id`, `download_url`, `license_name`, `license_url`, `attribution_text`, `allow_offline`, `checksum` を必須化。
- ダウンロード時に `licenses/<trackIdentifier>_LICENSE.txt`（曲単位）を同フォルダへ保存し、`licenseFilePath` として管理する。
- 素材キャッシュの消去機能を提供し、再ダウンロード時はカタログメタに基づき整合性チェックを行う。

---

## 5. アセット仕様（最終仕様・確定）

### 1) 解像度・スケール・補間
- **基準キャンバス**：`1920×1080 @1x`
- **描画スケール**：**整数拡大のみ**（@1x→@2x→@3x…）
- **補間**：**nearest-neighbor 固定**（Flutter Canvas/Flame で `FilterQuality.none`）
- **ピクセルグリッド**：**16px 基準**（背景タイル/小物を16の倍数で設計）

#### スプライト寸法（キャラ・小物）
- **相棒キャラ原寸**：`128×128 @1x`（**安全余白 8px** を四辺に確保）
- **小物**：`32×32` / `64×64` の整数倍（例：カップ `32×32`、PC `64×32`）

### 2) フレームレート & ループ長
- **キャラ**：**30fps**
  - `typing`：**12f**（0.4s ループ）
  - `coffee`：**24f**（0.8s 単発 → `typing`へ戻る）
- **背景**：**24fps**
  - 基本ループ：**96f（4.0s）**
  - 長尺ループ：**192f（8.0s）**

> ループ長は 12/24/48/96/192 の倍数のみを採用。キャラ30fpsと背景24fpsを**整数秒**で同期しやすくするため。

### 3) カラーパレット & 描画ルール
- **最大色数**：  
  - キャラ：**24色**（共通パレット）  
  - 背景：**32色/シーン**（必要なら 40 まで許容）
- **影**：ベース比 **+12〜16 の明度差** で1段階を基本（過度な多段影は禁止）
- **ハイライト**：1段階まで。加算合成や半透明多用は避け、**ドザベタ**で表現
- **ライン**：主要輪郭 **1px**、サブピクセル（0.5px等）禁止
- **透過**：背景透過OK、アンチエイリアスの半透明縁取りは**禁止**

### 4) ファイル形式・圧縮・アトラス
- **画像**：**PNG（可逆・インデックス可）** を基本  
  - WebP Losslessは可だが、初版はPNGに統一
- **アトラス**：`2048×2048` を推奨上限（Mac環境なら `4096×4096` も可、冗長回避のため 2048優先）
- **パディング**：**2px**（最小）〜 **4px**（推奨）フレーム間ギャップ（ブリード防止）
- **トリム**：可。ただし**ピボット（原点）**をメタデータで保持
- **前処理**：パレット最適化（PNG8）を検討。ただし色段差が出る場合はフルカラーPNG

### 5) ディレクトリ構成（確定）
```
assets/
  characters/
    char_a/
      sprites/
        typing/
          char_a_typing@1x.aseprite
        coffee/
          char_a_coffee@1x.aseprite
      atlas/
        atlas_char_a@1x.png
        atlas_char_a@1x.json
    char_b/ ...
  scenes/
    room/
      atlas_room@1x.png
      atlas_room@1x.json
    office/
      atlas_office@1x.png
      atlas_office@1x.json
    cafe/
      atlas_cafe@1x.png
      atlas_cafe@1x.json
  audio/
    bgm/
    sfx/
  licenses/
    <trackId>_LICENSE.txt
  meta/
    animation.json
```

### 6) 命名規約
- **ファイル**：`<kind>_<name>_<state>@<scale>.<ext>`  
  例：`char_a_typing@1x.png`, `bg_cafe_loop@1x.png`
- **アトラス**：`atlas_<kind>_<name>@<scale>.png` + `.json`
- **ID/識別子**：`[a-z0-9_]+`（例：`char_a`, `scene_cafe`）
- **Aseprite**  
  - **レイヤ**：`body`, `hands`, `mug`, `fx`  
  - **タグ**：`typing`, `coffee`, `loop`  
  - **スライス**：`safe`（安全枠）、`pivot`（ピボット）

### 7) メタデータスキーマ（`meta/animation.json`）
```json
{
  "version": 1,
  "pixelScale": 1,
  "interpolation": "nearest",
  "characters": [
    {
      "id": "char_a",
      "atlas": "assets/characters/char_a/atlas/atlas_char_a@1x.png",
      "atlasData": "assets/characters/char_a/atlas/atlas_char_a@1x.json",
      "spriteSize": { "w": 128, "h": 128 },
      "safePadding": 8,
      "animations": {
        "typing": { "fps": 30, "frames": 12, "loop": true, "pivot": {"x":64,"y":120} },
        "coffee": { "fps": 30, "frames": 24, "loop": false, "next": "typing", "pivot": {"x":64,"y":120} }
      },
      "outfits": {
        "morning": "char_a_outfit_morning",
        "noon": "char_a_outfit_noon",
        "night": "char_a_outfit_night"
      }
    }
  ],
  "scenes": [
    {
      "id": "scene_cafe",
      "atlas": "assets/scenes/cafe/atlas_cafe@1x.png",
      "atlasData": "assets/scenes/cafe/atlas_cafe@1x.json",
      "animations": {
        "loop": { "fps": 24, "frames": 96, "loop": true }
      },
      "effects": { "pedestrians": true, "steam": true }
    }
  ]
}
```

### 8) Aseprite 書き出しルール & CLI テンプレ
- **共通設定**
  - ピクセルスナップON、整数座標のみ
  - **トリミング有効**（`--trim`）＋ **パディング2px**（atlas側で確保）
  - 書き出しは **json-array** 形式
- **CLI例（キャラ）**
```bash
aseprite -b assets/characters/char_a/sprites/typing/char_a_typing@1x.aseprite   --sheet assets/characters/char_a/atlas/atlas_char_a@1x.png   --data  assets/characters/char_a/atlas/atlas_char_a@1x.json   --format json-array   --list-tags --trim --filename-format {tag}_{frame}
```
- **注意**  
  - `pivot` は Asepriteのスライス or JSON後処理で必ず保持  
  - パディングはパッカー（TexturePacker等）使用時も **2〜4px** を強制

### 9) 背景シーン仕様（初期3種）
| ID | ループ | 追加演出 | 備考 |
|---|---|---|---|
| `scene_room` | 96f/24fps | 雲流れ/カーテン | 明暗トーン切替（夜間） |
| `scene_office` | 96f/24fps | プリンタ/LED点滅 | LED周期は48fで位相ズラし |
| `scene_cafe` | 96f/24fps | 通行人/湯気 | 通行人は48fオフセット多重 |

> 背景は**1タイル=16px**基準でレイヤ化。並走オブジェクト（通行人等）は**ループ境界でティアリング無し**を必須。

### 10) 服装の自動切替（朝/昼/夜）
- **時間帯**：朝 4:00–11:59 / 昼 12:00–17:59 / 夜 18:00–3:59
- **アセット**：各衣装の差分は**独立レイヤ**または**別アトラス**で管理（差分が軽い場合は乗算/置換レイヤ）
- **優先**：手動指定＞自動判定

### 11) オーディオ仕様
- **フォーマット優先順**：**AAC > MP3 > WAV**  
  - macOSの再生実績・無音ギャップ観点（AAC推奨）
- **BGM/SFX**：BGM 1ch + SFX 2ch（同時最大3）
- **ループ**：  
  - ループポイントをメタに保持（サンプル番号 or ms）  
  - ループ無い場合でも**フェード 500ms**で継ぎ目対策
- **正規化**：目安 **-14 LUFS**（楽曲取得時の目合わせ）
- **命名**：`bgm_<mood>_<bpm>.m4a`, `sfx_<name>.wav`
- **ライセンスメタ（曲単位・必須）**  
  - `title`, `artist`, `source_url`, `license_name`, `license_url`, `attribution_text`, `allow_offline`  
  - `licenses/<trackId>_LICENSE.txt` を同梱保存

### 12) 同期・タイムライン設計
- **基準クロック**：アプリの`Ticker`（Flutter）を**単一ソース**とし、  
  - キャラ：30fps、背景：24fps の**サブタイムライン**で割り当て  
- **遷移フック**：`onPhaseEnter/Exit` で  
  - BGMフェード（500ms）  
  - `coffee` モーション開始/終了  
  - 通知/メニューバー更新  
- **バックグラウンド低負荷**：Window Hidden 時は**キャラ15fps/背景12fps**に間引き（見た目の破綻がない設計に）

### 13) 品質基準（QA チェックリスト）
- [ ] すべての拡大倍率で**ボケ・にじみゼロ**（nearest固定、整数拡大）
- [ ] ループの**継ぎ目に1pxのズレ/色差が無い**
- [ ] アトラスの**ブリーディング無し**（2〜4pxパディング、境界でのにじみ無し）
- [ ] `coffee`→`typing` の遷移で**ポーズ破綻無し**（最終2フレームはブレンド/同姿勢）
- [ ] 背景パララックス/並走物の**境界同期**（96f境界でティアリング無し）
- [ ] BGM単曲ループの**無音ギャップ < 100ms**（実測ログ）
- [ ] 服装切替（朝/昼/夜）で**色数・輪郭スタイルが一貫**
- [ ] LICENSE/メタが**全曲**に付与・保存されている

### 14) 制作ワークフロー（推奨）
1. **Aseprite 制作**：16pxグリッド、1pxライン、タグ/スライス設定  
2. **書き出し**：CLIテンプレでPNG+JSON（json-array）  
3. **パッキング**：アトラス化（2〜4pxパディング、2048上限厳守）  
4. **メタ統合**：`meta/animation.json` にfps/frames/next/pivot/衣装を登録  
5. **検証**：テストHarness（Flame/Flutter）でfps・ループ・ピボット確認  
6. **最終チェック**：QAチェックリスト通過 → リポジトリに配置

### 15) 予算（参考最大値）
- **画像メモリ**（PNGデコード後）：  
  - 2048×2048 × RGBA8 ≒ **16MB/枚**  
  - キャラ1枚 + 背景1枚 + UI/小物1枚 ≒ **48MB** 以内を目安
- **CPU/GPU**：1080p / 表示中 **CPU < 12%**, メモリ常駐 **< 400MB**（M1/M2 目安）

### 16) 実装メモ（Flutter/Flame）
- **最近傍**：`FilterQuality.none`、`Paint.isAntiAlias=false`  
- **揺れ対策**：`Alignment.topLeft` + **整数座標配置**（端数禁止）  
- **スプライト**：Flameの`SpriteAnimation`（`loop=true/false`、`onComplete`で`next`へ）  
- **アトラス**：Flameはatlas JSON対応、ピボットはcustomメタで補う  
- **オーディオ**：`just_audio` の`LoopMode.one`＋手動フェード、出力切替は将来対応

---

## 6. UI/UX（主要画面）
1) **メインウィンドウ**：キャラ＆背景、下部にミニコントロール（再生/停止、残り時間）。  
2) **クイックパネル**（メニューバー／⌘⇧P）：キャラ/シーン切替、音量、タイマー制御。  
3) **設定**：  
   - 一般：起動復元、言語、通知。  
   - 見た目：キャラ、服装（自動/手動）、背景、夜間モード。  
   - 音楽：プレイリスト編集、取り込み、フェード、出力。  
   - タイマー：作業/休憩/長休憩、スキップ許可、SFX。

---

## 7. 状態遷移（ポモドーロ）
```
IDLE → WORKING → BREAK → (LONG_BREAK every N cycles) → WORKING …
  |        |           |
  └── Start/Resume     └── Skip/End/Auto
```
- タイマー精度：±1 秒以内。スリープ復帰補正（システム時刻で差分補正）。
- 遷移時フック：`onPhaseEnter/Exit`（音量フェード、アニメ cue、通知）。

---

## 8. データモデル（例：SQLite/JSON）
```ts
Track {
  id, title, artist, localPath, durationMs,
  sourceUrl, licenseName, licenseUrl, attributionText, allowOffline
}
Playlist { id, name, tracks: TrackId[], createdAt, updatedAt }
Character { id, name, spritesheetPath, animations: { typing, coffee }, outfits: { morning, noon, night } }
Scene { id, name, bgAtlasPath, effects: { pedestrians?: boolean, steam?: boolean, clouds?: boolean } }
Settings {
  language, volume, outputDeviceId?,
  selectedCharacterId, selectedSceneId,
  outfitMode: "auto"|"manual",
  theme: "day"|"night"|"auto",
  pomodoro: { workMin, breakMin, longBreakMin, longBreakEvery },
  restoreOnLaunch
}
SessionLog { id, startedAt, endedAt, workMs, breakMs, cycles }
```

---

## 9. 技術アーキテクチャ（確定）
- **ランタイム/UI**：Flutter（macOS デスクトップ）
- **2D描画**：Skia（Flutter Canvas）。必要に応じて **Flame** を使用（スプライト、タイムライン管理）。
- **オーディオ**：`just_audio` + `audio_session` を基本。BGM 1ch + SFX 2ch、ループ/フェード対応。
- **永続化**：`sqflite` または `isar`。楽曲/アセットはファイルストレージに保存。
- **通知/メニューバー**：`flutter_local_notifications` + macOS メニューバー拡張（プラグイン or 自作 Platform Channel）。
- **ライセンス保存**：楽曲取得時に LICENSE テキストを同梱保存、メタをDB/JSONに格納。
- **ビルド/配布**：Xcode で署名/公証→ DMG 作成（後で自動化）。

---

## 10. 設定・権限
- 初回起動時：
  - ライセンス/プライバシー同意。
  - 通知許可の確認。
- 外部ダウンロード：保存先と容量上限（例：1GB）を設定可。

---

## 11. 受け入れ基準（サンプル）
- [AC‑CHR‑01] タイピング→コーヒー→タイピングの遷移が 10 分間で最低 3 回発生（確率 0.2/分想定、デバッグ倍率あり）。
- [AC‑BG‑01] カフェシーンで 4 秒ごとに通行人のループが破綻しない（境界でティアリングなし）。
- [AC‑AUD‑01] 単曲ループ時に無音ギャップが 100ms 未満。
- [AC‑POM‑01] 25/5 設定で 90 分稼働し、作業→休憩が 3 回正しいタイミングで通知される。
- [AC‑SET‑01] 再起動後に直前のキャラ/シーン/音量/タイマー設定が復元。

---

## 12. リスクと軽減策
- **楽曲ライセンス不整合**：メタ必須化・ライセンス保存・取り込み時に確認ダイアログ。
- **リソース過負荷**：FPS 限定/バックグラウンド時の描画間引き（例：前景 15fps/背景 12fps）。
- **マシン差**：初回ベンチで描画解像度/エフェクトを自動チューニング。
- **著作権表記漏れ**：アバウト画面に自動生成のクレジットリストを常設。

---

## 13. MVP（α）範囲（MoSCoW: Must のみ）
- キャラ 1 種（typing 12f / coffee 24f）+ 背景 1 種（自室 96f）。
- ローカル楽曲の手動インポート + 単曲ループ（フェード 500ms）。
- ポモドーロ（25/5）+ 通知 + メニューバー残り時間表示。
- 設定保存/復元、ライセンスメタ保存、整数スケール描画の保証。

---

## 14. βでの追加（MoSCoW: Should 中心）
- キャラ 2 種 / 背景 3 種 / 服装自動切替。
- プレイリスト CRUD、長休憩、夜間モード、出力デバイス選択。
- 公式カタログからのダウンロードフロー（ライセンス確認 UI は閲覧のみ）。

---

## 15. テレメトリ/ログ（任意オプトイン）
- 起動回数、平均セッション長、クラッシュレポート（個人情報なし）。
- ログ保存上限/自動削除。ユーザーが明示的に送信可。

---

## 16. 品質保証 / Definition of Done（抜粋）
- 1920×1080 @1x / 整数スケール / nearest で**全画面ボケ無し**。
- タイピング/コーヒー/背景の**継ぎ目無しループ**確認。
- 単曲ループ時の無音ギャップ < 100ms（測定ログ添付）。
- スリープ復帰を含むタイマー誤差 ±1s 以内（90分耐久）。
- ライセンスメタ & LICENSE テキストが楽曲ごとに保存され、アバウト画面で参照可。
- 署名/公証済み DMG を配布可能な状態で生成できる。

---

## 17. リリース計画（例）
- **M1（~4週）**：MVP α 完了、内部テスト（CPU/GPU/メモリ測定、ギャップ検証）。
- **M2（~4週）**：β 追加機能実装、アクセシビリティ/I18N。
- **M3（~2週）**：公証/配布、クレジット/ライセンス最終確認。

---

## 18 課金・利用制限（将来対応）
- **無課金（Free）**
  - 登録できる楽曲：最大3曲
  - 使用できるキャラクター：2種まで
- **課金（Paid）**
  - 楽曲数／キャラ数ともに無制限
- **実装方針**
  - `EntitlementService` で `canAddTrack`／`canUseCharacter` を判定。
  - `Plan`, `Subscription`, `Entitlement` エンティティを設計。
  - 初期版ではfree固定で制限無効（将来トグルで有効化）。
  - 購読状態はローカルキャッシュ（TTL付き）で保持し、オフラインでも判定可。
  - StoreKit／RevenueCat／独自検証のいずれにも対応できるポート/アダプタ構成。
