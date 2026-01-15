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

    func addItem() {
        guard let modelContext else { return }
        let newItem = Item(timestamp: Date())
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
