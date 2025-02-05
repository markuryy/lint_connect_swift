import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("defaultColorSpace") private var defaultColorSpace = "16-bit"
    @AppStorage("defaultTransferMode") private var defaultTransferMode = "With Response"
    @AppStorage("hideUnnamedDevices") private var hideUnnamedDevices = true
    @AppStorage("priorityKeywords") private var priorityKeywords = ""
    @State private var newKeyword = ""
    @State private var showingKeywordError = false
    
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
                ForEach(keywordsList, id: \.self) { keyword in
                    HStack {
                        Text(keyword)
                        
                        Spacer()
                        
                        Button(role: .destructive) {
                            removeKeyword(keyword)
                        } label: {
                            Label("Remove", systemImage: "minus.circle.fill")
                                .labelStyle(.iconOnly)
                                .foregroundStyle(.red)
                        }
                    }
                }
                
                HStack {
                    TextField("Add keyword", text: $newKeyword)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                    
                    Button {
                        addKeyword()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.blue)
                    }
                    .disabled(newKeyword.trimmingCharacters(in: .whitespaces).isEmpty)
                }
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
                LabeledContent("Version", value: "1.0.0")
                NavigationLink {
                    List {
                        Section {
                            Link("Adafruit Industries",
                                 destination: URL(string: "https://www.adafruit.com")!)
                            Link("Bluefruit Documentation",
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
            showingKeywordError = true
            return
        }
        
        let currentKeywords = keywordsList
        if !currentKeywords.contains(trimmedKeyword) {
            priorityKeywords = (currentKeywords + [trimmedKeyword]).joined(separator: ",")
        }
        newKeyword = ""
    }
    
    private func removeKeyword(_ keyword: String) {
        let updatedKeywords = keywordsList.filter { $0 != keyword }
        priorityKeywords = updatedKeywords.joined(separator: ",")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
