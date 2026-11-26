# Dayframe

Plan your day. Frame your life.

Markdownで一日を計画し、タイムラインで確認し、ストーリーズ用の画像として残すiPhone / Macアプリです。Swift 6.4、SwiftUI、SwiftData、CloudKit、CoreText、ImageIOのみを使用します。第三者フレームワークや独自ログインはありません。

## 起動

Xcode 27.2以降、iOS / macOS 27以降が必要です。

- `Dayframe.xcodeproj`を開き、`Dayframe`スキームとMacまたはiPhone Simulatorを選んで実行します。
- Macのローカル版は`make run`で起動できます。アプリは`.build/Dayframe.app`に生成されます。
- 実機ではSigning & Capabilitiesで自分のTeamと、一意のBundle Identifierを設定してください。
- 日付一覧から過去・未来へ移動できます。MacはMarkdownとプランを左右分割、狭いウィンドウとiPhoneは切り替え表示です。
- カレンダーの日付をタップすると、その日のプランを開きます。iPhoneでは選択済みの日付も開き直せます。年月をタップして日付ピッカーを回しても、表示する月が変わるだけです。年月をもう一度タップするとカレンダーに戻ります。「日々のプラン」には内容のある日だけが表示され、日付を開くだけでは保存されません。
- ツールバーの追加ボタンでタスク作成、各タスクのメニューで編集・削除・同一セクション内の並び替えができます。セクションの追加・名前変更、Markdownの入出力はプランの操作メニューから行います。
- Macのショートカットは`⌘N`（追加）、`⌘S`（保存）、`⇧⌘E`（画像出力）、`⇧⌘T`（今日）です。

## Markdown

```markdown
# 2026-11-26

## Morning
- [ ] 07:00 Morning routine
	Start your day

## Work
- [x] 09:00 Review pull requests
- [ ] 10:00 Team meeting
- Read a book
```

- `#`は日付またはタイトル、`##`はセクションです。日付はISO形式、英語の月名形式、日本語の年月日に対応します。日付のないタイトルは選択した日付を使用します。
- `- [ ]`、`- [x]`、`- [X]`と通常の`-` / `*` / `+`リストに対応します。通常リストを完了にするとチェックリストへ変換します。
- タスク先頭の`HH:mm`を時刻として解釈します。範囲外の時刻はタスク名の一部として残します。
- タスク直後の2文字以上インデントされた行は説明文です。コードフェンス内のリストはタスクにしません。
- 対応しない記法や自由記述も原文として保持します。完全なMarkdownレンダラーではなく、デイリープラン用の行指向パーサーです。
- 編集するとプレビューを即時更新し、350msの入力停止後に保存します。完了操作、日付移動、バックグラウンド移行でも保存します。
- 見出しの日付を変えると保存先の日付も変わります。その日付に既存プランがある場合は上書きせずエラーを表示し、入力中の原文を残します。

## 画像共有

共有ボタンからMinimal / Editorial / Darkを選び、背景色・文字色・フォント・セクション・完了タスク・完了数・日付形式・署名を調整できます。

PNGは1080×1920px（9:16）です。上下180px、左右120pxの余白を確保しています。長い一覧や長文は複数ページへ分割し、タスク本文を省略しません。ページ選択で確認し、保存ボタンで選択ページを保存、標準共有シートで全ページをまとめて共有できます。Instagramが共有先に表示されるかはインストール済みアプリ側に依存します。直接投稿は実装していません。

## iCloudを有効にする

開発者のTeamやCloudKitコンテナはリポジトリから設定できないため、既定のビルドはローカル保存です。

1. Apple Developer ProgramのTeamを選択し、iOSとmacOSで同じBundle Identifierを使います。
2. Signing & CapabilitiesでiCloud / CloudKitを追加し、両プラットフォームで同じコンテナを選択します。iOSではPush NotificationsとBackground Modes / Remote notificationsも有効にします。
3. DayframeターゲットのUser-Defined Build Settingsを次のように設定します。

| 設定 | 値 |
| --- | --- |
| `DAYFRAME_CLOUDKIT_CONTAINER` | 自分のコンテナID（例：`iCloud.app.dayframe.Dayframe`） |
| `DAYFRAME_ENTITLEMENTS` | `dayframe/Dayframe.entitlements` |
| `DAYFRAME_MAC_ENTITLEMENTS` | `dayframe/Dayframe-macOS.entitlements` |

