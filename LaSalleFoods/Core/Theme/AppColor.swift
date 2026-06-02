//
//  AppColor.swift
//  LaSalleFoods
//
//  Paleta de colores oficial de La Salle Foods, tomada de la
//  documentación del proyecto. Centralizar los colores aquí evita
//  valores "mágicos" dispersos por la UI y facilita el theming.
//

import SwiftUI

enum AppColor {
    // MARK: - Marca / institucional
    /// Azul institucional, usado en navegación activa y elementos de marca.
    static let blue = Color(hex: 0x0B3D91)
    /// Azul oscuro para títulos, nombres de locales y texto fuerte.
    static let navy = Color(hex: 0x0A2540)

    // MARK: - Acciones
    /// Naranja principal: CTA, botones de agregar y confirmar.
    static let orange = Color(hex: 0xFF7426)
    /// Naranja cálido para degradados y banners.
    static let orangeWarm = Color(hex: 0xFFA34D)

    /// Degradado cálido para banners y tarjetas promocionales.
    static let warmGradient = LinearGradient(
        colors: [Color(hex: 0xFF8A3D), Color(hex: 0xFF5E62)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Degradado institucional para encabezados destacados.
    static let brandGradient = LinearGradient(
        colors: [Color(hex: 0x0B3D91), Color(hex: 0x0A2540)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Estado
    /// Verde de éxito: pedido confirmado, envío gratis, indicadores positivos.
    static let success = Color(hex: 0x1FAA59)
    /// Rojo para acciones destructivas / agotado.
    static let danger = Color(hex: 0xE23744)
    /// Amarillo para estrellas y calificaciones.
    static let rating = Color(hex: 0xFFC107)

    // MARK: - Superficies y texto
    /// Fondo general de la app.
    static let background = Color(hex: 0xF6F7F9)
    /// Superficie de tarjetas y formularios.
    static let surface = Color.white
    /// Gris claro para inputs, buscador y fondos secundarios.
    static let surfaceMuted = Color(hex: 0xF0F1F3)

    /// Texto principal.
    static let textPrimary = Color(hex: 0x0A2540)
    /// Texto secundario / auxiliar (subtítulos, descripciones).
    static let textSecondary = Color(hex: 0x6B7280)
    /// Texto placeholder / iconos inactivos.
    static let textPlaceholder = Color(hex: 0x9CA3AF)

    /// Bordes y separadores suaves.
    static let border = Color(hex: 0xE5E7EB)
}
