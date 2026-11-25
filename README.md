# opencode-session-pins

**OpenCode Desktop / Web（PC・スマホ・iPad）のホーム画面・セッション画面に「ピン留め機能」＋「端末間リアルタイム同期」を追加するパッチ＆導入ツール**です。

OpenCode 公式 `v2.4.1` をベースにしています。

> OpenCode 公式にも TUI 版の `Ctrl+F` ピン留めや、実験的サイドバーモードでのローカルピン機能はありますが、**標準のホーム画面（「今日 / 昨日 / それ以前」）でのピン留め**や**PC ⇔ スマホ / iPad 間のリアルタイム同期**が無かったため自作しました。

---

## できること

- **ホーム画面に「ピン留め」グループを固定表示**
  - 「今日」の上にピン留めしたセッションを常時表示します。
  - 直近 64 件の表示ウィンドウから流れた古いセッションも、ID ルックアップで引き続き表示されます。
  - プロジェクト絞り込み中も選択プロジェクトに属するピンだけを表示し、他プロジェクトのピンは消えません。
- **どこからでもピン留め / 解除**
  - **ホーム画面（PC）**: セッション行を右クリック →「ピン留め / ピン留めを解除」
  - **ホーム画面（スマホ / タブレット）**: 各行右端の `…` ボタン（または長押し）→「ピン留め / ピン留めを解除」
  - **セッション画面（PC / iPad）**: 左上ヘッダーの `…` メニュー →「ピン留め / ピン留めを解除」
  - **セッション画面（スマホ）**: 上部バー右端のピンアイコンをタップ
- **PC ⇔ スマホ / iPad でリアルタイム同期**
  - ピン留め状態はサーバー側の既存 SQLite `kv` テーブル（キー `"home.pins"`）に保存されるため、DB マイグレーション不要です。
  - 更新時は SSE（`server.home_pins.updated`）で全接続クライアントへ即座に反映されます。
  - 古いサーバー（API 未対応）に接続した場合は自動でローカル保存のみにフォールバックします。
- **日本語 / 英語 UI 対応**
  - `Pinned` / `Pin` / `Unpin` および日本語ラベル（`ピン留め` / `ピン留めを解除`）に対応しています。
- **自動アップデート無効化**
  - カスタムビルドが公式リリースで意図せず上書きされないよう、自動アップデートを無効化しています。

---

## 導入方法

### 方法 1: フォーク済みブランチからそのままビルドする（おすすめ）

