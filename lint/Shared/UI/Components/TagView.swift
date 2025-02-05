import SwiftUI

struct TagView: View {
    let text: String
    let onDelete: () -> Void
    
    var body: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            onDelete()
        } label: {
            HStack(spacing: 6) {
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color(.separator), lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
    }
}

struct TagListView: View {
    let tags: [String]
    let onDelete: (String) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    TagView(text: tag) {
                        withAnimation(.spring(response: 0.3)) {
                            onDelete(tag)
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .scrollClipDisabled()
    }
}


#Preview {
    VStack(spacing: 20) {
        TagView(text: "Example Tag") {}
        
        TagListView(tags: ["Tag 1", "Long Tag Name", "Short"]) { _ in }
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
