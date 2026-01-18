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
                        ForEach(filteredMedications) { medication in
                            Button {
                                selectMedication(medication)
                            } label: {
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
                            }
                        }
                    }
                }
                Section("搜索或自定义") {
                    TextField("药名", text: $searchText)
                    Button("使用上面的药名") {
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
        step = .schedule
    }

    private func useCustomMedication() {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        name = trimmed
        ensureMedicationExists(named: trimmed)
        step = .schedule
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
}
