import Foundation
import Combine
import SwiftData

enum MedicationCategory {
    static let hypertension = "高血压"
    static let diabetes = "糖尿病"
    static let cardiovascular = "心血管"
    static let hyperlipidemia = "高血脂"
    static let hyperuricemia = "高尿酸"
    static let coldFever = "感冒发烧"
    static let respiratory = "呼吸系统"
    static let digestive = "消化系统"
    static let analgesic = "镇痛解热"
    static let antiInfection = "抗感染"
    static let dermatology = "皮肤用药"
    static let neuroPsycho = "精神与睡眠"
    static let others = "其他药物"

    static let all: [String] = [
        hypertension,
        diabetes,
        cardiovascular,
        hyperlipidemia,
        hyperuricemia,
        coldFever,
        respiratory,
        digestive,
        analgesic,
        antiInfection,
        dermatology,
        neuroPsycho,
        others
    ]
}

enum MedicationForm {
    static let tablet = "片剂"
    static let capsule = "胶囊"
    static let pill = "丸剂"
    static let droppingPill = "滴丸"
    static let granules = "颗粒剂"
    static let oralSolution = "口服液"
    static let syrup = "糖浆"
    static let suspension = "混悬液"
    static let injection = "注射剂"
    static let spray = "喷雾剂"
    static let eyeDrops = "滴眼液"
    static let nasalDrops = "滴鼻液"
    static let ointment = "外用软膏"
    static let patch = "贴剂"
    static let suppository = "栓剂"

