import SwiftUI

enum DesignSystem {
    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 14
    }
}

// MARK: - Icon tile

/// Colored rounded-rect background with a centered SF Symbol. Used as a row-leading
/// affordance in Settings, the paywall, and inspectors.
struct IconTile: View {
    let icon: String
    let color: Color
    var size: CGFloat = 28

    private var cornerRadius: CGFloat {
        size < 50 ? DesignSystem.CornerRadius.small : DesignSystem.CornerRadius.large
    }

    private var iconSize: CGFloat { size * 0.5 }

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: iconSize, weight: .medium))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .tintedGlassBackground(color, cornerRadius: cornerRadius)
    }
}

// MARK: - Tinted action button styling

extension View {
    /// Centered, tinted pill-style action button (e.g. "Mark as paid", "Delete").
    /// Apply to the *label* contents of a Button.
    func tintedActionButton(_ color: Color) -> some View {
        self
            .padding(.vertical, 14)
            .padding(.horizontal, 32)
            .foregroundStyle(color)
            .tintedGlassBackground(color, cornerRadius: DesignSystem.CornerRadius.large)
            .frame(maxWidth: 260)
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
    }

    /// Tinted glass on iOS 26, solid translucent fill on iOS 18–25.
    /// Set `prominent: true` for primary CTAs (full-strength tint, opaque fill on iOS 18).
    @ViewBuilder
    func tintedGlassBackground(_ color: Color, cornerRadius: CGFloat, prominent: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            let tint = prominent ? color : color.opacity(0.35)
            self.glassEffect(
                .regular.tint(tint),
                in: RoundedRectangle(cornerRadius: cornerRadius)
            )
        } else {
            let fill = prominent ? color : color.opacity(0.15)
            self.background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(fill)
            )
        }
    }
}

// MARK: - Glassy card

extension View {
    /// Card background that uses iOS 26 Liquid Glass when available and a solid
    /// tertiarySystemBackground fill on iOS 18-25. This is the single isolated
    /// availability branch in the codebase — call it instead of repeating background
    /// + clip shape inline.
    @ViewBuilder
    func glassyCard(cornerRadius: CGFloat = DesignSystem.CornerRadius.medium) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(in: RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            self
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
    }

    /// Combines multiple glassy cards into a unified morphing shape on iOS 26.
    @ViewBuilder
    func glassyContainer() -> some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer {
                self
            }
        } else {
            self
        }
    }
}
