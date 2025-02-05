import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("defaultColorSpace") private var defaultColorSpace = "16-bit"
    @AppStorage("defaultTransferMode") private var defaultTransferMode = "With Response"
    @AppStorage("hideUnnamedDevices") private var hideUnnamedDevices = true
    @AppStorage("priorityKeywords") private var priorityKeywords = ""
    @State private var newKeyword = ""
    @State private var showingKeywordError = false
    @State private var isAddingKeyword = false
    
    private var keywordsList: [String] {
        priorityKeywords.split(separator: ",")
            .map(String.init)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }
    
    var body: some View {
        List {
            Section {
                Toggle("Hide Unnamed Devices", isOn: $hideUnnamedDevices)
                    .tint(.blue)
            } header: {
                Text("Device List")
            } footer: {
                Text("When enabled, devices that don't advertise their name will be hidden from the list")
            }
            
            Section {
                if !keywordsList.isEmpty {
                    TagListView(tags: keywordsList, onDelete: removeKeyword)
                        .listRowInsets(EdgeInsets())
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.secondary)
                    
                    TextField("Add keyword", text: $newKeyword)
                        .font(.body)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onSubmit(addKeyword)
                    
                    if !newKeyword.trimmingCharacters(in: .whitespaces).isEmpty {
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            addKeyword()
                        } label: {
                            Image(systemName: "return")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.blue)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(10)
                .background {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(.systemFill))
                }
                .padding(.vertical, 4)
            } header: {
                Text("Priority Keywords")
            } footer: {
                Text("Devices with these keywords in their name will be shown at the top of the list")
            }
            
            Section("Default Settings") {
                Picker("Color Space", selection: $defaultColorSpace) {
                    Text("16-bit").tag("16-bit")
                    Text("24-bit").tag("24-bit")
                }
                
                Picker("Transfer Mode", selection: $defaultTransferMode) {
                    Text("With Response").tag("With Response")
                    Text("Without Response").tag("Without Response")
                    Text("Interleaved").tag("Interleaved")
                }
            }
            
            Section("About") {
                LabeledContent("Version", value: "1.1.1")
                NavigationLink {
                    List {
                        Section {
                            Link("Markury",
                                 destination: URL(string: "https://markury.dev")!)
                            Link("GitHub",
                                 destination: URL(string: "https://github.com/markuryy/lint_connect_swift")!)
                            Link("Pocket Lint",
                                 destination: URL(string: "https://github.com/markuryy/pocket_lint")!)
                            Link("Bluefruit Connect",
                                 destination: URL(string: "https://learn.adafruit.com/bluefruit-le-connect")!)
                        }
                    }
                    .navigationTitle("Links")
                } label: {
                    Text("Links")
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .toolbarRole(.browser)
        .alert("Invalid Keyword", isPresented: $showingKeywordError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Keywords cannot contain commas")
        }
    }
    
    private func addKeyword() {
        let trimmedKeyword = newKeyword.trimmingCharacters(in: .whitespaces)
        guard !trimmedKeyword.isEmpty else { return }
        
        // Check for commas since we use them as separators
        guard !trimmedKeyword.contains(",") else {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            showingKeywordError = true
            return
        }
        
        let currentKeywords = keywordsList
        if !currentKeywords.contains(trimmedKeyword) {
            withAnimation(.spring(response: 0.3)) {
                priorityKeywords = (currentKeywords + [trimmedKeyword]).joined(separator: ",")
            }
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
        newKeyword = ""
    }
    
    private func removeKeyword(_ keyword: String) {
        let updatedKeywords = keywordsList.filter { $0 != keyword }
        priorityKeywords = updatedKeywords.joined(separator: ",")
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
