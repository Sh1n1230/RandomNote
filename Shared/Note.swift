import Foundation
import SwiftData

@Model
final class Note {
    /// ウィジェットのディープリンク用に安定したキーを持たせる（SwiftData の PersistentIdentifier とは別）
    var id: UUID = UUID()
    var title: String = ""
    var content: String = ""
    var createdAt: Date = Date()
    var isArchived: Bool = false
    /// カテゴリ。「講演」のような出所と「哲学史」のような主題は別の軸なので、1件に複数付けられるようにしている。
    /// 別モデルにせず文字列配列で持つ（個人用の規模なら十分で、スキーマも増えない）。
    var tags: [String] = []

    init(id: UUID = UUID(), title: String, content: String, createdAt: Date = Date(), isArchived: Bool = false, tags: [String] = []) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.isArchived = isArchived
        self.tags = tags
    }
}

extension Note {
    /// 一覧やウィジェットで使う表示用タイトル（未入力なら本文の冒頭で代用）
    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        let head = content.trimmingCharacters(in: .whitespacesAndNewlines).prefix(20)
        return head.isEmpty ? "無題のメモ" : String(head)
    }

    /// 表記ゆれと空文字を弾いたタグ。nil ならタグとして採用しない。
    static func normalizedTag(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : String(trimmed.prefix(24))
    }

    func addTag(_ raw: String) {
        guard let tag = Note.normalizedTag(raw), !tags.contains(tag) else { return }
        tags.append(tag)
    }

    /// ウィジェットの本文冒頭。改行の連続を潰して行数を稼ぐ
    var compactContent: String {
        content
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
