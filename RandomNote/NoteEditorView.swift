import SwiftUI
import SwiftData
import WidgetKit

/// note が nil なら新規作成、渡されていれば編集
struct NoteEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Note.createdAt, order: .reverse) private var allNotes: [Note]
    let note: Note?
    @State private var title = ""
    @State private var content = ""
    @State private var tags: [String] = []
    @State private var newTag = ""
    @FocusState private var isContentFocused: Bool

    private var isNew: Bool { note == nil }
    private var canSave: Bool {
        !(title + content).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    /// まだ付けていない既存カテゴリ。毎回打ち直さずに済むよう候補として出す。
    private var suggestions: [String] {
        allNotes.usedTags.filter { !tags.contains($0) }
    }

    var body: some View {
        Group {
            if isNew { NavigationStack { form } } else { form }
        }
        .onAppear {
            guard let note else { return }
            title = note.title
            content = note.content
            tags = note.tags
        }
    }

    private var form: some View {
        Form {
            Section {
                TextField("タイトル", text: $title, axis: .vertical)
                    .dsHeadline()
                    .lineLimit(1...3)
            } header: {
                Text("タイトル").dsMicroLabel()
            }
            .listRowBackground(DS.Color.surface)
            tagSection
            Section {
                TextEditor(text: $content)
                    .dsBody()
                    .frame(minHeight: 220)
                    .focused($isContentFocused)
                    .scrollContentBackground(.hidden)
            } header: {
                Text("本文").dsMicroLabel()
            }
            .listRowBackground(DS.Color.surface)
            if let note, !isNew {
                Section {
                    Button(note.isArchived ? "アーカイブから戻す" : "アーカイブする") { toggleArchive(note) }
                    Button("削除", role: .destructive) { delete(note) }
                } footer: {
                    Text("アーカイブしたメモはランダム表示とウィジェットの対象外になります。").dsCaption()
                }
                .listRowBackground(DS.Color.surface)
            }
        }
        .scrollContentBackground(.hidden)
        .background(DS.Color.canvas)
        .navigationTitle(isNew ? "新しいメモ" : "メモを編集")
        .navigationBarTitleDisplayMode(.inline)
        .tint(DS.Color.accent)
        .toolbar {
            if isNew {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") { save() }.disabled(!canSave)
            }
        }
    }

    private var tagSection: some View {
        Section {
            if !tags.isEmpty {
                FlowLayout {
                    ForEach(tags, id: \.self) { tag in
                        Button { remove(tag) } label: {
                            DSChip(title: tag, isSelected: true, systemImage: "xmark")
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, DS.Space.xs)
            }
            TextField("カテゴリを追加（例: 講演、哲学史）", text: $newTag)
                .font(.subheadline)
                .submitLabel(.done)
                .onSubmit { add(newTag) }
            if !suggestions.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: DS.Space.sm) {
                        ForEach(suggestions, id: \.self) { tag in
                            Button { add(tag) } label: { DSChip(title: tag) }
                                .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, DS.Space.xs)
                }
                .scrollIndicators(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: DS.Space.lg, bottom: 0, trailing: 0))
            }
        } header: {
            Text("カテゴリ").dsMicroLabel()
        } footer: {
            Text("「講演」のような出所と「哲学史」のような主題は別の軸なので、複数付けられます。").dsCaption()
        }
        .listRowBackground(DS.Color.surface)
    }

    private func add(_ raw: String) {
        guard let tag = Note.normalizedTag(raw) else { return }
        withAnimation(DS.Motion.quick) {
            if !tags.contains(tag) { tags.append(tag) }
            newTag = ""
        }
    }

    private func remove(_ tag: String) {
        withAnimation(DS.Motion.quick) { tags.removeAll { $0 == tag } }
    }

    private func save() {
        // 入力欄に打ちかけのカテゴリが残っていても取りこぼさない
        var finalTags = tags
        if let pending = Note.normalizedTag(newTag), !finalTags.contains(pending) {
            finalTags.append(pending)
        }
        if let note {
            note.title = title
            note.content = content
            note.tags = finalTags
        } else {
            context.insert(Note(title: title, content: content, tags: finalTags))
        }
        commit()
    }

    private func toggleArchive(_ note: Note) {
        note.isArchived.toggle()
        commit()
    }

    private func delete(_ note: Note) {
        context.delete(note)
        commit()
    }

    private func commit() {
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }
}
