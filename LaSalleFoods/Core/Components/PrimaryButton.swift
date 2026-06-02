//
//  PrimaryButton.swift
//  LaSalleFoods
//
//  Botón principal (CTA) con el naranja de marca, y variantes
//  secundaria y de éxito reutilizables en toda la app.
//

import SwiftUI

enum AppButtonStyleKind {
    case primary
    case secondary
    case success
    case destructive
}

struct AppButton: View {
    let title: String
    var icon: String? = nil
    var kind: AppButtonStyleKind = .primary
    var isLoading: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                if isLoading {
                    ProgressView()
                        .tint(foreground)
                } else {
                    if let icon {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text(title)
                        .font(AppFont.headline())
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .foregroundStyle(foreground)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .stroke(borderColor, lineWidth: kind == .secondary ? 1.5 : 0)
            )
        }
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1 : 0.5)
    }

    @ViewBuilder private var background: some View {
        switch kind {
        case .primary: AppColor.orange
        case .secondary: AppColor.surface
        case .success: AppColor.success
        case .destructive: AppColor.danger
        }
    }

    private var foreground: Color {
        switch kind {
        case .secondary: return AppColor.navy
        default: return .white
        }
    }

    private var borderColor: Color {
        kind == .secondary ? AppColor.border : .clear
    }
}

#Preview {
    VStack(spacing: 16) {
        AppButton(title: "Iniciar sesión", icon: "arrow.right") {}
        AppButton(title: "Agregar al carrito", icon: "cart.badge.plus", kind: .secondary) {}
        AppButton(title: "Confirmar pedido", kind: .success) {}
        AppButton(title: "Eliminar", icon: "trash", kind: .destructive) {}
    }
    .padding()
    .background(AppColor.background)
}
