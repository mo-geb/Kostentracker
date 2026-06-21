import SwiftUI

struct ExpenseMediaView: View {
    let media: ExpenseMedia
    let size: CGFloat
    
    var body: some View {
        switch media {
        case .image(let uiImage):
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
        case .emoji(let emoji, let color):
            ZStack {
                Circle()
                    .fill(color.opacity(0.3))
                    .frame(width: size, height: size)
                Text(emoji)
                    .font(.system(size: size * 0.5))
            }
        case .icon(let symbolName, let color):
            ZStack {
                Circle()
                    .fill(color.opacity(0.3))
                    .frame(width: size, height: size)
                Image(systemName: symbolName)
                    .font(.system(size: size * 0.5))
                    .foregroundStyle(color)
            }
        }
    }
}
