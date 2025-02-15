import SwiftUI

struct MessageArrayView: View {
    @ObservedObject var viewModel: MessageArrayViewModel
    @Environment(\.isEnabled) private var isEnabled
    
    var body: some View {
        VStack(spacing: 0) {
            List {
                Section {
                    ForEach(viewModel.messages) { message in
                        HStack {
                            Text(message.text)
                                .font(.system(size: 17))
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text("\(Int(message.fontSize))pt")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .contentShape(Rectangle())
                    }
                    .onDelete(perform: viewModel.deleteMessage)
                    .onMove(perform: viewModel.moveMessage)
                } header: {
                    if viewModel.messages.isEmpty {
                        Text("No messages added yet")
                            .textCase(nil)
                            .foregroundStyle(.secondary)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .listRowInsets(EdgeInsets())
                            .padding(.vertical, 20)
                    }
                }
            }
            .listStyle(.insetGrouped)
            
            // Bottom toolbar
            HStack(spacing: 16) {
                Button {
                    viewModel.showAddMessageSheet = true
                } label: {
                    Label("Add Message", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(!isEnabled)
                
                Button {
                    viewModel.sendMessages()
                } label: {
                    Label("Send", systemImage: "arrow.up.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.messages.isEmpty || !isEnabled || viewModel.isTransferring)
            }
            .controlSize(.large)
            .padding()
            .background(.bar)
        }
        .navigationTitle("Messages")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
                    .disabled(viewModel.messages.isEmpty)
            }
        }
        .sheet(isPresented: $viewModel.showAddMessageSheet) {
            AddMessageSheet(isPresented: $viewModel.showAddMessageSheet) { text, size in
                viewModel.addMessage(text, fontSize: size)
            }
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
}

struct AddMessageSheet: View {
    @Binding var isPresented: Bool
    let onAdd: (String, CGFloat) -> Void
    
    @State private var text = ""
    @State private var fontSize: CGFloat = 32
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Message") {
                    TextField("Enter text", text: $text)
                        .submitLabel(.done)
                }
                
                Section {
                    VStack(alignment: .leading) {
                        Text("Size: \(Int(fontSize))pt")
                            .foregroundStyle(.secondary)
                        
                        Slider(value: $fontSize, in: 12...72, step: 1) {
                            Text("Font Size")
                        }
                    }
                    .padding(.vertical, 4)
                    
                    // Preview
                    ZStack {
                        Color.black
                        Text(text.isEmpty ? "Preview" : text)
                            .font(.system(size: fontSize))
                            .foregroundStyle(text.isEmpty ? .gray : .white)
                            .padding()
                    }
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .listRowInsets(EdgeInsets())
                } header: {
                    Text("Style")
                }
            }
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd(text, fontSize)
                        isPresented = false
                    }
                    .disabled(text.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    NavigationStack {
        MessageArrayView(viewModel: MessageArrayViewModel())
    }
} 