4. 自動署名が生成するプロビジョニングプロファイルに、選択したコンテナと通知の権限が含まれることを確認します。Xcodeが別のentitlementsを生成した場合は、実際のCode Signing Entitlementsが上記のファイルを参照していることを確認してください。
5. 同じApple AccountでiCloudにサインインしたiPhoneとMacでDebug版を実行します。初回同期の完了と、双方の編集・完了操作・オフライン復帰後の反映を確認します。
6. 配布前にCloudKit ConsoleでDevelopmentスキーマをProductionへデプロイします。DebugはDevelopment、ReleaseはProductionと本番通知を利用する設定です。

CloudKitの初期化に失敗した場合は**同じURLのストア**をクラウドなしで開きます。アカウント未設定や通信失敗でもローカル保存を継続します。ストアそのものが壊れている場合は削除・初期化せず、エラーを表示します。

状態表示は「端末に保存」「確認中」「同期待ち」「同期中」「同期済み」「利用不可」「失敗」です。「同期済み」はSwiftDataのCloudKitインポート・エクスポートイベントの成功を受信した場合だけ表示します。同期タイミングと再試行はOSが管理します。

**実際のiCloud同期は、署名済みの実機2台での確認が必要です。ローカルテストはApple AccountやCloudKitサーバーの代替にはなりません。**

## アーキテクチャ

- `DayframeCore`: UIに依存しないパーサー・行単位編集・IDの照合、SwiftDataのDayモデル、保存・復旧・同期状態。
- `DayframeExport`: フォント計測を利用したページ分割、固定サイズのキャンバス、ImageRendererとImageIOによるPNG生成。通常の画面とは独立しています。
- `DayframeApp`: 日付ごとの編集セッション、ネイティブな画面とファイル入出力。選択日付はウィンドウ単位です。

DayのMarkdownを正とし、TaskとSectionは派生値です。IDのスナップショットだけをDay内へ保存し、原文と同じSwiftDataトランザクションで更新します。別々のTaskレコードを同期しないため、二重管理を避けられます。CloudKit非対応のunique制約や必須リレーションは使っていません。

日付はGregorianの`yyyy-MM-dd`キーとUTCの保存値で管理し、画面では端末のタイムゾーンへ復元します。端末のタイムゾーン変更でプランの日付が前日にずれません。

同じ日に複数のDayが同期された場合は、内容のあるDayを優先し、更新時刻とIDで一意に選択します。異なる原文は復旧用のMarkdownへ退避してから重複を整理します。入力中にリモート変更を受けた場合と、Markdownインポート前も退避します。「復旧用の下書き」から復元・共有できます。退避に失敗した場合は削除しません。復旧用ファイル自体は端末ローカルです。

CloudKitは同じレコードへの同時編集で最終更新が優先される場合があります。共同編集や文字単位の競合マージはMVPの対象外です。認識できた競合は退避しますが、サーバー側で統合されるすべての編集履歴の保存は保証しません。

署名済みMac版の保存先はアプリのSandbox内の`Library/Application Support/Dayframe`です。署名なしのXcodeテスト版は別の保存領域になる場合があります。開発中にBundle IdentifierやSandbox設定を変える前にMarkdownをエクスポートしてください。

## 検証

```sh
make test
make lint
make complex
make build
xcodebuild -project Dayframe.xcodeproj -scheme Dayframe \
	-destination 'platform=iOS Simulator,name=iPhone 18 Pro' test
xcodebuild -project Dayframe.xcodeproj -scheme Dayframe \
	-destination 'platform=macOS' test \
	CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES CODE_SIGNING_REQUIRED=NO
```

Swift Testingで原文保持、ID保持、CRUD、日付変更、タイムゾーン、永続化の再読み込み、同日重複の退避、iCloudなしの状態、画像ページ分割とPNG寸法を検証します。XCUITestでタスク作成・完了反映・画像プレビュー、日本語の最大Dynamic Typeを検証します。UIテストは専用の一時ストアを使い、通常のデータには触れません。

フォント・色・操作ラベルはDynamic Type、VoiceOver、ダークモードに対応します。画像出力だけは固定サイズの作品として文字サイズを固定しています。Grid / Timelineテンプレート、カレンダー連携、AI生成、SNS直接投稿はMVPには含みません。

この環境ではMac、iPhone 18 Pro、iPhone Duoの主要操作と、iPhoneの日本語・最大Dynamic Typeを検証済みです。iPhone Duoの折り角変更・全回転・左右のSplit View、実機VoiceOver、2台間の実iCloud同期は手動確認が必要です。MacのUIテストはローカル署名が必要で、ウィンドウ復元がない場合は標準の新規ウィンドウ操作を行います。