    static let all: [String] = [
        tablet,
        capsule,
        pill,
        droppingPill,
        granules,
        oralSolution,
        syrup,
        suspension,
        injection,
        spray,
        eyeDrops,
        nasalDrops,
        ointment,
        patch,
        suppository
    ]
}

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

    func deleteMedications(_ medicationsToDelete: [Medication]) {
        guard let modelContext else { return }
        for medication in medicationsToDelete {
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
            ("硝苯地平", "", MedicationCategory.hypertension, MedicationForm.tablet, "", ""),
            ("氨氯地平", "Amlodipine", MedicationCategory.hypertension, MedicationForm.tablet, "5 mg", "常用降压药"),
            ("非洛地平", "", MedicationCategory.hypertension, MedicationForm.tablet, "", ""),
            ("美托洛尔", "Metoprolol", MedicationCategory.hypertension, MedicationForm.tablet, "25 mg", ""),
            ("依那普利", "Enalapril", MedicationCategory.hypertension, MedicationForm.tablet, "10 mg", ""),
            ("贝那普利", "Benazepril", MedicationCategory.hypertension, MedicationForm.tablet, "10 mg", ""),
            ("福辛普利", "Fosinopril", MedicationCategory.hypertension, MedicationForm.tablet, "10 mg", ""),
            ("厄贝沙坦", "Irbesartan", MedicationCategory.hypertension, MedicationForm.tablet, "150 mg", ""),
            ("替米沙坦", "Telmisartan", MedicationCategory.hypertension, MedicationForm.tablet, "40 mg", ""),
            ("吲达帕胺", "Indapamide", MedicationCategory.hypertension, MedicationForm.tablet, "2.5 mg", ""),
            ("缬沙坦", "Valsartan", MedicationCategory.hypertension, MedicationForm.tablet, "80 mg", "ARB 类降压药"),
            ("辛伐他汀", "Simvastatin", MedicationCategory.hyperlipidemia, MedicationForm.tablet, "20 mg", "他汀类降脂药"),
            ("阿托伐他汀", "Atorvastatin", MedicationCategory.hyperlipidemia, MedicationForm.tablet, "10 mg", "他汀类降脂药"),
            ("瑞舒伐他汀", "Rosuvastatin", MedicationCategory.hyperlipidemia, MedicationForm.tablet, "10 mg", "他汀类降脂药"),
            ("普伐他汀", "Pravastatin", MedicationCategory.hyperlipidemia, MedicationForm.tablet, "20 mg", "他汀类降脂药"),
            ("非诺贝特", "Fenofibrate", MedicationCategory.hyperlipidemia, MedicationForm.tablet, "200 mg", "贝特类降脂药"),
            ("依折麦布", "Ezetimibe", MedicationCategory.hyperlipidemia, MedicationForm.tablet, "10 mg", "胆固醇吸收抑制剂"),
            ("单硝酸异山梨酯", "Isosorbide mononitrate", MedicationCategory.cardiovascular, MedicationForm.tablet, "20 mg", ""),
            ("阿司匹林", "Aspirin", MedicationCategory.cardiovascular, MedicationForm.tablet, "100 mg", "心梗、脑梗二级预防常用药"),
            ("吡拉西坦", "Piracetam", MedicationCategory.cardiovascular, MedicationForm.tablet, "", ""),
            ("氯吡格雷", "Clopidogrel", MedicationCategory.cardiovascular, MedicationForm.tablet, "75 mg", "抗血小板"),
            ("曲美他嗪", "Trimetazidine", MedicationCategory.cardiovascular, MedicationForm.tablet, "20 mg", ""),
            ("稳心颗粒", "", MedicationCategory.cardiovascular, MedicationForm.granules, "", ""),
            ("心宝丸", "", MedicationCategory.cardiovascular, MedicationForm.pill, "", ""),
            ("复方丹参滴丸", "", MedicationCategory.cardiovascular, MedicationForm.droppingPill, "", ""),
            ("心血康胶囊", "", MedicationCategory.cardiovascular, MedicationForm.capsule, "", ""),
            ("速效救心丸", "", MedicationCategory.cardiovascular, MedicationForm.pill, "", ""),
            ("辅酶Q10胶囊", "Coenzyme Q10", MedicationCategory.cardiovascular, MedicationForm.capsule, "", ""),
            ("丹参川芎嗪注射液", "", MedicationCategory.cardiovascular, MedicationForm.injection, "", ""),
            ("丹红注射液", "", MedicationCategory.cardiovascular, MedicationForm.injection, "", ""),
            ("舒血宁注射液", "", MedicationCategory.cardiovascular, MedicationForm.injection, "", ""),
            ("门冬胰岛素", "", MedicationCategory.diabetes, MedicationForm.injection, "", "速效胰岛素"),
            ("甘精胰岛素", "", MedicationCategory.diabetes, MedicationForm.injection, "", "长效胰岛素"),
            ("阿卡波糖", "Acarbose", MedicationCategory.diabetes, MedicationForm.tablet, "50 mg", ""),
            ("二甲双胍", "Metformin", MedicationCategory.diabetes, MedicationForm.tablet, "500 mg", "2 型糖尿病基础用药"),
            ("格列吡嗪", "Glipizide", MedicationCategory.diabetes, MedicationForm.tablet, "5 mg", "磺脲类降糖药"),
            ("格列美脲", "Glimepiride", MedicationCategory.diabetes, MedicationForm.tablet, "1 mg", "磺脲类降糖药"),
            ("别嘌醇", "Allopurinol", MedicationCategory.hyperuricemia, MedicationForm.tablet, "100 mg", "降低尿酸的常用药"),
            ("非布司他", "Febuxostat", MedicationCategory.hyperuricemia, MedicationForm.tablet, "40 mg", "黄嘌呤氧化酶抑制剂"),
            ("苯溴马隆", "Benzbromarone", MedicationCategory.hyperuricemia, MedicationForm.tablet, "50 mg", "促进尿酸排泄"),
            ("对乙酰氨基酚", "Acetaminophen", MedicationCategory.coldFever, MedicationForm.tablet, "500 mg", "解热镇痛常用药"),
            ("布洛芬", "Ibuprofen", MedicationCategory.coldFever, MedicationForm.tablet, "200 mg", "解热镇痛、抗炎"),
            ("复方感冒药", "", MedicationCategory.coldFever, MedicationForm.tablet, "", "多成分复方制剂"),
            ("奥美拉唑", "Omeprazole", MedicationCategory.digestive, MedicationForm.capsule, "20 mg", "胃酸相关疾病常用药")
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
