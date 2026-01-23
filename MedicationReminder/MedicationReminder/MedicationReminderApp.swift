//
//  MedicationReminderApp.swift
//  MedicationReminder
//
//  Created by Yuangang Sheng on 15.01.26.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct MedicationReminderApp: App {
    init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            Medication.self,
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
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
