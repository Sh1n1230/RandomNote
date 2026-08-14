import Foundation
import SwiftData
import WidgetKit

/// 初回起動時だけサンプルメモを入れる。不要ならこのファイルごと削除し、
/// RandomNoteApp.swift の `.task { SampleData.seedIfNeeded(...) }` を消せばよい。
enum SampleData {
    private static let seededKey = "didSeedSampleNotes"

    @MainActor
    static func seedIfNeeded(into container: ModelContainer) {
        let defaults = AppGroup.defaults
        guard !defaults.bool(forKey: seededKey) else { return }
        let context = container.mainContext
        let isEmpty = ((try? context.fetchCount(FetchDescriptor<Note>())) ?? 0) == 0
        defaults.set(true, forKey: seededKey)
        guard isEmpty else { return }
        for note in samples { context.insert(note) }
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    private static var samples: [Note] {
        [
            Note(title: "反復想起は理解より記憶に効く",
                 content: "読み返すより、思い出そうとする行為そのものが記憶を定着させる。だからメモは「見返す」ではなく「不意に出会う」形にしておくとよい。ホーム画面に置く意味はここにある。",
                 tags: ["読書", "学習法"]),
            Note(title: "書くことは考えることの外部化",
                 content: "頭の中だけで考えを回すとワーキングメモリの容量に縛られる。文章にした瞬間に思考の作業台が広がり、矛盾や飛躍が目に見えるようになる。",
                 tags: ["読書", "思考法"]),
            Note(title: "制約が創造性を生む",
                 content: "選択肢が多いほど良いものができるとは限らない。締切・文字数・素材の制限が、かえって発想の筋道を作る。何を捨てるかを先に決めるほうが速い。",
                 tags: ["講演", "思考法"])
        ]
    }
}
