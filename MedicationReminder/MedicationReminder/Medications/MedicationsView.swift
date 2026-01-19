import SwiftUI
import SwiftData

struct MedicationsView: View {
    private let mode: MedicationsViewModel.Mode

    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: MedicationsViewModel

    init(mode: MedicationsViewModel.Mode = .favorites) {
        self.mode = mode
        _viewModel = StateObject(wrappedValue: MedicationsViewModel(mode: mode))
    }
    @State private var isPresentingAddMedication = false
    @State private var searchText = ""

    private var filteredMedications: [Medication] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return viewModel.medications
        }
        return viewModel.medications.filter { medication in
            if medication.name.localizedCaseInsensitiveContains(trimmed) {
                return true
            }
            if !medication.genericName.isEmpty,
               medication.genericName.localizedCaseInsensitiveContains(trimmed) {
                return true
            }
            if !medication.category.isEmpty,
               medication.category.localizedCaseInsensitiveContains(trimmed) {
                return true
            }
            return false
        }
    }

    var body: some View {
        content
            .navigationTitle(mode == .favorites ? "我的常用药" : "常用药物目录")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
            ToolbarItem {
                Button {
                    isPresentingAddMedication = true
                } label: {
                    Label("添加药物", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingAddMedication) {
            AddMedicationView(
                isPresented: $isPresentingAddMedication,
                onSave: { name, genericName, category, form, strength, notes in
                    viewModel.addMedication(
                        name: name,
                        genericName: genericName,
                        category: category,
                        form: form,
                        strength: strength,
                        notes: notes,
                        isFavorite: mode == .favorites
                    )
                }
            )
        }
        .onAppear {
            viewModel.configure(modelContext: modelContext)
        }
    }

    @ViewBuilder
    private var content: some View {
        if mode == .favorites {
            listView
        } else {
            listView
                .searchable(
                    text: $searchText,
                    placement: .navigationBarDrawer(displayMode: .automatic),
                    prompt: "搜索药名或类别"
                )
        }
    }

    private var listView: some View {
        List {
            ForEach(filteredMedications) { medication in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(medication.name)
                            .font(.headline)
                        if !medication.genericName.isEmpty {
                            Text("(\(medication.genericName))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if !medication.category.isEmpty {
                        Text(medication.category)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 8) {
                        if !medication.form.isEmpty {
                            Text(medication.form)
                        }
                        if !medication.strength.isEmpty {
                            Text(medication.strength)
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    if !medication.notes.isEmpty {
                        Text(medication.notes)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            .onDelete(perform: deleteMedications)
        }
    }

    private func deleteMedications(at offsets: IndexSet) {
        withAnimation {
            let medicationsToDelete = offsets.map { filteredMedications[$0] }
            viewModel.deleteMedications(medicationsToDelete)
        }
    }
}
