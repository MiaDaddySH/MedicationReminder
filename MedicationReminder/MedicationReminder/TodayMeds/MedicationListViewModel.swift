import Foundation
import Combine
import SwiftUI
import SwiftData
import UserNotifications

@MainActor
final class MedicationListViewModel: ObservableObject {
    @Published var items: [Item] = []
    private var modelContext: ModelContext?

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchItems()
    }

    func fetchItems() {
        guard let modelContext else { return }
        let descriptor = FetchDescriptor<Item>(sortBy: [SortDescriptor(\.timestamp)])
        do {
            items = try modelContext.fetch(descriptor)
        } catch {
            items = []
        }
    }

    func addMedication(name: String, date: Date, time: Date, amount: String) {
        guard let modelContext else { return }
        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: time)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        let scheduledDate = Calendar.current.date(from: components) ?? date
        let newItem = Item(timestamp: scheduledDate, name: name, amount: amount)
        modelContext.insert(newItem)
        try? modelContext.save()
        scheduleNotification(for: newItem)
        fetchItems()
    }

    func deleteItems(at offsets: IndexSet) {
        guard let modelContext else { return }
        for index in offsets {
            let item = items[index]
            modelContext.delete(item)
        }
        try? modelContext.save()
        fetchItems()
    }

    func deleteItems(_ itemsToDelete: [Item]) {
        guard let modelContext else { return }
        for item in itemsToDelete {
            modelContext.delete(item)
        }
        try? modelContext.save()
        fetchItems()
    }

    func toggleCompletion(for item: Item) {
        guard let modelContext else { return }
        item.isCompleted.toggle()
        try? modelContext.save()
        fetchItems()
    }

    private func scheduleNotification(for item: Item) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
                return
            }

            let content = UNMutableNotificationContent()
            content.title = item.name
            if item.amount.isEmpty {
                content.body = "该服药了"
            } else {
                content.body = "该服药了，剂量：\(item.amount)"
            }
            content.sound = .default

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: item.timestamp
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let identifier = "med-\(item.name)-\(item.timestamp.timeIntervalSince1970)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            center.add(request)
        }
    }
}
