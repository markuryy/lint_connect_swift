import SwiftUI

struct ContentPadding: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 16)
    }
}

extension View {
    func contentPadding() -> some View {
        modifier(ContentPadding())
    }
}
