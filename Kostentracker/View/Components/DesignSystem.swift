import SwiftUI

enum DesignSystem {
    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 14
    }
}

// MARK: - Icon tile

/// Classic iOS Settings row-leading affordance: a white SF Symbol on a solid
/// gradient tile. Used in Settings, the paywall, and inspectors so they all match.
struct IconTile: View {
    let icon: String
    let color: Color
    var size: CGFloat = 28

    private var cornerRadius: CGFloat { size * 0.23 }
    private var iconSize: CGFloat { size * 0.5 }

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: iconSize, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(color.gradient)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
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
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
    }

    /// Solid translucent tint behind an accent element (icon tiles, action buttons).
    /// Set `prominent: true` for primary CTAs (full-strength tint).
    /// Post-overhaul this drops Liquid Glass so accents stay consistent with the
    /// now-flat cards; identical on iOS 18 and 26.
    func tintedGlassBackground(_ color: Color, cornerRadius: CGFloat, prominent: Bool = false) -> some View {
        let fill = prominent ? color : color.opacity(0.15)
        return self.background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(fill)
        )
    }
}

// MARK: - Card surface

extension View {
    /// Neutral card surface: an elevated grouped background with a soft hairline,
    /// for content sitting on a `systemGroupedBackground`. Post-overhaul this uses
    /// the native inset-grouped look instead of Liquid Glass; identical on iOS 18
    /// and 26.
    func cardSurface(cornerRadius: CGFloat = DesignSystem.CornerRadius.medium) -> some View {
        self
            .background(
                Color(.secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color(.separator).opacity(0.5), lineWidth: 1)
            )
    }
}
