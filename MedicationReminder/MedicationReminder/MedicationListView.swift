import SwiftUI
import SwiftData

struct MedicationListView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = MedicationListViewModel()

    var body: some View {
        List {
            ForEach(viewModel.items) { item in
                NavigationLink {
                    Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                } label: {
                    Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                }
            }
            .onDelete(perform: deleteItems)
        }
        .toolbar {
#if os(iOS)
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
#endif
            ToolbarItem {
                Button(action: addItem) {
                    Label("Add Item", systemImage: "plus")
                }
            }
        }
        .navigationTitle("要吃的药")
        .onAppear {
            viewModel.configure(modelContext: modelContext)
        }
    }

    private func addItem() {
        withAnimation {
            viewModel.addItem()
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            viewModel.deleteItems(at: offsets)
        }
    }
}

