import Foundation
import Combine
import SwiftData

@MainActor
final class MedicationsViewModel: ObservableObject {
    enum Mode {
        case favorites
        case catalog
    }

    @Published var medications: [Medication] = []
    private var modelContext: ModelContext?
    private let mode: Mode

    init(mode: Mode) {
        self.mode = mode
    }

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        if mode == .catalog {
            ensureBuiltinMedicationsSeededIfNeeded()
        }
        fetchMedications()
    }

    func fetchMedications() {
        guard let modelContext else { return }
        let descriptor: FetchDescriptor<Medication>
        switch mode {
        case .favorites:
            descriptor = FetchDescriptor<Medication>(
                predicate: #Predicate { $0.isFavorite == true },
                sortBy: [SortDescriptor(\.category), SortDescriptor(\.name)]
            )
        case .catalog:
            descriptor = FetchDescriptor<Medication>(
                sortBy: [SortDescriptor(\.category), SortDescriptor(\.name)]
            )
        }
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
        notes: String,
        isFavorite: Bool
    ) {
        guard let modelContext else { return }
        let newMedication = Medication(
            name: name,
            genericName: genericName,
            category: category,
            form: form,
            strength: strength,
            notes: notes,
            isBuiltin: false,
            isFavorite: isFavorite
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

    private func ensureBuiltinMedicationsSeededIfNeeded() {
        guard let modelContext else { return }

        let descriptor = FetchDescriptor<Medication>()
        if let existing = try? modelContext.fetch(descriptor), !existing.isEmpty {
            return
        }

        let defaults: [(String, String, String, String, String, String)] = [
            ("硝苯地平", "", "高血压", "片剂", "", ""),
            ("氨氯地平", "Amlodipine", "高血压", "片剂", "5 mg", "常用降压药"),
            ("非洛地平", "", "高血压", "片剂", "", ""),
            ("美托洛尔", "Metoprolol", "高血压", "片剂", "25 mg", ""),
            ("依那普利", "Enalapril", "高血压", "片剂", "10 mg", ""),
            ("贝那普利", "Benazepril", "高血压", "片剂", "10 mg", ""),
            ("福辛普利", "Fosinopril", "高血压", "片剂", "10 mg", ""),
            ("厄贝沙坦", "Irbesartan", "高血压", "片剂", "150 mg", ""),
            ("替米沙坦", "Telmisartan", "高血压", "片剂", "40 mg", ""),
            ("吲达帕胺", "Indapamide", "高血压", "片剂", "2.5 mg", ""),
            ("缬沙坦", "Valsartan", "高血压", "片剂", "80 mg", "ARB 类降压药"),
            ("辛伐他汀", "Simvastatin", "心血管", "片剂", "20 mg", "他汀类降脂药"),
            ("阿托伐他汀", "Atorvastatin", "心血管", "片剂", "10 mg", "他汀类降脂药"),
            ("瑞舒伐他汀", "Rosuvastatin", "心血管", "片剂", "10 mg", "他汀类降脂药"),
            ("非诺贝特", "Fenofibrate", "心血管", "片剂", "200 mg", "贝特类降脂药"),
            ("单硝酸异山梨酯", "Isosorbide mononitrate", "心血管", "片剂", "20 mg", ""),
            ("阿司匹林", "Aspirin", "心血管", "片剂", "100 mg", "心梗、脑梗二级预防常用药"),
            ("吡拉西坦", "Piracetam", "心血管", "片剂", "", ""),
            ("氯吡格雷", "Clopidogrel", "心血管", "片剂", "75 mg", "抗血小板"),
            ("曲美他嗪", "Trimetazidine", "心血管", "片剂", "20 mg", ""),
            ("稳心颗粒", "", "心血管", "颗粒剂", "", ""),
            ("心宝丸", "", "心血管", "丸剂", "", ""),
            ("复方丹参滴丸", "", "心血管", "滴丸", "", ""),
            ("心血康胶囊", "", "心血管", "胶囊", "", ""),
            ("速效救心丸", "", "心血管", "丸剂", "", ""),
            ("辅酶Q10胶囊", "Coenzyme Q10", "心血管", "胶囊", "", ""),
            ("丹参川芎嗪注射液", "", "心血管", "注射剂", "", ""),
            ("丹红注射液", "", "心血管", "注射剂", "", ""),
            ("舒血宁注射液", "", "心血管", "注射剂", "", ""),
            ("门冬胰岛素", "", "糖尿病", "注射剂", "", "速效胰岛素"),
            ("甘精胰岛素", "", "糖尿病", "注射剂", "", "长效胰岛素"),
            ("阿卡波糖", "Acarbose", "糖尿病", "片剂", "50 mg", ""),
            ("二甲双胍", "Metformin", "糖尿病", "片剂", "500 mg", "2 型糖尿病基础用药"),
            ("格列吡嗪", "Glipizide", "糖尿病", "片剂", "5 mg", "磺脲类降糖药"),
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
