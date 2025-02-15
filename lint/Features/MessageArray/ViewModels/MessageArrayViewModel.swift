import SwiftUI

@MainActor
class MessageArrayViewModel: ObservableObject {
    private let bleManager = BLEManager.shared
    
    // MARK: - Properties
    @Published var messages: [Message] = []
    @Published var isTransferring = false
    @Published var showAddMessageSheet = false
    @Published var errorMessage: String?
    
    struct Message: Identifiable, Equatable {
        let id = UUID()
        var text: String
        var fontSize: CGFloat
        
        static func == (lhs: Message, rhs: Message) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    // MARK: - Public Methods
    func addMessage(_ text: String, fontSize: CGFloat) {
        messages.append(Message(text: text, fontSize: fontSize))
    }
    
    func deleteMessage(at indexSet: IndexSet) {
        messages.remove(atOffsets: indexSet)
    }
    
    func moveMessage(from source: IndexSet, to destination: Int) {
        messages.move(fromOffsets: source, toOffset: destination)
    }
    
    func sendMessages() {
        Task {
            do {
                guard !messages.isEmpty else { return }
                isTransferring = true
                
                // Clear existing messages
                bleManager.sendData(Data([0x02]), withResponse: true)
                try await Task.sleep(nanoseconds: 500_000_000) // 500ms delay
                
                // Send each message
                for message in messages {
                    let command: [UInt8] = [0x01]
                    let size = UInt8(max(12, min(message.fontSize, 72)))
                    
                    guard let textData = message.text.data(using: .utf8) else { continue }
                    let length = UInt8(min(textData.count, 255))
                    
                    var data = Data(command)
                    data.append(size)
                    data.append(length)
                    data.append(textData.prefix(Int(length)))
                    
                    bleManager.sendData(data, withResponse: true)
                    try await Task.sleep(nanoseconds: 300_000_000) // 300ms delay
                }
                
                isTransferring = false
            } catch {
                isTransferring = false
                errorMessage = error.localizedDescription
            }
        }
    }
} 