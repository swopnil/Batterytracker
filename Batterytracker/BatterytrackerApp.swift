//
//  BatterytrackerApp.swift
//  Batterytracker
//
//  Created by Swopnil Panday on 11/2/24.
//

import SwiftUI
import SwiftData

@main
struct BatterytrackerApp: App {
    init() {
            BackgroundManager.shared.registerBackgroundTask()
        }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
