import SwiftUI

struct AddMedicationView: View {
    @Binding var isPresented: Bool
    var onSave: (String, String, String, String, String, String) -> Void

    @State private var name: String = ""
    @State private var genericName: String = ""
    @State private var category: String = ""
    @State private var form: String = ""
    @State private var strength: String = ""
    @State private var notes: String = ""

    private let commonCategories = [
        "高血压",
        "心血管",
        "糖尿病",
        "感冒发烧",
        "消化系统"
    ]

    private let commonForms = [
        "片剂",
        "胶囊",
        "口服液",
        "注射剂"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("名称") {
                    TextField("药品名称（必填）", text: $name)
                }
                Section("通用名") {
                    TextField("例如：Amlodipine", text: $genericName)
                }
                Section("类别") {
                    Picker("类别", selection: $category) {
                        Text("自定义").tag("")
                        ForEach(commonCategories, id: \.self) { value in
                            Text(value).tag(value)
                        }
                    }
                    TextField("其他类别", text: $category)
                }
                Section("剂型与规格") {
                    Picker("剂型", selection: $form) {
                        Text("自定义").tag("")
                        ForEach(commonForms, id: \.self) { value in
                            Text(value).tag(value)
                        }
                    }
                    TextField("规格，例如 5 mg", text: $strength)
                }
                Section("备注") {
                    TextField("可记录用途、注意事项等", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("添加药物")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(name, genericName, category, form, strength, notes)
                        isPresented = false
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

