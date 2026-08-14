import AppIntents
import SwiftUI
import WidgetKit

struct NoteEntry: TimelineEntry {
    let date: Date
    let note: NoteSnapshot?
    /// 設定で絞り込んでいるカテゴリ。該当メモが0件のときの案内に使う。
    var scope: String?
}

/// 1時間ごとに別のメモへ切り替わるタイムラインを先出しで組む
struct NoteTimelineProvider: AppIntentTimelineProvider {
    private static let interval: TimeInterval = 60 * 60
    private static let entryCount = 12

    func placeholder(in context: Context) -> NoteEntry {
        NoteEntry(date: .now, note: .placeholder)
    }

    func snapshot(for configuration: SelectCategoryIntent, in context: Context) async -> NoteEntry {
        let scope = configuration.category?.id
        let notes = loadSnapshots(scope: scope)
        return NoteEntry(date: .now, note: context.isPreview ? .placeholder : notes.first, scope: scope)
    }

    func timeline(for configuration: SelectCategoryIntent, in context: Context) async -> Timeline<NoteEntry> {
        let scope = configuration.category?.id
        let notes = loadSnapshots(scope: scope)
        guard !notes.isEmpty else {
            let entry = NoteEntry(date: .now, note: nil, scope: scope)
            return Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(Self.interval)))
        }
        let start = Calendar.current.date(bySetting: .second, value: 0, of: .now) ?? .now
        let entries = (0..<Self.entryCount).map { index in
            NoteEntry(
                date: start.addingTimeInterval(Double(index) * Self.interval),
                note: notes[index % notes.count],
                scope: scope
            )
        }
        return Timeline(entries: entries, policy: .atEnd)
    }

    /// App Group 上の共有ストアから読み、カテゴリで絞ってシード付きでシャッフルする
    private func loadSnapshots(scope: String?) -> [NoteSnapshot] {
        var generator = SeededGenerator(seed: WidgetSeed.current &+ 1)
        return NoteFetch.activeNotes(in: SharedStore.container)
            .filter { scope == nil || $0.tags.contains(scope!) }
            .map(NoteSnapshot.init)
            .shuffled(using: &generator)
    }
}

struct RandomNoteWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: AppGroup.widgetKind,
            intent: SelectCategoryIntent.self,
            provider: NoteTimelineProvider()
        ) { entry in
            RandomNoteWidgetView(entry: entry)
                .containerBackground(DS.Color.surface, for: .widget)
        }
        .configurationDisplayName("ランダムメモ")
        .description("溜めたメモから1件をランダムに表示します。1時間ごとに切り替わり、長押しでカテゴリを絞り込めます。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct RandomNoteWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: NoteEntry

    var body: some View {
        if let note = entry.note {
            noteBody(note)
                .widgetURL(URL(string: "\(AppGroup.urlScheme)://note/\(note.id.uuidString)"))
        } else {
            emptyBody
        }
    }

    private func noteBody(_ note: NoteSnapshot) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            if family == .systemSmall {
                Text(note.tag ?? Self.shortDate(note.createdAt))
                    .dsMicroLabel(note.tag == nil ? DS.Color.inkTertiary : DS.Color.accent)
                    .lineLimit(1)
            }
            Text(note.title)
                .font(.headline)
                .tracking(-0.2)
                .foregroundStyle(DS.Color.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            Text(note.content)
                .font(family == .systemSmall ? .caption : .footnote)
                .foregroundStyle(DS.Color.inkSecondary)
                .lineSpacing(1)
                .lineLimit(family == .systemSmall ? 4 : 5)
                .minimumScaleFactor(0.8)
                .padding(.top, 2)
            Spacer(minLength: 0)
            if family != .systemSmall {
                HStack(spacing: DS.Space.sm) {
                    if let tag = note.tag {
                        Text(tag).dsMicroLabel(DS.Color.accent).lineLimit(1)
                    }
                    Text(note.createdAt, format: .dateTime.year().month().day()).dsMicroLabel()
                    Spacer()
                    Button(intent: ShuffleNoteIntent()) {
                        Image(systemName: "shuffle")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(DS.Color.onAccent)
                            .padding(7)
                            .background(DS.Color.accent, in: .circle)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private static func shortDate(_ date: Date) -> String {
        date.formatted(.dateTime.month(.defaultDigits).day())
    }

    private var emptyBody: some View {
        VStack(spacing: DS.Space.xs) {
            Image(systemName: "text.page").font(.title3).foregroundStyle(DS.Color.inkTertiary)
            if let scope = entry.scope {
                Text(scope).dsMicroLabel(DS.Color.accent).lineLimit(1)
                Text("該当するメモがありません").font(.caption.weight(.semibold)).foregroundStyle(DS.Color.ink)
            } else {
                Text("メモがありません").font(.caption.weight(.semibold)).foregroundStyle(DS.Color.ink)
                Text("アプリで追加してください").dsMicroLabel()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .multilineTextAlignment(.center)
    }
}

#Preview("Small", as: .systemSmall) {
    RandomNoteWidget()
} timeline: {
    NoteEntry(date: .now, note: .placeholder)
}

#Preview("Medium", as: .systemMedium) {
    RandomNoteWidget()
} timeline: {
    NoteEntry(date: .now, note: .placeholder)
    NoteEntry(date: .now, note: nil, scope: "哲学史")
}
