import SwiftUI

// MARK: - Colour tokens (Macchiato & Co palette)

extension Color {
    static let espresso  = Color(hex: "#3A2418")
    static let bark      = Color(hex: "#6B4A33")
    static let inkMuted  = Color(hex: "#8E7560")
    static let terra     = Color(hex: "#C97B5C")
    static let amber     = Color(hex: "#D49846")
    static let amberSoft = Color(hex: "#F2DDB0")
    static let oat       = Color(hex: "#E8DCC6")
    static let cream     = Color(hex: "#F5EDDF")
    static let paper     = Color(hex: "#FBF6EB")
    static let cafeRed   = Color(hex: "#C25B53")
    static let cafeRedSoft = Color(hex: "#F2D6D3")
    static let cafeGreen = Color(hex: "#5C8A5A")

    static let cardBorder    = Color(red: 58/255, green: 36/255, blue: 24/255).opacity(0.08)
    static let cardBorderSoft = Color(red: 58/255, green: 36/255, blue: 24/255).opacity(0.06)

    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Typography helpers

extension Font {
    // New York (iOS built-in serif) — closest to Newsreader on-device
    static func serif(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
    // SF Pro rounded
    static func sans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    // SF Mono
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

// MARK: - Shared shape

extension RoundedRectangle {
    static let card = RoundedRectangle(cornerRadius: 18, style: .continuous)
    static let cardLarge = RoundedRectangle(cornerRadius: 22, style: .continuous)
    static let cta  = RoundedRectangle(cornerRadius: 16, style: .continuous)
    static let pill = RoundedRectangle(cornerRadius: 100, style: .continuous)
}

// MARK: - View modifiers

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Color.cardBorderSoft, lineWidth: 0.5))
            .shadow(color: Color.espresso.opacity(0.05), radius: 9, y: 6)
            .shadow(color: Color.espresso.opacity(0.04), radius: 1, y: 1)
    }
}

struct CTAButtonStyle: ButtonStyle {
    var filled: Bool = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.sans(16, weight: .semibold))
            .foregroundStyle(filled ? Color.cream : Color.espresso)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .padding(.horizontal, 22)
            .background(filled ? Color.espresso : Color.white)
            .clipShape(RoundedRectangle.cta)
            .overlay(filled ? nil : RoundedRectangle.cta.strokeBorder(Color.cardBorder, lineWidth: 0.5))
            .shadow(color: Color.espresso.opacity(filled ? 0.32 : 0), radius: 12, y: 10)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

extension View {
    func cardStyle() -> some View { modifier(CardStyle()) }

    func monoLabel(_ text: String, color: Color = .bark) -> some View {
        Text(text)
            .font(.mono(10.5, weight: .regular))
            .foregroundStyle(color)
            .tracking(1.6)
            .textCase(.uppercase)
    }
}
