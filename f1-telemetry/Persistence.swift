import Foundation
import SwiftData

@MainActor
struct PersistenceController {
    static let shared = PersistenceController()
    let modelContainer: ModelContainer
    private init(inMemory: Bool = false) {
        let schema = Schema([RaceSession.self, LapSummary.self])
        let config = ModelConfiguration(cloudKitDatabase: .private("iCloud.com.aguilarcarboni.f1-telemetry"))
        modelContainer = try! ModelContainer(for: schema, configurations: [config])
        if inMemory {
            modelContainer.mainContext.autosaveEnabled = false
        }
    }
}
