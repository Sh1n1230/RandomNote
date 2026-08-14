import Foundation
import SwiftData

enum NoteFetch {
    /// アーカイブされていないメモ。#Predicate では `!$0.isArchived` ではなく `== false` を使う
    static var activeDescriptor: FetchDescriptor<Note> {
        FetchDescriptor<Note>(
            predicate: #Predicate { $0.isArchived == false },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
    }

    static var archivedDescriptor: FetchDescriptor<Note> {
        FetchDescriptor<Note>(
            predicate: #Predicate { $0.isArchived == true },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
    }

    /// ウィジェットなど、独立したコンテキストから読むとき用
    static func activeNotes(in container: ModelContainer) -> [Note] {
        let context = ModelContext(container)
        return (try? context.fetch(activeDescriptor)) ?? []
    }
}

extension Collection where Element == Note {
    /// 使用頻度の高い順、同数なら名前順のタグ一覧。フィルタチップの並びに使う。
    var usedTags: [String] {
        var counts: [String: Int] = [:]
        for note in self {
            for tag in note.tags { counts[tag, default: 0] += 1 }
        }
        return counts.sorted { $0.value == $1.value ? $0.key < $1.key : $0.value > $1.value }.map(\.key)
    }
}

extension Array where Element == Note {
    /// 直前に表示していたメモを避けてランダムに1件選ぶ（1件しかなければそれを返す）
    func randomNote(excluding excludedID: UUID?) -> Note? {
        guard !isEmpty else { return nil }
        let candidates = filter { $0.id != excludedID }
        return (candidates.isEmpty ? self : candidates).randomElement()
    }
}
