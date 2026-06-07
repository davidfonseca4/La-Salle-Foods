//
//  OrderConfirmationView.swift
//  LaSalleFoods
//
//  Confirmación de pedido con el verde de éxito, folio y código de recogida.
//

import SwiftUI

struct OrderConfirmationView: View {
    let order: Order
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @State private var animate = false

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AppColor.success.opacity(0.15))
                    .frame(width: 140, height: 140)
                Circle()
                    .fill(AppColor.success)
                    .frame(width: 96, height: 96)
                Image(systemName: "checkmark")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(.white)
            }
            .scaleEffect(animate ? 1 : 0.6)
            .opacity(animate ? 1 : 0)

            VStack(spacing: AppSpacing.xs) {
                Text("¡Pedido confirmado!")
                    .font(AppFont.title())
                    .foregroundStyle(AppColor.textPrimary)
                Text("Enviamos tu pedido a \(order.restaurantName). Te avisaremos cuando empiecen a prepararlo.")
                    .font(AppFont.body())
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.lg)
            }

            pickupCard

            Label("Puedes cancelarlo mientras siga pendiente.", systemImage: "info.circle.fill")
                .font(AppFont.caption())
                .foregroundStyle(AppColor.textSecondary)

            Spacer()

            VStack(spacing: AppSpacing.xs) {
                AppButton(title: "Ver mis pedidos", icon: "bag.fill") {
                    appState.goToMyOrders()
                    dismiss()
                }
                AppButton(title: "Volver al inicio", kind: .secondary) {
                    appState.goToHomeRoot()
                    dismiss()
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColor.background.ignoresSafeArea())
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                animate = true
            }
        }
    }

    private var pickupCard: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack {
                infoBlock(title: "Folio", value: order.folio)
                Divider().frame(height: 40)
                infoBlock(title: "Código de recogida", value: order.pickupCode)
            }
            Divider()
            HStack {
                Label(order.paymentMethod.rawValue, systemImage: order.paymentMethod.icon)
                    .font(AppFont.subheadline())
                    .foregroundStyle(AppColor.textSecondary)
                Spacer()
                Text(order.total.asCurrency)
                    .font(AppFont.headline())
                    .foregroundStyle(AppColor.textPrimary)
            }
        }
        .cardStyle()
    }

    private func infoBlock(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(AppFont.caption())
                .foregroundStyle(AppColor.textSecondary)
            Text(value)
                .font(AppFont.title())
                .foregroundStyle(AppColor.orange)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    OrderConfirmationView(order: Order(
        folio: "LSF-2048",
        restaurantID: UUID(),
        restaurantName: "Tortas Doña Mary",
        lines: [
            OrderLine(productName: "Torta de milanesa", quantity: 1, unitPrice: 65),
            OrderLine(productName: "Agua de horchata", quantity: 1, unitPrice: 20)
        ],
        paymentMethod: .cash,
        status: .preparing,
        createdAt: Date().addingTimeInterval(-600),
        pickupCode: "A12"
    ))
    .environmentObject(AppState())
}
