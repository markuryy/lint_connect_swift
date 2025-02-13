import SwiftUI

struct ImageCropView: View {
    let image: UIImage
    @Binding var scale: CGFloat
    @Binding var offset: CGSize
    let onCrop: (UIImage) -> Void
    let onCancel: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var lastScale: CGFloat = 1.0
    @State private var lastOffset: CGSize = .zero
    @GestureState private var gestureScale: CGFloat = 1.0
    @GestureState private var gestureOffset: CGSize = .zero
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                let size = min(geometry.size.width, geometry.size.height * 0.8)
                let cropSize = CGSize(width: size, height: size)
                
                ZStack {
                    Color.black
                        .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        Spacer()
                        
                        // Crop Area
                        ZStack {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .scaleEffect(scale * gestureScale)
                                .offset(x: offset.width + gestureOffset.width,
                                        y: offset.height + gestureOffset.height)
                                .frame(width: cropSize.width, height: cropSize.height)
                                .clipped()
                                .overlay {
                                    CropGridOverlay()
                                }
                                .gesture(
                                    SimultaneousGesture(
                                        MagnificationGesture()
                                            .updating($gestureScale) { value, state, _ in
                                                state = value
                                            }
                                            .onEnded { value in
                                                scale = scale * value
                                            },
                                        DragGesture()
                                            .updating($gestureOffset) { value, state, _ in
                                                state = value.translation
                                            }
                                            .onEnded { value in
                                                offset = CGSize(
                                                    width: offset.width + value.translation.width,
                                                    height: offset.height + value.translation.height
                                                )
                                            }
                                    )
                                )
                        }
                        .frame(width: cropSize.width, height: cropSize.height)
                        .background(Color.black)
                        .cornerRadius(8)
                        .shadow(radius: 20)
                        
                        Spacer()
                        
                        // Bottom Toolbar
                        HStack {
                            Button(action: {
                                dismiss()
                                onCancel()
                            }) {
                                Text("Cancel")
                                    .font(.body.weight(.medium))
                            }
                            
                            Spacer()
                            
                            Button {
                                let renderer = ImageRenderer(content: 
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .scaleEffect(scale)
                                        .offset(offset)
                                        .frame(width: size, height: size)
                                        .clipped()
                                )
                                
                                if let uiImage = renderer.uiImage {
                                    dismiss()
                                    onCrop(uiImage)
                                }
                            } label: {
                                Text("Choose")
                                    .font(.body.weight(.bold))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background {
                            Rectangle()
                                .fill(.black)
                                .ignoresSafeArea()
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationTitle("")
        }
        .navigationViewStyle(.stack)
    }
}

struct CropGridOverlay: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Grid lines
                GridLines(spacing: geometry.size.width / 3)
                    .stroke(Color.white.opacity(0.7), lineWidth: 1)
                
                // Border
                Rectangle()
                    .strokeBorder(Color.white, lineWidth: 2)
            }
        }
    }
}

struct GridLines: Shape {
    let spacing: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Vertical lines
        for i in 1...2 {
            let x = rect.width / 3 * CGFloat(i)
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: rect.height))
        }
        
        // Horizontal lines
        for i in 1...2 {
            let y = rect.height / 3 * CGFloat(i)
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
        }
        
        return path
    }
}

#Preview {
    ImageCropView(
        image: UIImage(systemName: "photo")!,
        scale: .constant(1.0),
        offset: .constant(.zero),
        onCrop: { _ in },
        onCancel: {}
    )
} 