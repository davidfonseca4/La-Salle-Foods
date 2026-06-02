//
//  OrderStore.swift
//  LaSalleFoods
//
//  Almacena los pedidos. Para el alumno expone su historial; para el dueño,
//  los pedidos recibidos en su local.
//

import SwiftUI

@MainActor
final class OrderStore: ObservableObject {
    @Published private(set) var orders: [Order]
    /// Avisos dentro de la app (para el local y para el alumno).
    @Published private(set) var notifications: [AppNotification] = []

    private var folioCounter = 2049

    init(orders: [Order] = MockData.sampleOrders(for: MockData.studentUser.name)) {
        self.orders = orders
    }

    // MARK: - Consultas

    func orders(forCustomer name: String) -> [Order] {
        orders
            .filter { $0.customerName == name }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func orders(forRestaurant id: UUID) -> [Order] {
        orders
            .filter { $0.restaurantID == id }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func search(_ query: String, customerName: String) -> [Order] {
        let base = orders(forCustomer: customerName)
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return base }
        let lower = query.lowercased()
        return base.filter {
            $0.folio.lowercased().contains(lower) ||
            $0.restaurantName.lowercased().contains(lower) ||
            $0.lines.contains { $0.productName.lowercased().contains(lower) }
        }
    }

    // MARK: - Creación

    /// Crea un pedido a partir del carrito y lo agrega al historial.
    @discardableResult
    func placeOrder(
        items: [CartItem],
        restaurant: Restaurant,
        customerName: String,
        paymentMethod: PaymentMethod
    ) -> Order {
        let lines = items.map {
            OrderLine(
                productName: $0.product.name,
                quantity: $0.quantity,
                unitPrice: $0.product.price
            )
        }
        let order = Order(
            folio: "LSF-\(folioCounter)",
            restaurantID: restaurant.id,
            restaurantName: restaurant.name,
            customerName: customerName,
            lines: lines,
            paymentMethod: paymentMethod,
            status: .pending,
            pickupCode: Self.randomPickupCode()
        )
        folioCounter += 1
        orders.insert(order, at: 0)
        return order
    }

    // MARK: - Administración (dueño)

    func updateStatus(_ order: Order, to status: OrderStatus) {
        guard let index = orders.firstIndex(where: { $0.id == order.id }) else { return }
        guard orders[index].status != status else { return }
        orders[index].status = status
        notifyCustomerOfStatusChange(orders[index])
    }

    /// Avisa al alumno cuando el local cambia el estado de su pedido.
    private func notifyCustomerOfStatusChange(_ order: Order) {
        let title: String
        let message: String
        switch order.status {
        case .preparing:
            title = "¡Tu pedido está en preparación!"
            message = "\(order.restaurantName) ya está preparando tu pedido \(order.folio)."
        case .ready:
            title = "¡Tu pedido está listo!"
            message = "Recoge tu pedido \(order.folio) en \(order.restaurantName). Código: \(order.pickupCode)."
        case .completed:
            title = "Pedido entregado"
            message = "¡Disfruta! Tu pedido \(order.folio) fue entregado."
        case .cancelled:
            title = "Pedido cancelado por el local"
            message = "\(order.restaurantName) canceló tu pedido \(order.folio)."
        case .pending:
            return
        }
        notifications.insert(
            AppNotification(
                audienceID: order.customerName,
                title: title,
                message: message,
                orderFolio: order.folio,
                iconName: order.status.icon,
                tintHex: order.status.colorHex
            ),
            at: 0
        )
    }

    /// Devuelve la versión vigente de un pedido (refleja cambios del local).
    func order(by id: UUID) -> Order? {
        orders.first { $0.id == id }
    }

    // MARK: - Cancelación por el comprador

    /// Cancela un pedido solo si todavía puede cancelarse (sigue pendiente).
    /// Devuelve `true` si la cancelación se realizó.
    @discardableResult
    func cancelByCustomer(_ order: Order) -> Bool {
        guard let index = orders.firstIndex(where: { $0.id == order.id }),
              orders[index].canBeCancelledByCustomer else {
            return false
        }
        orders[index].status = .cancelled

        let cancelled = orders[index]
        notifications.insert(
            AppNotification(
                audienceID: cancelled.restaurantID.uuidString,
                title: "Pedido cancelado",
                message: "\(cancelled.customerName) canceló el pedido \(cancelled.folio).",
                orderFolio: cancelled.folio,
                iconName: "xmark.circle.fill",
                tintHex: OrderStatus.cancelled.colorHex
            ),
            at: 0
        )
        return true
    }

    // MARK: - Notificaciones (consultas por destinatario)

    func notifications(forAudience audienceID: String) -> [AppNotification] {
        notifications
            .filter { $0.audienceID == audienceID }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func unreadCount(forAudience audienceID: String) -> Int {
        notifications.filter { $0.audienceID == audienceID && !$0.isRead }.count
    }

    func markNotificationsRead(forAudience audienceID: String) {
        for i in notifications.indices where notifications[i].audienceID == audienceID {
            notifications[i].isRead = true
        }
    }

    private static func randomPickupCode() -> String {
        let letter = "ABCDEFGH".randomElement() ?? "A"
        let number = Int.random(in: 10...99)
        return "\(letter)\(number)"
    }
}
