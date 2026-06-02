//
//  View+Extensions.swift
//  LaSalleFoods
//
//  Modificadores reutilizables que encapsulan estilos comunes.
//

import SwiftUI

extension View {
    /// Aplica el estilo base de tarjeta: fondo blanco, esquinas y sombra suave.
    func cardStyle(padding: CGFloat = AppSpacing.md, radius: CGFloat = AppRadius.lg) -> some View {
        self
            .padding(padding)
            .background(AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .appShadow()
    }

    /// Oculta el teclado en iOS.
    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }

    /// Aplica un modificador condicionalmente.
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }
}

extension Double {
    /// Formatea un monto como precio en pesos mexicanos.
    var asCurrency: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "MXN"
        formatter.locale = Locale(identifier: "es_MX")
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self)) ?? "$\(self)"
    }
}
