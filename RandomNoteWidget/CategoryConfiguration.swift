import AppIntents

/// ウィジェット設定で選べるカテゴリ。タグ名そのものをIDにする。
struct CategoryEntity: AppEntity {
    let id: String

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "カテゴリ")
    static let defaultQuery = CategoryQuery()

    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(id)") }
}

struct CategoryQuery: EntityQuery {
    /// 保存済みの設定を復元するだけなので、候補一覧と突き合わせない。
    /// ここで絞ると、ストアを読めなかったときに設定がnilに落ちて絞り込みが消える。
    func entities(for identifiers: [String]) async throws -> [CategoryEntity] {
        identifiers.map(CategoryEntity.init)
    }

    /// 設定画面のピッカーに並ぶ候補。アーカイブされていないメモから拾う。
    func suggestedEntities() async throws -> [CategoryEntity] {
        availableTags().map(CategoryEntity.init)
    }

    private func availableTags() -> [String] {
        NoteFetch.activeNotes(in: SharedStore.container).usedTags
    }
}

/// ウィジェットを長押し →「ウィジェットを編集」で表示するカテゴリを固定できる
struct SelectCategoryIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "カテゴリを選ぶ"
    static let description = IntentDescription("表示するメモをカテゴリで絞り込みます。未選択ならすべてのメモから引きます。")

    @Parameter(title: "カテゴリ")
    var category: CategoryEntity?

    init() {}

    init(category: CategoryEntity?) {
        self.category = category
    }
}
