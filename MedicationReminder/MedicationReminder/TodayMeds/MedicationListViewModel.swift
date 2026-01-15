import Foundation
import Combine
import SwiftUI
import SwiftData

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
}
