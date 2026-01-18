import SwiftUI
import SwiftData

struct NewMedicationFlow: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var viewModel: MedicationListViewModel
    @Binding var isPresented: Bool
    @State private var step: Step = .selectMedication
    @State private var name: String = ""
    @State private var date: Date
    @State private var time: Date = Date()
    @State private var amount: String = ""
    @State private var medications: [Medication] = []
    @State private var searchText: String = ""
    @State private var isPresentingAddMedication = false

    enum Step {
        case selectMedication
        case schedule
    }

    init(viewModel: MedicationListViewModel, isPresented: Binding<Bool>, initialDate: Date) {
        self.viewModel = viewModel
        _isPresented = isPresented
        _date = State(initialValue: initialDate)
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(step == .selectMedication ? "选择药物" : "设置服药时间")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("取消") {
                            isPresented = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        if step == .schedule {
                            Button("保存") {
                                save()
                            }
                            .disabled(name.isEmpty || amount.isEmpty)
                        }
                    }
                }
                .onAppear {
                    loadMedications()
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

    @ViewBuilder
    private var content: some View {
        switch step {
        case .selectMedication:
            Form {
                Section("常用药物目录") {
                    if medications.isEmpty {
                        Text("暂无常用药物，请先在“药物”页添加")
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
                    Button("使用这个药名添加药物") {
                        useCustomMedication()
                    }
                    .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        case .schedule:
            Form {
                Section("药物") {
                    Text(name)
                }
                Section("日期") {
                    DatePicker(
                        "日期",
                        selection: $date,
                        displayedComponents: .date
                    )
                }
                Section("时间") {
                    DatePicker(
                        "时间",
                        selection: $time,
                        displayedComponents: .hourAndMinute
                    )
                }
                Section("剂量") {
                    TextField("例如：1 片、5 ml", text: $amount)
                }
            }
        }
    }

    private func save() {
        viewModel.addMedication(name: name, date: date, time: time, amount: amount)
        isPresented = false
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
        name = medication.name
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            step = .schedule
        }
    }

    private func useCustomMedication() {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isPresentingAddMedication = true
    }

    private func ensureMedicationExists(named: String) {
        let trimmed = named.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let existing = medications.first(where: { $0.name == trimmed }) {
            existing.isFavorite = true
            try? modelContext.save()
            loadMedications()
            return
        }
        let medication = Medication(name: trimmed, isFavorite: true)
        modelContext.insert(medication)
        try? modelContext.save()
        loadMedications()
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
            self.name = trimmedName
            step = .schedule
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
        self.name = trimmedName
        step = .schedule
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
}

struct MedicationCategorySelectionView: View {
    let title: String
    let medications: [Medication]
    let onSelect: (Medication) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            ForEach(medications) { medication in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(medication.name)
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
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    onSelect(medication)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        dismiss()
                    }
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
