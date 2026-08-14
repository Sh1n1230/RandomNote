import SwiftUI
import SwiftData
import WidgetKit

struct NoteListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Note.createdAt, order: .reverse) private var allNotes: [Note]
    @State private var showsArchived = false
    @State private var isEditorPresented = false
    @State private var selectedTag: String?

    private var scoped: [Note] { allNotes.filter { $0.isArchived == showsArchived } }
    private var notes: [Note] {
        guard let selectedTag else { return scoped }
        return scoped.filter { $0.tags.contains(selectedTag) }
    }

    var body: some View {
        List {
            Section {
                ForEach(notes) { note in
                    NavigationLink { NoteEditorView(note: note) } label: { row(note) }
                        .listRowBackground(DS.Color.surface)
                        .listRowSeparatorTint(DS.Color.border)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) { delete(note) } label: { Label("削除", systemImage: "trash") }
                        }
                        .swipeActions(edge: .leading) {
                            Button { toggleArchive(note) } label: {
                                Label(note.isArchived ? "戻す" : "アーカイブ",
                                      systemImage: note.isArchived ? "tray.and.arrow.up" : "archivebox")
                            }
                            .tint(DS.Color.highlight)
                        }
                }
            } header: {
                Text("\(notes.count) 件").dsMicroLabel()
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) { tagFilterBar }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(DS.Color.canvas)
        .overlay {
            if notes.isEmpty {
                Text(emptyMessage).dsCallout()
            }
        }
        .navigationTitle(showsArchived ? "アーカイブ" : "メモ一覧")
        .navigationBarTitleDisplayMode(.inline)
        .tint(DS.Color.accent)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { isEditorPresented = true } label: { Label("追加", systemImage: "plus") }
            }
            ToolbarItem(placement: .principal) {
                Picker("表示", selection: $showsArchived) {
                    Text("有効").tag(false)
                    Text("アーカイブ").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
        }
        .sheet(isPresented: $isEditorPresented) { NoteEditorView(note: nil) }
        .onChange(of: showsArchived) { selectedTag = nil }
    }

    /// カテゴリのフィルタ列。参考デザインのフィルターチップに対応する。
    @ViewBuilder private var tagFilterBar: some View {
        let tags = scoped.usedTags
        if !tags.isEmpty {
            ScrollView(.horizontal) {
                HStack(spacing: DS.Space.sm) {
                    Button { select(nil) } label: {
                        DSChip(title: "すべて", isSelected: selectedTag == nil)
                    }
                    ForEach(tags, id: \.self) { tag in
                        Button { select(tag) } label: {
                            DSChip(title: tag, isSelected: selectedTag == tag)
                        }
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, DS.Space.xl)
                .padding(.vertical, DS.Space.md)
            }
            .scrollIndicators(.hidden)
            .background(DS.Color.canvas)
        }
    }

    private var emptyMessage: String {
        if selectedTag != nil { return "このカテゴリのメモはありません" }
        return showsArchived ? "アーカイブは空です" : "メモがありません"
    }

    private func select(_ tag: String?) {
        withAnimation(DS.Motion.quick) { selectedTag = selectedTag == tag ? nil : tag }
    }

    private func row(_ note: Note) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            HStack(spacing: DS.Space.sm) {
                Text(note.createdAt, format: .dateTime.year().month().day()).dsMicroLabel()
                if let tag = note.tags.first {
                    Text(tag).dsMicroLabel(DS.Color.accent)
                }
                if note.tags.count > 1 {
                    Text("+\(note.tags.count - 1)").dsMicroLabel()
                }
            }
            Text(note.displayTitle).dsHeadline().lineLimit(1)
            Text(note.compactContent)
                .font(.subheadline)
                .foregroundStyle(DS.Color.inkSecondary)
                .lineLimit(2)
        }
        .padding(.vertical, DS.Space.sm)
    }

    private func delete(_ note: Note) {
        context.delete(note)
        save()
    }

    private func toggleArchive(_ note: Note) {
        note.isArchived.toggle()
        save()
    }

    private func save() {
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
