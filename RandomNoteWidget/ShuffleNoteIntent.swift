import AppIntents
import WidgetKit

/// ウィジェット上のボタンから、アプリを開かずに別のメモへ切り替える
struct ShuffleNoteIntent: AppIntent {
    static let title: LocalizedStringResource = "別のメモを表示"
    static let isDiscoverable = false

    func perform() async throws -> some IntentResult {
        let defaults = AppGroup.defaults
        defaults.set(defaults.integer(forKey: WidgetSeed.key) &+ 1, forKey: WidgetSeed.key)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

enum WidgetSeed {
    static let key = "widgetShuffleSeed"
    static var current: UInt64 { UInt64(bitPattern: Int64(AppGroup.defaults.integer(forKey: key))) }
}