パッチ適用済みのブランチを [hiyasitomato/opencode (`home-session-pins`)](https://github.com/hiyasitomato/opencode/tree/home-session-pins) に公開しています。

```bash
git clone -b home-session-pins https://github.com/hiyasitomato/opencode.git
cd opencode
bun install
```

### 方法 2: 公式 OpenCode `v2.4.1` にこのリポジトリのパッチを当てる

```bash
# 1. 公式 OpenCode v2.4.1 を取得
git clone --branch v2.4.1 https://github.com/anomalyco/opencode.git
cd opencode
git checkout -b home-session-pins

# 2. パッチを適用（macOS / Linux）
/path/to/opencode-session-pins/scripts/apply.sh .

# または直接 git apply
git apply /path/to/opencode-session-pins/patches/opencode-v2.4.1-home-session-pins.patch

bun install
```

Windows PowerShell の場合：

```powershell
.\scripts\apply.ps1 -RepoPath C:\path\to\opencode
```

---

## ビルド・起動方法

### 開発モードで試す

既存の公式 OpenCode 本体を上書きせずに、`dev` プロファイルで動作確認できます。

```bash
bun run dev:desktop
```

### Desktop インストーラーをビルドする（Windows 例）

> **重要**: `OPENCODE_CHANNEL` には `prod` ではなく **`latest`** を指定してください。CLI が標準の `service.json` に登録し、Desktop と正常に接続されます。また、`OPENCODE_VERSION` に公式と異なるサフィックス（例: `2.4.1-pins.1`）を付けることで、公式版 `opencode-cli` のキャッシュ再利用を防ぎ確実にカスタム版へ切り替わります。

```powershell
$env:OPENCODE_CHANNEL = "latest"
$env:OPENCODE_VERSION = "2.4.1-pins.1"

bun run --cwd packages/cli build --single --baseline
bun run --cwd packages/desktop build
Set-Location packages\desktop
bunx electron-builder --win --x64 --publish never --config electron-builder.config.ts
```

生成先: `packages/desktop/dist/opencode-desktop-win-x64.exe`

※ 未署名ビルドのため Windows SmartScreen が表示された場合は「詳細情報 → 実行」で起動できます。

---

## スマホ / iPad ブラウザで反映されないとき

OpenCode の Web UI は PWA の Service Worker でアセットをキャッシュするため、以前のタブが開いたままだとリロードしても古いバージョンが残ることがあります。

1. スマホ / iPad のブラウザで OpenCode のタブを **すべて閉じる**（タブグループ内も含む）
2. ブラウザアプリを一度完全に終了してから開き直す
3. ペアリングリンク / トンネル URL を新しいタブで開く

---

## 技術構成・変更概要

- **サーバー / プロトコル / SDK**
  - `GET /api/home/pins`・`PUT /api/home/pins/:sessionID`・`DELETE /api/home/pins/:sessionID` を追加（`packages/protocol/src/groups/server.ts`, `packages/server/src/handlers/server.ts`）
  - 既存 SQLite `kv` テーブルの `"home.pins"` キーに排他制御（`Semaphore`）付きで永続化
  - `server.home_pins.updated` SSE イベントを追加し全クライアントへ配信（`packages/schema/src/server-event.ts`, `event-manifest.ts`）
  - `@opencode/client` Promise / Effect SDK を再生成
- **フロントエンド（SolidJS）**
  - `packages/app/src/home/sessions/pins.ts` / `pin-sync-machine.ts` / `pin-store.ts`: 楽観的更新・直列化ミューテーションキュー・初回ローカルピン移行・SSE リアルタイム同期
  - `packages/app/src/runtime/server/runtime.tsx`: サーバー常駐コントローラーに `homePins` を統合し、ホーム画面・セッション画面で状態を共有
  - `packages/app/src/home/sessions/view.tsx` / `view.css`: ホーム行のコンテキストメニュー、ピンアイコン、モバイル用 `…` ボタン、長押し時のタッチコールアウト抑制
  - `packages/app/src/session/timeline/message-timeline.tsx` / `packages/app/src/session/screen.tsx`: セッションヘッダー `…` メニュー＆スマホ上部バーのピンボタン
  - `packages/ui/src/icons/catalog.ts`: `pin` アイコン追加
- **テスト**
  - サーバー永続化＆SSE テスト（`packages/server/test/home-pins.test.ts`）
  - ユニットテスト（`pins.test.ts`, `groups.test.ts`, `pin-lookup.test.ts`, `pin-sync-machine.test.ts`）
  - E2E テスト（`packages/app/e2e/regression/home.spec.ts`: ピン留め・再起動保持・プロジェクト切替・64 行外ピン・別デバイスからの SSE ライブ同期・セッションヘッダーメニュー・モバイル UI 操作）

全差分は GitHub 上でも確認できます: https://github.com/hiyasitomato/opencode/compare/v2.4.1...home-session-pins

---

## 注意事項

- ベースとなる OpenCode は `v2.4.1` です。公式の新しいバージョンで上書きインストールするとピン留め機能は公式版に置き換わりますが、SQLite `kv` テーブル内のピン留めデータ自体は保持されます。
- 非公式のコミュニティパッチです。利用は自己責任でお願いします。

## License

MIT License（[LICENSE](./LICENSE)）
