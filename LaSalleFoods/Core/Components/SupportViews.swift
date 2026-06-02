//
//  SupportViews.swift
//  LaSalleFoods
//
//  Vistas auxiliares pequeñas: encabezados de sección, estados vacíos
//  y badge de estado de pedido.
//

import SwiftUI

struct SectionHeader: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(AppFont.headline())
                .foregroundStyle(AppColor.textPrimary)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(AppFont.callout())
                    .foregroundStyle(AppColor.orange)
            }
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(AppColor.surfaceMuted)
                    .frame(width: 96, height: 96)
                Image(systemName: icon)
                    .font(.system(size: 38, weight: .medium))
                    .foregroundStyle(AppColor.textPlaceholder)
            }
            Text(title)
                .font(AppFont.headline())
                .foregroundStyle(AppColor.textPrimary)
            Text(message)
                .font(AppFont.subheadline())
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.lg)
            if let actionTitle, let action {
                AppButton(title: actionTitle, action: action)
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.top, AppSpacing.xs)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xl)
    }
}

struct StatusBadge: View {
    let status: OrderStatus

    var body: some View {
        TagChip(
            text: status.rawValue,
            icon: status.icon,
            foreground: Color(hex: status.colorHex),
            background: Color(hex: status.colorHex).opacity(0.14)
        )
    }
}

#Preview {
    VStack(spacing: 24) {
        SectionHeader(title: "Locales", actionTitle: "Ver todos") {}
        StatusBadge(status: .preparing)
        EmptyStateView(
            icon: "bag",
            title: "Tu carrito está vacío",
            message: "Agrega productos de algún local para empezar tu pedido."
        )
    }
    .padding()
    .background(AppColor.background)
}
