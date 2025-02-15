import SwiftUI

struct MessageEditorView: View {
    @Environment(\.dismiss) private var dismiss
    
    var initialText: String = ""
    var initialSize: CGFloat = 32
    var initialWeight: Font.Weight = .regular
    var onSave: (String, CGFloat, Font.Weight) -> Void
    
    @State private var text: String = ""
    @State private var fontSize: CGFloat = 32
    @State private var fontWeight: Font.Weight = .regular
    
    init(
        initialText: String = "",
        initialSize: CGFloat = 32,
        initialWeight: Font.Weight = .regular,
        onSave: @escaping (String, CGFloat, Font.Weight) -> Void
    ) {
        self.initialText = initialText
        self.initialSize = initialSize
        self.initialWeight = initialWeight
        self.onSave = onSave
        
        // Initialize state
        _text = State(initialValue: initialText)
        _fontSize = State(initialValue: initialSize)
        _fontWeight = State(initialValue: initialWeight)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Preview") {
                    ZStack {
                        Color.black
                        Text(text.isEmpty ? "Preview" : text)
                            .font(.system(size: fontSize, weight: fontWeight))
                            .foregroundStyle(text.isEmpty ? .gray : .white)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Section("Text") {
                    TextField("Enter message", text: $text, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    VStack(alignment: .leading) {
                        Text("Size: \(Int(fontSize))pt")
                        Slider(value: $fontSize, in: 12...72) {
                            Text("Font Size")
                        }
                    }
                    
                    Picker("Weight", selection: $fontWeight) {
                        Text("Light").tag(Font.Weight.light)
                        Text("Regular").tag(Font.Weight.regular)
                        Text("Medium").tag(Font.Weight.medium)
                        Text("Bold").tag(Font.Weight.bold)
                    }
                }
            }
            .navigationTitle(initialText.isEmpty ? "New Message" : "Edit Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(text, fontSize, fontWeight)
                        dismiss()
                    }
                    .disabled(text.isEmpty)
                }
            }
        }
        .presentationDetents([.large])
    }
}

#Preview {
    MessageEditorView { _, _, _ in }
} 