import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultColorSpace") private var defaultColorSpace = "16-bit"
    @AppStorage("defaultTransferMode") private var defaultTransferMode = "With Response"
    
    var body: some View {
        NavigationStack {
            List {
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
        }
    }
}

#Preview {
    SettingsView()
}
