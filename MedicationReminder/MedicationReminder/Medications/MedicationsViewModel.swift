import Foundation
import Combine
import SwiftData

@MainActor
final class MedicationsViewModel: ObservableObject {
    @Published var medications: [Medication] = []
    private var modelContext: ModelContext?

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchMedications()
        if medications.isEmpty {
            seedBuiltinMedications()
            fetchMedications()
        }
    }

    func fetchMedications() {
        guard let modelContext else { return }
        let descriptor = FetchDescriptor<Medication>(
            sortBy: [SortDescriptor(\.category), SortDescriptor(\.name)]
        )
        do {
            medications = try modelContext.fetch(descriptor)
        } catch {
            medications = []
        }
    }

    func addMedication(
        name: String,
        genericName: String,
        category: String,
        form: String,
        strength: String,
        notes: String
    ) {
        guard let modelContext else { return }
        let newMedication = Medication(
            name: name,
            genericName: genericName,
            category: category,
            form: form,
            strength: strength,
            notes: notes,
            isBuiltin: false
        )
        modelContext.insert(newMedication)
        try? modelContext.save()
        fetchMedications()
    }

    func deleteMedications(at offsets: IndexSet) {
        guard let modelContext else { return }
        for index in offsets {
            let medication = medications[index]
            modelContext.delete(medication)
        }
        try? modelContext.save()
        fetchMedications()
    }

    private func seedBuiltinMedications() {
        guard let modelContext else { return }

        let defaults: [(String, String, String, String, String, String)] = [
            ("氨氯地平", "Amlodipine", "高血压", "片剂", "5 mg", "常用降压药"),
            ("缬沙坦", "Valsartan", "高血压", "片剂", "80 mg", "ARB 类降压药"),
            ("阿司匹林肠溶片", "Aspirin", "心血管", "片剂", "100 mg", "心梗、脑梗二级预防常用药"),
            ("他汀类降脂药", "Atorvastatin", "心血管", "片剂", "10 mg", "降脂常用药"),
            ("二甲双胍", "Metformin", "糖尿病", "片剂", "500 mg", "2 型糖尿病基础用药"),
            ("格列美脲", "Glimepiride", "糖尿病", "片剂", "1 mg", "磺脲类降糖药"),
            ("对乙酰氨基酚", "Acetaminophen", "感冒发烧", "片剂", "500 mg", "解热镇痛常用药"),
            ("布洛芬", "Ibuprofen", "感冒发烧", "片剂", "200 mg", "解热镇痛、抗炎"),
            ("复方感冒药", "", "感冒发烧", "片剂", "", "多成分复方制剂"),
            ("奥美拉唑", "Omeprazole", "消化系统", "胶囊", "20 mg", "胃酸相关疾病常用药")
        ]

        for item in defaults {
            let medication = Medication(
                name: item.0,
                genericName: item.1,
                category: item.2,
                form: item.3,
                strength: item.4,
                notes: item.5,
                isBuiltin: true
            )
            modelContext.insert(medication)
        }

        try? modelContext.save()
    }
}
