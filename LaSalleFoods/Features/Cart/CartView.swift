//
//  CartView.swift
//  LaSalleFoods
//
//  Pantalla 4: carrito / resumen de pedido con método de pago y total.
//

import SwiftUI

struct CartView: View {
    @EnvironmentObject private var session: SessionStore
    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var cart: CartStore
    @EnvironmentObject private var orders: OrderStore
    @Environment(\.dismiss) private var dismiss

    @State private var paymentMethod: PaymentMethod = .cash
    @State private var placedOrder: Order?
    @State private var showErrorAlert = false

    var body: some View {
        Group {
            if cart.isEmpty {
                EmptyStateView(
                    icon: "bag",
                    title: "Tu carrito está vacío",
                    message: "Agrega productos de algún local para empezar tu pedido."
                )
            } else {
                content
            }
        }
        .navigationTitle("Mi pedido")
        .navigationBarTitleDisplayMode(.inline)
        .background(AppColor.background.ignoresSafeArea())
        .fullScreenCover(item: $placedOrder) { order in
            OrderConfirmationView(order: order)
        }
        .alert("No se pudo confirmar el pedido", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(orders.errorMessage ?? "Ocurrió un error inesperado.")
        }
    }

    private var content: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    if let restaurant {
                        restaurantHeader(restaurant)
                    }
                    itemsCard
                    paymentSection
                    summaryCard
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.top, AppSpacing.md)
                .padding(.bottom, 100)
            }

            confirmBar
        }
    }

    private var restaurant: Restaurant? {
        guard let id = cart.restaurantID else { return nil }
        return catalog.restaurant(by: id)
    }

    private func restaurantHeader(_ restaurant: Restaurant) -> some View {
        HStack(spacing: AppSpacing.md) {
            SymbolThumbnail(symbol: restaurant.symbol, hex: restaurant.coverHex, size: 52)
            VStack(alignment: .leading, spacing: 2) {
                Text(restaurant.name)
                    .font(AppFont.headline())
                    .foregroundStyle(AppColor.textPrimary)
                Label("Recoger en \(restaurant.location)", systemImage: "bag.fill")
                    .font(AppFont.caption())
                    .foregroundStyle(AppColor.textSecondary)
            }
            Spacer()
        }
        .cardStyle()
    }

    private var itemsCard: some View {
        VStack(spacing: AppSpacing.sm) {
            ForEach(cart.items) { item in
                CartItemRow(item: item)
                if item.id != cart.items.last?.id {
                    Divider()
                }
            }
        }
        .cardStyle()
    }

    private var paymentSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionHeader(title: "Método de pago")
            ForEach(PaymentMethod.allCases) { method in
                PaymentOptionRow(
                    method: method,
                    isSelected: paymentMethod == method
                ) {
                    withAnimation(.snappy) { paymentMethod = method }
                }
            }
        }
    }

    private var summaryCard: some View {
        VStack(spacing: AppSpacing.xs) {
            summaryRow(label: "Subtotal", value: cart.subtotal)
            summaryRow(label: "Cuota de servicio", value: cart.serviceFee)
            Divider()
            HStack {
                Text("Total")
                    .font(AppFont.headline())
                    .foregroundStyle(AppColor.textPrimary)
                Spacer()
                Text(cart.total.asCurrency)
                    .font(AppFont.headline())
                    .foregroundStyle(AppColor.orange)
            }
        }
        .cardStyle()
    }

    private func summaryRow(label: String, value: Double) -> some View {
        HStack {
            Text(label)
                .font(AppFont.body())
                .foregroundStyle(AppColor.textSecondary)
            Spacer()
            Text(value.asCurrency)
                .font(AppFont.body())
                .foregroundStyle(AppColor.textPrimary)
        }
    }

    private var confirmBar: some View {
        AppButton(title: "Confirmar pedido  ·  \(cart.total.asCurrency)", kind: .success) {
            placeOrder()
        }
        .padding(AppSpacing.md)
        .background(AppColor.surface.ignoresSafeArea(edges: .bottom).appShadow(.floating))
    }

    private func placeOrder() {
        guard let restaurant else { return }
        Task {
            if let order = await orders.placeOrder(items: cart.items, restaurant: restaurant, paymentMethod: paymentMethod) {
                cart.clear()
                placedOrder = order
            } else {
                showErrorAlert = true
            }
        }
    }
}

// MARK: - Fila de item del carrito

private struct CartItemRow: View {
    let item: CartItem
    @EnvironmentObject private var cart: CartStore

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            SymbolThumbnail(symbol: item.product.symbol, hex: 0xFF7426, size: 56)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.product.name)
                    .font(AppFont.callout())
                    .foregroundStyle(AppColor.textPrimary)
                Text(item.product.price.asCurrency)
                    .font(AppFont.subheadline())
                    .foregroundStyle(AppColor.textSecondary)
                if !item.notes.isEmpty {
                    Text("“\(item.notes)”")
                        .font(AppFont.caption())
                        .foregroundStyle(AppColor.textPlaceholder)
                        .lineLimit(1)
                }
            }
            Spacer()
            QuantityStepper(
                quantity: Binding(
                    get: { item.quantity },
                    set: { newValue in
                        if newValue > item.quantity { cart.increment(item) }
                        else { cart.decrement(item) }
                    }
                ),
                minValue: 0,
                compact: true
            )
        }
    }
}

// MARK: - Opción de método de pago

private struct PaymentOptionRow: View {
    let method: PaymentMethod
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: method.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? AppColor.orange : AppColor.textSecondary)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(method.rawValue)
                        .font(AppFont.callout())
                        .foregroundStyle(AppColor.textPrimary)
                    Text(method.subtitle)
                        .font(AppFont.caption())
                        .foregroundStyle(AppColor.textSecondary)
                }
                Spacer()
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(isSelected ? AppColor.orange : AppColor.border)
            }
            .padding(AppSpacing.md)
            .background(AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .stroke(isSelected ? AppColor.orange : AppColor.border, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let restaurantID = UUID()
    let cart = CartStore()
    cart.add(Product(restaurantID: restaurantID, name: "Torta de milanesa", description: "Milanesa, aguacate y frijoles.", price: 65, category: .mains, symbol: "takeoutbag.and.cup.and.straw.fill"), quantity: 2)
    cart.add(Product(restaurantID: restaurantID, name: "Agua de horchata", description: "Vaso de 500 ml.", price: 20, category: .drinks, symbol: "cup.and.saucer.fill"))
    return NavigationStack {
        CartView()
            .environmentObject(SessionStore())
            .environmentObject(CatalogStore())
            .environmentObject(cart)
            .environmentObject(OrderStore())
            .environmentObject(AppState())
    }
}
