import SwiftUI

struct JoiefullTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
    }
}
