import SwiftUI

struct Function: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let icon: String
    let description: String
    let type: FunctionType
    
    static func == (lhs: Function, rhs: Function) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum FunctionType: Hashable {
    case imageTransfer
    // Add more function types here
}

struct FunctionCard: View {
    let function: Function
    let isEnabled: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                // Icon
                Image(systemName: function.icon)
                    .font(.title)
                    .foregroundStyle(isEnabled ? .blue : .secondary)
                    .frame(width: 44, height: 44)
                    .background {
                        Circle()
                            .fill(.secondary.opacity(0.1))
                    }
                
                // Title and Description
                VStack(alignment: .leading, spacing: 4) {
                    Text(function.name)
                        .font(.headline)
                    
                    Text(isEnabled ? function.description : "Connect a device to use this function")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            }
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.6)
    }
}

struct FunctionList: View {
    let functions: [Function]
    let isEnabled: Bool
    let selectedFunction: Function?
    let onSelect: (Function) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                ForEach(functions) { function in
                    FunctionCard(
                        function: function,
                        isEnabled: isEnabled,
                        onSelect: { onSelect(function) }
                    )
                    .frame(width: 280)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .scrollClipDisabled()
    }
}

#Preview {
    FunctionList(
        functions: [
            Function(
                name: "Image Transfer",
                icon: "photo.on.rectangle.angled",
                description: "Transfer images to your device with custom resolution and color settings",
                type: .imageTransfer
            )
        ],
        isEnabled: true,
        selectedFunction: nil,
        onSelect: { _ in }
    )
}
