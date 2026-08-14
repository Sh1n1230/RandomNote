import SwiftUI
import SwiftData
import WidgetKit

/// 起動した瞬間にランダムな1件が目に入るメイン画面
struct RandomNoteRootView: View {
    @Query(filter: #Predicate<Note> { $0.isArchived == false }, sort: \Note.createdAt, order: .reverse)
    private var notes: [Note]
    /// シャッフル対象のカテゴリ。空文字はすべて。次の起動でも同じ範囲を引けるよう App Group に残す。
    @State private var scopeTag = AppGroup.defaults.string(forKey: AppGroup.scopeTagKey) ?? ""
    @State private var currentID: UUID?
    @State private var isEditorPresented = false
    @State private var path: [Route] = []

    private enum Route: Hashable { case list, prompt }

    /// 現在の絞り込みを適用したメモ。カテゴリが消えていたら黙って全件に戻す。
    private var scopedNotes: [Note] {
        guard !scopeTag.isEmpty else { return notes }
        let matched = notes.filter { $0.tags.contains(scopeTag) }
        return matched.isEmpty ? notes : matched
    }

    private var currentNote: Note? {
        scopedNotes.first { $0.id == currentID } ?? scopedNotes.first
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                DS.Color.canvas.ignoresSafeArea()
                if notes.isEmpty {
                    emptyState
                } else {
                    content
                }
            }
            .navigationTitle("RandomNote")
            .navigationBarTitleDisplayMode(.inline)
            .tint(DS.Color.accent)
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .list: NoteListView()
                case .prompt: ImportPromptView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink(value: Route.list) { Label("一覧", systemImage: "list.bullet") }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(value: Route.prompt) { Label("AI用プロンプト", systemImage: "sparkles") }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { isEditorPresented = true } label: { Label("追加", systemImage: "plus") }
                }
            }
            .sheet(isPresented: $isEditorPresented) { NoteEditorView(note: nil) }
            .onAppear(perform: shuffleIfNeeded)
            .onOpenURL(perform: handleDeepLink)
        }
    }

    private var content: some View {
        ScrollView {
            if let note = currentNote {
                NoteCardView(note: note)
                    .id(note.id)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.96)),
                        removal: .opacity
                    ))
                    .padding(DS.Space.screenMargin)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        // 操作系は下端に固定する。縦スクロールと高さを取り合わせると、
        // チップが描画されるのにタップが下のボタンへ抜ける事故が起きる。
        .safeAreaInset(edge: .bottom, spacing: 0) { controls }
    }

    private var controls: some View {
        VStack(spacing: DS.Space.md) {
            scopeBar
            Button(action: shuffle) {
                Label("別のメモを表示", systemImage: "shuffle")
            }
            .buttonStyle(.dsPrimary)
            .disabled(scopedNotes.count < 2)
            .opacity(scopedNotes.count < 2 ? 0.4 : 1)
        }
        .padding(DS.Space.screenMargin)
        .background(DS.Color.canvas)
    }

    /// どのカテゴリから引くかを選ぶ列。シャッフルボタンの直上に置き、「何を / 引く」で一組に見せる。
    /// 横スクロールは入れ子にするとタップが下のボタンへ抜けるため、折り返しで並べる。
    @ViewBuilder private var scopeBar: some View {
        let tags = notes.usedTags
        if !tags.isEmpty {
            FlowLayout(spacing: DS.Space.sm) {
                Button { setScope("") } label: {
                    DSChip(title: "すべて", isSelected: scopeTag.isEmpty)
                }
                ForEach(tags, id: \.self) { tag in
                    Button { setScope(tag) } label: {
                        DSChip(title: tag, isSelected: scopeTag == tag)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var emptyState: some View {
        VStack(spacing: DS.Space.md) {
            Text("まだメモがありません").dsMicroLabel()
            Text("推敲したメモを追加すると、\n起動するたびに1件ずつ目に入ります。")
                .dsTitle()
                .multilineTextAlignment(.center)
                .padding(.bottom, DS.Space.md)
            Button("メモを追加") { isEditorPresented = true }
                .buttonStyle(.dsPrimary)
                .frame(maxWidth: 240)
            NavigationLink(value: Route.prompt) { Text("AI用プロンプトを見る") }
                .buttonStyle(.dsSecondary)
        }
        .padding(DS.Space.screenMargin)
    }

    private func setScope(_ tag: String) {
        let next = (scopeTag == tag) ? "" : tag
        AppGroup.defaults.set(next, forKey: AppGroup.scopeTagKey)
        withAnimation(DS.Motion.standard) {
            scopeTag = next
            // 絞り込みを変えたら、その範囲の中から引き直す
            let candidates = next.isEmpty ? notes : notes.filter { $0.tags.contains(next) }
            if !candidates.contains(where: { $0.id == currentID }) {
                currentID = candidates.randomElement()?.id
            }
        }
    }

    private func shuffleIfNeeded() {
        guard currentID == nil || currentNote == nil else { return }
        currentID = scopedNotes.randomElement()?.id
    }

    private func shuffle() {
        withAnimation(DS.Motion.standard) {
            currentID = scopedNotes.randomNote(excluding: currentID)?.id
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// randomnote://note/<uuid> — ウィジェットのタップから該当メモを開く。
    /// 前回開いていた画面や絞り込みが残っていてもそのメモが見えるよう、すべて解除してから差し替える。
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == AppGroup.urlScheme, url.host == "note",
              let id = UUID(uuidString: url.lastPathComponent) else { return }
        isEditorPresented = false
        path.removeAll()
        AppGroup.defaults.set("", forKey: AppGroup.scopeTagKey)
        withAnimation(DS.Motion.standard) {
            scopeTag = ""
            currentID = id
        }
    }
}
