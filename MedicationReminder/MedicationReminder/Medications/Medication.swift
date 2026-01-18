import Foundation
import SwiftData

@Model
final class Medication {
    var name: String
    var genericName: String
    var category: String
    var form: String
    var strength: String
    var notes: String
    var isBuiltin: Bool
    var isFavorite: Bool

    init(
        name: String,
        genericName: String = "",
        category: String = "",
        form: String = "",
        strength: String = "",
        notes: String = "",
        isBuiltin: Bool = false,
        isFavorite: Bool = false
    ) {
        self.name = name
        self.genericName = genericName
        self.category = category
        self.form = form
        self.strength = strength
        self.notes = notes
        self.isBuiltin = isBuiltin
        self.isFavorite = isFavorite
    }
}
