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
                Section("我的药") {
                    if medications.isEmpty {
                        Text("暂无“我的药”，请先在“我的药”页添加")
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
                Section("搜索我的药") {
                    TextField("药名", text: $searchText)
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
            predicate: #Predicate { $0.isFavorite == true },
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
        name = medication.name
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            step = .schedule
        }
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
