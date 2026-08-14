import Foundation
import SwiftData

/// アプリとウィジェット拡張で共有する識別子。実機配布時はここと2つの .entitlements を自分のものに置換する。
enum AppGroup {
    static let identifier = "group.com.example.randomnote"
    static let widgetKind = "RandomNoteWidget"
    static let urlScheme = "randomnote"
    /// メイン画面のシャッフル対象カテゴリ（空文字はすべて）
    static let scopeTagKey = "mainScopeTag"

    /// 呼ぶたびに新しいインスタンスを作ると @AppStorage が監視する対象とずれて
    /// 画面が更新されないので、必ず1つを使い回す。
    static let defaults: UserDefaults = UserDefaults(suiteName: identifier) ?? .standard
}

/// App Group のコンテナ上に置く単一の SwiftData ストア。アプリ・ウィジェットの双方がこれを参照する。
enum SharedStore {
    static let container: ModelContainer = {
        let schema = Schema([Note.self])
        let configuration = ModelConfiguration(
            schema: schema,
            groupContainer: .identifier(AppGroup.identifier),
            cloudKitDatabase: .none
        )
        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            // App Group が使えない環境（設定漏れなど）でもアプリが落ちないようローカルへフォールバックする
            let fallback = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
            return try! ModelContainer(for: schema, configurations: fallback)
        }
    }()
}
