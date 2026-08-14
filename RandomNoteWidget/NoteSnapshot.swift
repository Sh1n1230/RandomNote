import Foundation

/// タイムラインエントリに載せる軽量なコピー。SwiftData の @Model をそのまま WidgetKit に渡さない。
struct NoteSnapshot: Identifiable, Hashable, Sendable {
    let id: UUID
    let title: String
    let content: String
    let createdAt: Date
    let tag: String?

    init(id: UUID, title: String, content: String, createdAt: Date, tag: String? = nil) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.tag = tag
    }

    init(_ note: Note) {
        self.init(id: note.id, title: note.displayTitle, content: note.compactContent,
                  createdAt: note.createdAt, tag: note.tags.first)
    }

    static let placeholder = NoteSnapshot(
        id: UUID(),
        title: "反復想起は理解より記憶に効く",
        content: "読み返すより、思い出そうとする行為そのものが記憶を定着させる。だからメモは「見返す」ではなく「不意に出会う」形にしておくとよい。",
        createdAt: .now,
        tag: "学習"
    )
}

/// シャッフル用の決定的な乱数生成器。同じ seed なら同じ並びになる。
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed &* 6364136223846793005 &+ 1442695040888963407 }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
