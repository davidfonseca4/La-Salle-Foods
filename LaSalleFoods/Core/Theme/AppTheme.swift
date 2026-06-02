//
//  AppTheme.swift
//  LaSalleFoods
//
//  Tokens de diseño: espaciado, radios de esquina, sombras y tipografía.
//  Mantener estos valores centralizados garantiza consistencia visual.
//

import SwiftUI

// MARK: - Espaciado

enum AppSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Radios

enum AppRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 18
    static let xl: CGFloat = 28
    static let pill: CGFloat = 999
}

// MARK: - Tipografía

enum AppFont {
    static func largeTitle() -> Font { .system(size: 32, weight: .bold, design: .rounded) }
    static func title() -> Font { .system(size: 24, weight: .bold, design: .rounded) }
    static func headline() -> Font { .system(size: 18, weight: .semibold, design: .rounded) }
    static func body() -> Font { .system(size: 16, weight: .regular) }
    static func callout() -> Font { .system(size: 15, weight: .medium) }
    static func subheadline() -> Font { .system(size: 14, weight: .regular) }
    static func caption() -> Font { .system(size: 12, weight: .regular) }
    static func price() -> Font { .system(size: 16, weight: .bold, design: .rounded) }
}

// MARK: - Sombras

struct AppShadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    static let card = AppShadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    static let floating = AppShadow(color: Color.black.opacity(0.12), radius: 18, x: 0, y: 8)
}

extension View {
    func appShadow(_ shadow: AppShadow = .card) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}
