//
//  TagChip.swift
//  LaSalleFoods
//
//  Etiqueta tipo "chip" reutilizable para tags, estados y filtros.
//

import SwiftUI

struct TagChip: View {
    let text: String
    var icon: String? = nil
    var foreground: Color = AppColor.navy
    var background: Color = AppColor.surfaceMuted

    var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
            }
            Text(text)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, 6)
        .background(background)
        .clipShape(Capsule())
    }
}

/// Chip seleccionable para filtros de categorías.
struct FilterChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(isSelected ? .white : AppColor.textPrimary)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.xs)
            .background(isSelected ? AppColor.navy : AppColor.surface)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(isSelected ? Color.clear : AppColor.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack {
            TagChip(text: "Popular", icon: "flame.fill", foreground: AppColor.orange, background: AppColor.orange.opacity(0.12))
            TagChip(text: "Sin filas")
        }
        HStack {
            FilterChip(title: "Todos", isSelected: true) {}
            FilterChip(title: "Bebidas", icon: "cup.and.saucer.fill", isSelected: false) {}
        }
    }
    .padding()
    .background(AppColor.background)
}
