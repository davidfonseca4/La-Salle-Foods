//
//  Color+Hex.swift
//  LaSalleFoods
//
//  Permite construir colores a partir de un valor hexadecimal,
//  útil para mapear la paleta de marca definida en la documentación.
//

import SwiftUI

extension Color {
    /// Crea un color a partir de un entero hexadecimal (ej. 0xFF7426).
    init(hex: UInt, alpha: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}
