import SwiftUI

enum Theme {
    // MARK: - Colors
    static let accent = Color(red: 0.35, green: 0.55, blue: 0.95) // Soft blue
    static let destructive = Color(red: 0.9, green: 0.35, blue: 0.35) // Soft red
    static let success = Color(red: 0.35, green: 0.75, blue: 0.5) // Soft green
    static let warning = Color(red: 0.95, green: 0.75, blue: 0.35) // Soft amber

    // MARK: - Spacing
    static let paddingSmall: CGFloat = 8
    static let paddingMedium: CGFloat = 16
    static let paddingLarge: CGFloat = 24

    // MARK: - Corner Radius
    static let cornerRadius: CGFloat = 8
    static let cornerRadiusSmall: CGFloat = 4
}

// MARK: - View Extensions
extension View {
    func cardStyle() -> some View {
        self
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(Theme.cornerRadius)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
