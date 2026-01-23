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
            .navigationTitle(mode == .favorites ? "我的药" : "常用药物目录")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button {
                        isPresentingAddMedication = true
                    } label: {
                        Label(mode == .favorites ? "添加我的药" : "添加药物", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingAddMedication) {
                if mode == .favorites {
                    FavoriteMedicationSelectionView()
                } else {
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
                                isFavorite: false
                            )
                        }
                    )
                }
            }
            .onChange(of: isPresentingAddMedication) { newValue in
                if !newValue {
                    viewModel.fetchMedications()
                }
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

struct FavoriteMedicationSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var medications: [Medication] = []
    @State private var searchText: String = ""
    @State private var isPresentingAddMedication = false
    @State private var step: Step = .selectMedication
    @State private var selectedMedication: Medication?
    @State private var dosesPerDay: Int = 1
    @State private var intervalDays: Int = 1

    enum Step {
        case selectMedication
        case usage
    }

    private var filteredMedications: [Medication] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return medications
        }
        let lowercased = trimmed.lowercased()
        return medications.filter { medication in
            medication.name.lowercased().contains(lowercased) ||
            medication.genericName.lowercased().contains(lowercased) ||
            medication.category.lowercased().contains(lowercased)
        }
    }

    var body: some View {
        NavigationStack {
            switch step {
            case .selectMedication:
                selectionForm
                    .navigationTitle("添加我的药")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("取消") {
                                dismiss()
                            }
                        }
                    }
                    .onAppear {
                        loadMedications()
                    }
            case .usage:
                usageForm
                    .navigationTitle("设置用药方案")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("上一步") {
                                step = .selectMedication
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("完成") {
                                saveUsage()
                            }
                            .disabled(selectedMedication == nil)
                        }
                    }
            }
        }
        .sheet(isPresented: $isPresentingAddMedication) {
            AddMedicationView(
                isPresented: $isPresentingAddMedication,
                initialName: searchText.trimmingCharacters(in: .whitespacesAndNewlines),
                onSave: handleCustomMedicationSave
            )
        }
    }

    private var selectionForm: some View {
        Form {
            Section("常用药物目录") {
                if medications.isEmpty {
                    Text("暂无常用药物，请先在“常用药物目录”页添加")
                        .foregroundStyle(.secondary)
                } else {
                    let grouped = Dictionary(grouping: filteredMedications) { medication in
                        medication.category
                    }
                    let categories = grouped.keys.sorted()
                    ForEach(categories, id: \.self) { category in
                        let displayName = categoryDisplayName(for: category)
                        NavigationLink(displayName) {
                            MedicationCategorySelectionView(
                                title: displayName,
                                medications: grouped[category] ?? [],
                                onSelect: { medication in
                                    selectMedication(medication)
                                }
                            )
                        }
                    }
                }
            }
            Section("搜索或自定义") {
                TextField("药名", text: $searchText)
                Button("使用这个药名添加到“我的药”") {
                    useCustomMedication()
                }
                .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private var usageForm: some View {
        Form {
            if let medication = selectedMedication {
                Section("药物") {
                    Text(medication.name)
                }
            }
            Section("用药间隔") {
                Stepper("每 \(intervalDays) 天", value: $intervalDays, in: 1...30)
            }
            Section("每日次数") {
                Stepper("每天 \(dosesPerDay) 次", value: $dosesPerDay, in: 1...6)
            }
        }
    }

    private func loadMedications() {
        ensureBuiltinMedicationsSeeded()
        let descriptor = FetchDescriptor<Medication>(
            sortBy: [SortDescriptor(\.category), SortDescriptor(\.name)]
        )
        do {
            medications = try modelContext.fetch(descriptor)
        } catch {
            medications = []
        }
    }

    private func ensureBuiltinMedicationsSeeded() {
        let descriptor = FetchDescriptor<Medication>()
        if let existing = try? modelContext.fetch(descriptor), existing.isEmpty {
            let viewModel = MedicationsViewModel(mode: .catalog)
            viewModel.configure(modelContext: modelContext)
        }
    }

    private func selectMedication(_ medication: Medication) {
        medication.isFavorite = true
        try? modelContext.save()
        loadMedications()
        selectedMedication = medication
        dosesPerDay = max(1, medication.dosesPerDay)
        intervalDays = max(1, medication.intervalDays)
        step = .usage
    }

    private func useCustomMedication() {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isPresentingAddMedication = true
    }

    private func handleCustomMedicationSave(
        name: String,
        genericName: String,
        category: String,
        form: String,
        strength: String,
        notes: String
    ) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        if let existing = medications.first(where: { $0.name == trimmedName }) {
            existing.genericName = genericName
            existing.category = category
            existing.form = form
            existing.strength = strength
            existing.notes = notes
            existing.isFavorite = true
            try? modelContext.save()
            loadMedications()
            selectedMedication = existing
            dosesPerDay = max(1, existing.dosesPerDay)
            intervalDays = max(1, existing.intervalDays)
            step = .usage
            return
        }

        let medication = Medication(
            name: trimmedName,
            genericName: genericName,
            category: category,
            form: form,
            strength: strength,
            notes: notes,
            isBuiltin: false,
            isFavorite: true
        )
        modelContext.insert(medication)
        try? modelContext.save()
        loadMedications()
        selectedMedication = medication
        dosesPerDay = max(1, medication.dosesPerDay)
        intervalDays = max(1, medication.intervalDays)
        step = .usage
    }

    private func categoryDisplayName(for category: String) -> String {
        if category.isEmpty {
            return "其他药物"
        }
        if category == "高血压" {
            return "高血压药"
        }
        if category == "糖尿病" {
            return "糖尿病药"
        }
        return category
    }

    private func saveUsage() {
        guard let medication = selectedMedication else { return }
        medication.dosesPerDay = dosesPerDay
        medication.intervalDays = intervalDays
        try? modelContext.save()
        dismiss()
    }
}
