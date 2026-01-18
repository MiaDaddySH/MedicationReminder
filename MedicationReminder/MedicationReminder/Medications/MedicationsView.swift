import SwiftUI
import SwiftData

struct MedicationsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = MedicationsViewModel()
    @State private var isPresentingAddMedication = false

    var body: some View {
        List {
            ForEach(viewModel.medications) { medication in
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
        .navigationTitle("药物")
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
                        notes: notes
                    )
                }
            )
        }
        .onAppear {
            viewModel.configure(modelContext: modelContext)
        }
    }

    private func deleteMedications(at offsets: IndexSet) {
        withAnimation {
            viewModel.deleteMedications(at: offsets)
        }
    }
}

