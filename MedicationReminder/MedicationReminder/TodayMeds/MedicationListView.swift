import SwiftUI
import SwiftData

struct MedicationListView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = MedicationListViewModel()
    @State private var selectedDate = Date()
    @State private var isShowingDatePicker = false
    @State private var isPresentingNewMedicationFlow = false

    private var titleLine1: String {
        if Calendar.current.isDateInToday(selectedDate) {
            return "今天"
        } else {
            return weekdayString(for: selectedDate)
        }
    }

    private var titleLine2: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: selectedDate)
    }

    var body: some View {
        List {
            ForEach(itemsForSelectedDate) { item in
                NavigationLink {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.name)
                            .font(.headline)
                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .shortened))
                        Text("剂量：\(item.amount)")
                            .foregroundStyle(.secondary)
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name)
                                .foregroundStyle(item.isCompleted ? .secondary : .primary)
                            Text(item.timestamp, format: Date.FormatStyle(time: .shortened))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            viewModel.toggleCompletion(for: item)
                        } label: {
                            Image(systemName: item.isCompleted ? "face.smiling.fill" : "face.smiling")
                                .foregroundStyle(item.isCompleted ? .green : .secondary)
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
            .onDelete(perform: deleteItems)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Button(action: { isShowingDatePicker = true }) {
                    VStack(spacing: 2) {
                        Text(titleLine1)
                            .font(.headline)
                        Text(titleLine2)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: 180)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .buttonStyle(.plain)
            }
            ToolbarItem {
                Button {
                    isPresentingNewMedicationFlow = true
                } label: {
                    Label("Add Item", systemImage: "plus")
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingDatePicker) {
            NavigationStack {
                VStack {
                    DatePicker(
                        "",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    Button("回到今天") {
                        selectedDate = Date()
                    }
                    .padding(.top, 8)
                    .opacity(Calendar.current.isDateInToday(selectedDate) ? 0 : 1)
                    .allowsHitTesting(!Calendar.current.isDateInToday(selectedDate))
                }
                .padding()
                .navigationTitle("选择日期")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("取消") {
                            isShowingDatePicker = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("完成") {
                            isShowingDatePicker = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $isPresentingNewMedicationFlow) {
            NewMedicationFlow(
                viewModel: viewModel,
                isPresented: $isPresentingNewMedicationFlow,
                initialDate: selectedDate
            )
        }
        .onAppear {
            viewModel.configure(modelContext: modelContext)
        }
    }

    private var itemsForSelectedDate: [Item] {
        viewModel.items.filter { item in
            Calendar.current.isDate(item.timestamp, inSameDayAs: selectedDate)
        }
    }

    private func weekdayString(for date: Date) -> String {
        let weekday = Calendar.current.component(.weekday, from: date)
        switch weekday {
        case 1: return "星期日"
        case 2: return "星期一"
        case 3: return "星期二"
        case 4: return "星期三"
        case 5: return "星期四"
        case 6: return "星期五"
        case 7: return "星期六"
        default: return ""
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            let itemsToDelete = offsets.map { itemsForSelectedDate[$0] }
            viewModel.deleteItems(itemsToDelete)
        }
    }
}
