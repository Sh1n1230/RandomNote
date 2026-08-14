import SwiftUI
import SwiftData

@main
struct RandomNoteApp: App {
    var body: some Scene {
        WindowGroup {
            RandomNoteRootView()
                .task { SampleData.seedIfNeeded(into: SharedStore.container) }
        }
        .modelContainer(SharedStore.container)
    }
}
