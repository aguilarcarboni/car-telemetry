//
//  f1_telemetryApp.swift
//  f1-telemetry
//
//  Created by Andrés on 9/10/2025.
//

import SwiftUI
import SwiftData

@main
struct f1_telemetryApp: App {
    private let persistence = PersistenceController.shared
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(persistence.modelContainer)
        }
    }
}
