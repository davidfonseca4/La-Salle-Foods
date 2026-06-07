//
//  OrderDetailView.swift
//  LaSalleFoods
//
//  Detalle de un pedido con la línea de tiempo de su estado (seguimiento).
//  El comprador puede cancelar el pedido solo mientras siga "Pendiente".
//

import SwiftUI

struct OrderDetailView: View {
    let order: Order
    @EnvironmentObject private var orders: OrderStore
    @State private var showCancelConfirm = false

    /// Versión vigente del pedido tomada del store, para reflejar en vivo
    /// los cambios de estado que haga el local.
    private var current: Order {
        orders.order(by: order.id) ?? order
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                headerCard
                if current.status != .cancelled {
                    timelineCard
                }
                itemsCard
                paymentCard
                cancelSection
            }
            .padding(AppSpacing.lg)
        }
        .background(AppColor.background.ignoresSafeArea())
        .navigationTitle("Pedido \(current.folio)")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "¿Cancelar este pedido?",
            isPresented: $showCancelConfirm,
            titleVisibility: .visible
        ) {
            Button("Sí, cancelar pedido", role: .destructive) {
                Task { await orders.cancelByCustomer(current) }
            }
            Button("No, mantener", role: .cancel) {}
        } message: {
            Text("Solo puedes cancelar mientras el local no haya comenzado a prepararlo.")
        }
    }

    private var headerCard: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(current.restaurantName)
                        .font(AppFont.headline())
                        .foregroundStyle(AppColor.textPrimary)
                    Text(current.createdAt.formatted(date: .complete, time: .shortened))
                        .font(AppFont.caption())
                        .foregroundStyle(AppColor.textSecondary)
                }
                Spacer()
                StatusBadge(status: current.status)
            }
            Divider()
            HStack(spacing: AppSpacing.lg) {
                VStack(spacing: 4) {
                    Text("Código de recogida")
                        .font(AppFont.caption())
                        .foregroundStyle(AppColor.textSecondary)
                    Text(current.pickupCode)
                        .font(AppFont.largeTitle())
                        .foregroundStyle(AppColor.orange)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .cardStyle()
    }

    private var timelineCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Seguimiento del pedido")
                .font(AppFont.headline())
                .foregroundStyle(AppColor.textPrimary)

            let steps: [OrderStatus] = [.pending, .preparing, .ready, .completed]
            ForEach(Array(steps.enumerated()), id: \.element) { index, step in
                TimelineRow(
                    status: step,
                    isDone: current.status.step >= step.step,
                    isLast: index == steps.count - 1
                )
            }
        }
        .cardStyle()
    }

    private var itemsCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Productos")
                .font(AppFont.headline())
                .foregroundStyle(AppColor.textPrimary)
            ForEach(current.lines) { line in
                HStack {
                    Text("\(line.quantity)×")
                        .font(AppFont.callout())
                        .foregroundStyle(AppColor.orange)
                    Text(line.productName)
                        .font(AppFont.body())
                        .foregroundStyle(AppColor.textPrimary)
                    Spacer()
                    Text(line.subtotal.asCurrency)
                        .font(AppFont.body())
                        .foregroundStyle(AppColor.textSecondary)
                }
                if line.id != current.lines.last?.id { Divider() }
            }
        }
        .cardStyle()
    }

    private var paymentCard: some View {
        VStack(spacing: AppSpacing.xs) {
            HStack {
                Label(current.paymentMethod.rawValue, systemImage: current.paymentMethod.icon)
                    .font(AppFont.subheadline())
                    .foregroundStyle(AppColor.textSecondary)
                Spacer()
            }
            Divider()
            HStack {
                Text("Total")
                    .font(AppFont.headline())
                    .foregroundStyle(AppColor.textPrimary)
                Spacer()
                Text(current.total.asCurrency)
                    .font(AppFont.headline())
                    .foregroundStyle(AppColor.orange)
            }
        }
        .cardStyle()
    }

    // MARK: - Cancelación

    @ViewBuilder private var cancelSection: some View {
        if current.canBeCancelledByCustomer {
            VStack(spacing: AppSpacing.xs) {
                AppButton(title: "Cancelar pedido", icon: "xmark.circle.fill", kind: .destructive) {
                    showCancelConfirm = true
                }
                Text("Puedes cancelar mientras el pedido siga pendiente.")
                    .font(AppFont.caption())
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
        } else if current.status == .preparing || current.status == .ready {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "info.circle.fill")
                Text("Este pedido ya está en preparación y no puede cancelarse.")
            }
            .font(AppFont.caption())
            .foregroundStyle(AppColor.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.sm)
            .background(AppColor.surfaceMuted)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        }
    }
}

private struct TimelineRow: View {
    let status: OrderStatus
    let isDone: Bool
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(isDone ? AppColor.success : AppColor.surfaceMuted)
                        .frame(width: 32, height: 32)
                    Image(systemName: isDone ? "checkmark" : status.icon)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(isDone ? .white : AppColor.textPlaceholder)
                }
                if !isLast {
                    Rectangle()
                        .fill(isDone ? AppColor.success : AppColor.border)
                        .frame(width: 2, height: 28)
                }
            }
            Text(status.rawValue)
                .font(AppFont.callout())
                .foregroundStyle(isDone ? AppColor.textPrimary : AppColor.textPlaceholder)
                .padding(.top, 6)
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        OrderDetailView(order: Order(
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
        .environmentObject(OrderStore())
    }
}
