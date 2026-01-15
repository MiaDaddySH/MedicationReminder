import SwiftUI

struct NewMedicationFlow: View {
    @ObservedObject var viewModel: MedicationListViewModel
    @Binding var isPresented: Bool
    @State private var step: Step = .selectMedication
    @State private var name: String = ""
    @State private var date: Date
    @State private var time: Date = Date()
    @State private var amount: String = ""

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
        }
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .selectMedication:
            Form {
                Section("药物") {
                    TextField("药名", text: $name)
                }
                Section {
                    Button("下一步") {
                        step = .schedule
                    }
                    .disabled(name.isEmpty)
                }
            }
        case .schedule:
            Form {
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
}

