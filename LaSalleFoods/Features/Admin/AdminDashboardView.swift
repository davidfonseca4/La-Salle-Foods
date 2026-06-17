//
//  AdminDashboardView.swift
//  LaSalleFoods
//
//  Pantalla 6: panel de administración para dueños de local.
//  Permite alta/edición/baja de productos, inhabilitar agotados y
//  revisar pedidos recibidos.
//

import SwiftUI

struct AdminDashboardView: View {
    @EnvironmentObject private var session: SessionStore
    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var orders: OrderStore

    @State private var productFormMode: ProductFormView.Mode?
    @State private var productToDelete: Product?
    @State private var showStatusError = false
    @State private var showEditRestaurant = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    if let restaurant {
                        restaurantHeader(for: restaurant)
                        statsRow(for: restaurant)
                        notificationsSection(for: restaurant)
                        receivedOrdersSection(for: restaurant)
                        productsSection(for: restaurant)
                    } else {
                        EmptyStateView(
                            icon: "storefront",
                            title: "Sin local asignado",
                            message: "Esta cuenta no tiene un local asociado."
                        )
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl)
            }
            .background(AppColor.background.ignoresSafeArea())
            .task {
                await catalog.loadCatalog()
            }
            .refreshable {
                await orders.refreshAll(showLoading: false)
            }
            .navigationTitle("Panel del local")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if restaurant != nil {
                        let unread = orders.unreadCount
                        Image(systemName: unread > 0 ? "bell.badge.fill" : "bell")
                            .foregroundStyle(unread > 0 ? AppColor.danger : AppColor.textSecondary)
                            .overlay(alignment: .topTrailing) {
                                if unread > 0 {
                                    Text("\(unread)")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.white)
                                        .padding(4)
                                        .background(AppColor.danger, in: Circle())
                                        .offset(x: 8, y: -8)
                                }
                            }
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    if let restaurant {
                        Button {
                            productFormMode = .create(restaurantID: restaurant.id)
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(AppColor.orange)
                        }
                    }
                }
            }
            .sheet(item: $productFormMode) { mode in
                ProductFormView(mode: mode)
            }
            .confirmationDialog(
                "¿Eliminar este producto?",
                isPresented: Binding(get: { productToDelete != nil }, set: { if !$0 { productToDelete = nil } }),
                presenting: productToDelete
            ) { product in
                Button("Eliminar", role: .destructive) {
                    Task { await catalog.deleteProduct(product) }
                    productToDelete = nil
                }
                Button("Cancelar", role: .cancel) { productToDelete = nil }
            } message: { product in
                Text(product.name)
            }
            .alert("No se pudo actualizar el pedido", isPresented: $showStatusError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(orders.errorMessage ?? "Ocurrió un error inesperado.")
            }
            .sheet(isPresented: $showEditRestaurant) {
                if let restaurant {
                    EditRestaurantView(restaurant: restaurant)
                }
            }
        }
    }

    private var restaurant: Restaurant? {
        guard let id = session.currentUser?.ownedRestaurantID else { return nil }
        return catalog.restaurant(by: id)
    }

    // MARK: - Mi local

    private func restaurantHeader(for restaurant: Restaurant) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.md) {
                SymbolThumbnail(symbol: restaurant.symbol, hex: restaurant.coverHex, size: 56)
                VStack(alignment: .leading, spacing: 2) {
                    Text(restaurant.name)
                        .font(AppFont.headline())
                        .foregroundStyle(AppColor.textPrimary)
                    Text(restaurant.location.isEmpty ? restaurant.category : restaurant.location)
                        .font(AppFont.subheadline())
                        .foregroundStyle(AppColor.textSecondary)
                    HStack(spacing: 4) {
                        Circle()
                            .fill(restaurant.isOpen ? AppColor.success : AppColor.danger)
                            .frame(width: 8, height: 8)
                        Text(restaurant.isOpen ? "Abierto" : "Cerrado")
                            .font(AppFont.caption())
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }
                Spacer()
            }
            if !restaurant.tags.isEmpty {
                HStack(spacing: AppSpacing.xs) {
                    ForEach(restaurant.tags, id: \.self) { tag in
                        TagChip(text: tag)
                    }
                }
            }
            AppButton(title: "Editar local", icon: "pencil", kind: .secondary) {
                showEditRestaurant = true
            }
        }
        .cardStyle()
    }

    // MARK: - Estadísticas

    private func statsRow(for restaurant: Restaurant) -> some View {
        let items = catalog.products(for: restaurant.id)
        let received = orders.orders
        return HStack(spacing: AppSpacing.sm) {
            StatCard(value: "\(items.count)", label: "Productos", icon: "fork.knife", hex: 0xFF7426)
            StatCard(value: "\(items.filter { !$0.isAvailable }.count)", label: "Agotados", icon: "xmark.circle.fill", hex: 0xE23744)
            StatCard(value: "\(received.filter { $0.status != .completed }.count)", label: "Pendientes", icon: "clock.fill", hex: 0x0B3D91)
        }
    }

    // MARK: - Avisos (notificaciones)

    @ViewBuilder
    private func notificationsSection(for restaurant: Restaurant) -> some View {
        let items = orders.notifications
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                SectionHeader(title: "Avisos")
                ForEach(items) { notification in
                    AdminNotificationRow(notification: notification)
                }
            }
            .task { await orders.markAllNotificationsRead() }
        }
    }

    // MARK: - Pedidos recibidos

    private func receivedOrdersSection(for restaurant: Restaurant) -> some View {
        let received = orders.orders
        return VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionHeader(title: "Pedidos recibidos")
            if received.isEmpty {
                Text("Aún no hay pedidos.")
                    .font(AppFont.subheadline())
                    .foregroundStyle(AppColor.textSecondary)
                    .padding(.vertical, AppSpacing.sm)
            } else {
                ForEach(received) { order in
                    AdminOrderRow(order: order, onStatusChange: { newStatus in
                        Task {
                            if !(await orders.updateStatus(order, to: newStatus)) {
                                showStatusError = true
                            }
                        }
                    }, onCancel: {
                        Task {
                            if !(await orders.cancelByCustomer(order)) {
                                showStatusError = true
                            }
                        }
                    })
                }
            }
        }
    }

    // MARK: - Productos

    private func productsSection(for restaurant: Restaurant) -> some View {
        let items = catalog.products(for: restaurant.id)
        return VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionHeader(title: "Mis productos")
            ForEach(items) { product in
                AdminProductRow(
                    product: product,
                    onToggle: { Task { await catalog.toggleAvailability(product) } },
                    onEdit: { productFormMode = .edit(product) },
                    onDelete: { productToDelete = product }
                )
            }
        }
    }
}

