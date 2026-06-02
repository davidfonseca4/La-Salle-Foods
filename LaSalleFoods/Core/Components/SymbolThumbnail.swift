//
//  SymbolThumbnail.swift
//  LaSalleFoods
//
//  Miniatura ilustrada basada en SF Symbols sobre un degradado.
//  Sustituye a imágenes reales en este prototipo de front-end.
//

import SwiftUI

struct SymbolThumbnail: View {
    let symbol: String
    var hex: UInt = 0xFF7426
    var size: CGFloat = 64
    var cornerRadius: CGFloat = AppRadius.md

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: hex), Color(hex: hex).opacity(0.65)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: symbol)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

/// Portada ancha para tarjetas de locales.
struct SymbolBanner: View {
    let symbol: String
    var hex: UInt = 0xFF7426
    var height: CGFloat = 140

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: hex), Color(hex: hex).opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: symbol)
                .font(.system(size: height * 0.4, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
                .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .clipped()
    }
}

#Preview {
    VStack(spacing: 16) {
        SymbolThumbnail(symbol: "takeoutbag.and.cup.and.straw.fill")
        SymbolBanner(symbol: "cup.and.saucer.fill", hex: 0x0B3D91)
    }
    .padding()
}
