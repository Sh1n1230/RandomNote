import SwiftUI
import UIKit

/// design_system.yml の写し。YAMLが正なので、片方を変えたらもう片方も合わせる。
enum DS {
    enum Color {
        static let canvas = dynamic(0xF1F2F6, 0x0B0D14)
        static let surface = dynamic(0xFFFFFF, 0x161925)
        static let surfaceSunken = dynamic(0xE9EBF1, 0x101320)
        static let ink = dynamic(0x0F1222, 0xF2F3F7)
        static let inkSecondary = dynamic(0x5A6076, 0xA2A8BC)
        static let inkTertiary = dynamic(0x8B90A3, 0x6E748A)
        static let border = dynamic(0xE3E5EE, 0x252938)
        static let brand = dynamic(0x1E3AC4, 0x2E4FE0)
        static let accent = dynamic(0x3D6EF7, 0x6C90FF)
        static let accentPressed = dynamic(0x2F58D4, 0x547BF5)
        static let onAccent = SwiftUI.Color.white
        static let highlight = dynamic(0xF5A623, 0xF7B955)
        static let danger = dynamic(0xE5484D, 0xFF6369)

        private static func dynamic(_ light: UInt32, _ dark: UInt32) -> SwiftUI.Color {
            SwiftUI.Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light) })
        }
    }

    enum Space {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
        static let screenMargin: CGFloat = 20
        static let cardPadding: CGFloat = 20
        static let stackGap: CGFloat = 16
    }

    enum Radius {
        static let pill: CGFloat = 999
        static let card: CGFloat = 24
        static let control: CGFloat = 16
        static let media: CGFloat = 14
    }

    enum Shadow {
        static let cardOpacity = 0.05
        static let cardBlur: CGFloat = 12
        static let cardY: CGFloat = 2
    }

    enum Motion {
        static let quick = Animation.smooth(duration: 0.18)
        static let standard = Animation.smooth(duration: 0.30)
    }
}

/// 文字スタイル。Dynamic Type を殺さないよう semantic text style をベースにする。
extension View {
    func dsDisplay() -> some View {
        font(.largeTitle.weight(.bold)).tracking(-0.8).foregroundStyle(DS.Color.ink)
    }
    func dsTitle() -> some View {
        font(.title2.weight(.semibold)).tracking(-0.5).foregroundStyle(DS.Color.ink)
    }
    func dsHeadline() -> some View {
        font(.headline).tracking(-0.2).foregroundStyle(DS.Color.ink)
    }
    func dsBody() -> some View {
        font(.body).lineSpacing(5).foregroundStyle(DS.Color.ink)
    }
    func dsCallout() -> some View {
        font(.callout).foregroundStyle(DS.Color.inkSecondary)
    }
    func dsCaption() -> some View {
        font(.caption).foregroundStyle(DS.Color.inkSecondary)
    }
    /// 日付・件数などのメタ情報。極小・大文字・トラッキング広めで主役と競合させない。
    /// 色は引数で渡す（あとから .foregroundStyle を重ねても内側のこの指定が勝ってしまうため）。
    func dsMicroLabel(_ color: SwiftUI.Color = DS.Color.inkTertiary) -> some View {
        font(.caption2.weight(.semibold)).tracking(1.2).textCase(.uppercase).foregroundStyle(color)
    }

    /// 面。影ではなくヘアラインと極薄の影で輪郭を出す。
    func dsCard(padding: CGFloat = DS.Space.cardPadding, radius: CGFloat = DS.Radius.card) -> some View {
        self
            .padding(padding)
            .background(DS.Color.surface, in: .rect(cornerRadius: radius))
            .overlay(RoundedRectangle(cornerRadius: radius).strokeBorder(DS.Color.border, lineWidth: 1))
            .shadow(color: .black.opacity(DS.Shadow.cardOpacity), radius: DS.Shadow.cardBlur, y: DS.Shadow.cardY)
    }
}

/// 主操作は完全なピル。参考ショットの "Get Early Access" ピルに合わせる。
struct DSPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(DS.Color.onAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(configuration.isPressed ? DS.Color.accentPressed : DS.Color.accent, in: .capsule)
            .opacity(configuration.isPressed ? 0.9 : 1)
    }
}

struct DSSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(DS.Color.ink)
            .padding(.vertical, 11)
            .padding(.horizontal, DS.Space.xl)
            .background(DS.Color.surface, in: .capsule)
            .overlay(Capsule().strokeBorder(DS.Color.border, lineWidth: 1))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

/// design_system.yml の components.chip。カテゴリの表示・選択に使う。
struct DSChip: View {
    let title: String
    var isSelected = false
    var systemImage: String?
    var compact = false

    var body: some View {
        HStack(spacing: DS.Space.xs) {
            if let systemImage {
                Image(systemName: systemImage).font(.caption2.weight(.bold))
            }
            Text(title).font(compact ? .caption2.weight(.semibold) : .footnote.weight(.semibold))
        }
        .foregroundStyle(isSelected ? DS.Color.onAccent : DS.Color.inkSecondary)
        .padding(.horizontal, compact ? DS.Space.sm : DS.Space.md)
        .frame(height: compact ? 24 : 32)
        .background(isSelected ? DS.Color.accent : DS.Color.surface, in: .capsule)
        .overlay(Capsule().strokeBorder(isSelected ? SwiftUI.Color.clear : DS.Color.border, lineWidth: 1))
    }
}

/// チップを折り返して並べるための最小限のレイアウト
struct FlowLayout: Layout {
    var spacing: CGFloat = DS.Space.sm

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth.isFinite ? maxWidth : x, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

extension ButtonStyle where Self == DSPrimaryButtonStyle {
    static var dsPrimary: DSPrimaryButtonStyle { .init() }
}

extension ButtonStyle where Self == DSSecondaryButtonStyle {
    static var dsSecondary: DSSecondaryButtonStyle { .init() }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