// MARK: - Tarjeta de estadística

private struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let hex: UInt

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Color(hex: hex))
            Text(value)
                .font(AppFont.title())
                .foregroundStyle(AppColor.textPrimary)
            Text(label)
                .font(AppFont.caption())
                .foregroundStyle(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: AppSpacing.sm)
    }
}

// MARK: - Fila de aviso (admin)

private struct AdminNotificationRow: View {
    let notification: AppNotification

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            ZStack {
                Circle()
                    .fill(Color(hex: notification.tintHex).opacity(0.14))
                    .frame(width: 40, height: 40)
                Image(systemName: notification.iconName)
                    .font(.system(size: 18))
                    .foregroundStyle(Color(hex: notification.tintHex))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(notification.title)
                    .font(AppFont.callout())
                    .foregroundStyle(AppColor.textPrimary)
                Text(notification.message)
                    .font(AppFont.subheadline())
                    .foregroundStyle(AppColor.textSecondary)
                Text(notification.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(AppFont.caption())
                    .foregroundStyle(AppColor.textPlaceholder)
            }
            Spacer()
            if !notification.isRead {
                Circle()
                    .fill(AppColor.orange)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
            }
        }
        .cardStyle(padding: AppSpacing.sm)
    }
}

// MARK: - Fila de producto (admin)

private struct AdminProductRow: View {
    let product: Product
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            SymbolThumbnail(symbol: product.symbol, hex: product.isAvailable ? 0xFF7426 : 0x9CA3AF, size: 56)
            VStack(alignment: .leading, spacing: 2) {
                Text(product.name)
                    .font(AppFont.callout())
                    .foregroundStyle(AppColor.textPrimary)
                Text(product.price.asCurrency)
                    .font(AppFont.subheadline())
                    .foregroundStyle(AppColor.textSecondary)
                if !product.isAvailable {
                    TagChip(text: "Agotado", foreground: AppColor.danger, background: AppColor.danger.opacity(0.12))
                }
            }
            Spacer()
            Menu {
                Button {
                    onToggle()
                } label: {
                    Label(product.isAvailable ? "Marcar agotado" : "Marcar disponible",
                          systemImage: product.isAvailable ? "xmark.circle" : "checkmark.circle")
                }
                Button(action: onEdit) {
                    Label("Editar", systemImage: "pencil")
                }
                Button(role: .destructive, action: onDelete) {
                    Label("Eliminar", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
        .cardStyle(padding: AppSpacing.sm)
        .opacity(product.isAvailable ? 1 : 0.7)
    }
}

// MARK: - Fila de pedido (admin)

private struct AdminOrderRow: View {
    let order: Order
    let onStatusChange: (OrderStatus) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(order.folio)
                        .font(AppFont.callout())
                        .foregroundStyle(AppColor.textPrimary)
                    Text("Recogida \(order.pickupCode) · \(order.itemCount) productos")
                        .font(AppFont.caption())
                        .foregroundStyle(AppColor.textSecondary)
                }
                Spacer()
                Text(order.total.asCurrency)
                    .font(AppFont.price())
                    .foregroundStyle(AppColor.textPrimary)
            }

            Text(order.lines.map { "\($0.quantity)× \($0.productName)" }.joined(separator: ", "))
                .font(AppFont.caption())
                .foregroundStyle(AppColor.textSecondary)
                .lineLimit(2)

            HStack(spacing: AppSpacing.sm) {
                Menu {
                    ForEach(OrderStatus.allCases.filter { $0 != .cancelled }) { status in
                        Button {
                            onStatusChange(status)
                        } label: {
                            Label(status.rawValue, systemImage: status.icon)
                        }
                    }
                } label: {
                    HStack {
                        StatusBadge(status: order.status)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }

                if order.status == .pending {
                    Button(role: .destructive) {
                        onCancel()
                    } label: {
                        Label("Cancelar pedido", systemImage: "xmark.circle.fill")
                            .font(AppFont.caption())
                            .foregroundStyle(AppColor.danger)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .cardStyle(padding: AppSpacing.sm)
    }
}

#Preview {
    AdminDashboardView()
        .environmentObject(SessionStore())
        .environmentObject(CatalogStore())
        .environmentObject(OrderStore())
}
