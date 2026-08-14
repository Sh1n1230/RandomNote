# RandomNote

溜めたメモをランダムに提示して受動的に復習するiOSアプリ。通知は一切使わず、ホーム画面ウィジェットとアプリ起動時の表示で自然に目に入れる。

## デザイン

**UIに触れる前に必ず [design_system.yml](design_system.yml) を読むこと。**

色・タイポグラフィ・余白・角丸・コンポーネント規約はすべてそこが正。Swift側の [Shared/DesignSystem.swift](Shared/DesignSystem.swift) はYAMLの写しなので、**YAMLを変えたらSwiftも合わせる**（逆も同じ）。

- 新しいUIを書くときは `DS.Color` / `DS.Text` / `DS.Space` / `DS.Radius` のトークンを使う。生の `Color(.systemBackground)` や `.padding(17)` のような直値を新規に足さない。
- YAMLの `principles` セクションは個別トークンより優先する。迷ったらそこに戻る。
- 変更はライト／ダーク両方で確認する。

## 構成

| ディレクトリ | 内容 |
|---|---|
| `Shared/` | アプリ・ウィジェット両ターゲットに所属。SwiftDataモデル、App Group共有ストア、デザイントークン |
| `RandomNote/` | アプリ本体（buildable folder。ファイルを足せば自動でターゲットに入る） |
| `RandomNoteWidget/` | ウィジェット拡張（同上） |
| `Config/` | Info.plist × 2、entitlements × 2 |

## 制約

- **ローカル通知は実装しない。** `UserNotifications` のimport、パーミッション要求、通知スケジュールを一切入れない。これは仕様であって未実装項目ではない。
- アプリとウィジェットは別プロセスなので、SwiftDataストアは App Group (`group.com.example.randomnote`) 上の1つを共有する。定義は [Shared/SharedStore.swift](Shared/SharedStore.swift) の1箇所だけ。
- メモを保存・削除・アーカイブしたら `WidgetCenter.shared.reloadAllTimelines()` を呼ぶ。呼ばないとウィジェットは古いタイムラインを出し続ける（設定変更の反映も遅れる）。
- ウィジェットは `AppIntentConfiguration`。カテゴリの絞り込みは `SelectCategoryIntent` で持つ。`CategoryQuery.entities(for:)` は保存済みIDをそのまま返すこと（候補一覧と突き合わせると、ストアを読めなかったときに設定が消える）。
- App Group の `UserDefaults` は `AppGroup.defaults`（`static let`）を使う。呼ぶたびに `UserDefaults(suiteName:)` を作らない。
- `#Predicate` では `!$0.isArchived` ではなく `$0.isArchived == false` と書く（SwiftDataの変換都合）。
- カテゴリは `Note.tags: [String]` の**複数タグ**。別モデルにはしない。「講演」のような出所と「哲学史」のような主題は別の軸なので、単一カテゴリにはしない。タグでの絞り込みは `#Predicate` ではなくメモリ上で行う（個人用の件数なら十分で、配列に対する述語はSwiftDataで不安定）。

## ビルド

```bash
xcodebuild -scheme RandomNote -destination 'platform=iOS Simulator,name=iPhone 17' build
```

実機に載せる際は、両ターゲットのTeam設定に加えて Bundle ID / App Group を自分のものへ置換する（`Config/*.entitlements` と `Shared/SharedStore.swift`）。
