import SwiftUI

struct MoreView: View {
    var body: some View {
        List {
            Section {
                NavigationLink("常用药物目录") {
                    MedicationsView(mode: .catalog)
                }
            }
            Section("免责声明") {
                Text("本应用仅用于个人用药记录与提醒，不构成任何医疗建议或诊断。用药请遵循专业医生或药师的指导，如有不适请及时就医。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("更多")
    }
}
