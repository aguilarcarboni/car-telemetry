import SwiftUI

/// A reusable tile that shows an optional icon or value together with a title.
/// Mimics the styling that was previously embedded in `SessionView` so it can be shared by other views.
public struct InfoTile: View {
    public let title: String
    public let value: String?
    public let icon: String?
    public let content: AnyView?
    public let color: Color

    public init(title: String, value: String? = nil, icon: String? = nil, color: Color = .white, content: AnyView? = nil) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
        self.content = content
    }

    /// Convenience initializer that takes a `@ViewBuilder` closure for the content.
    public init<Content: View>(title: String, value: String? = nil, icon: String? = nil, color: Color = .white, @ViewBuilder content: () -> Content) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
        self.content = AnyView(content())
    }

    public var body: some View {
        VStack {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(color)
            }

            if let value = value {
                Text(value)
                    .font(.title)
                    .bold()
                    .foregroundColor(color)
            }

            if let embeddedContent = content {
                embeddedContent
            }

            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

#if DEBUG
struct InfoTile_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            InfoTile(title: "Weather", icon: "sun.max.fill")
                .previewLayout(.sizeThatFits)
                .background(Color.black)

            InfoTile(title: "Track Temp", value: "42°C")
                .previewLayout(.sizeThatFits)
                .background(Color.black)
        }
    }
}
#endif
