//
//  OrderStore.swift
//  LaSalleFoods
//
//  Almacena los pedidos visibles para la sesión activa: para el alumno,
//  su historial; para el dueño, los pedidos recibidos en su local. RLS
//  ya filtra esto del lado del servidor (vía `/api/orders`), así que
//  basta una sola consulta.
//

import SwiftUI

@MainActor
final class OrderStore: ObservableObject {
    @Published private(set) var orders: [Order] = []
    @Published private(set) var notifications: [AppNotification] = []
    @Published var errorMessage: String?
    @Published private(set) var isLoading = false

    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    // MARK: - Carga

    /// Trae los pedidos visibles para el usuario activo (RLS decide si son
    /// los propios del alumno o los recibidos por el local del dueño).
    func loadOrders() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            orders = try await APIClient.get("orders")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadNotifications() async {
        do {
            notifications = try await APIClient.get("notifications")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Consultas

    func search(_ query: String) -> [Order] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return orders }
        let lower = query.lowercased()
        return orders.filter {
            $0.folio.lowercased().contains(lower) ||
            $0.restaurantName.lowercased().contains(lower) ||
            $0.lines.contains { $0.productName.lowercased().contains(lower) }
        }
    }

    /// Devuelve la versión vigente de un pedido (refleja cambios del local).
    func order(by id: UUID) -> Order? {
        orders.first { $0.id == id }
    }

    // MARK: - Creación

    private struct PlaceOrderParams: Encodable {
        let pRestaurantID: UUID
        let pPaymentMethod: PaymentMethod
        let pItems: [ItemPayload]

        struct ItemPayload: Encodable {
            let productID: UUID
            let quantity: Int
            let notes: String?

            enum CodingKeys: String, CodingKey {
                case productID = "product_id"
                case quantity, notes
            }
        }

        enum CodingKeys: String, CodingKey {
            case pRestaurantID = "p_restaurant_id"
            case pPaymentMethod = "p_payment_method"
            case pItems = "p_items"
        }
    }

    private struct PlacedOrder: Decodable {
        let id: UUID
        let folio: String
        let status: OrderStatus
        let createdAt: Date
        let pickupCode: String

        enum CodingKeys: String, CodingKey {
            case id, folio, status
            case createdAt = "created_at"
            case pickupCode = "pickup_code"
        }
    }

    /// Crea un pedido a partir del carrito vía `POST /api/orders` (folio y
    /// código de recolección los arma el backend) y lo agrega al historial local.
    func placeOrder(items: [CartItem], restaurant: Restaurant, paymentMethod: PaymentMethod) async -> Order? {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            let params = PlaceOrderParams(
                pRestaurantID: restaurant.id,
                pPaymentMethod: paymentMethod,
                pItems: items.map {
                    PlaceOrderParams.ItemPayload(
                        productID: $0.product.id,
                        quantity: $0.quantity,
                        notes: $0.notes.isEmpty ? nil : $0.notes
                    )
                }
            )

            let placed: PlacedOrder = try await APIClient.post("orders", body: params)

            let lines = items.map {
                OrderLine(
                    productName: $0.product.name,
                    quantity: $0.quantity,
                    unitPrice: $0.product.price,
                    notes: $0.notes.isEmpty ? nil : $0.notes
                )
            }

            let order = Order(
                id: placed.id,
                folio: placed.folio,
                restaurantID: restaurant.id,
                restaurantName: restaurant.name,
                lines: lines,
                paymentMethod: paymentMethod,
                status: placed.status,
                createdAt: placed.createdAt,
                pickupCode: placed.pickupCode
            )
            orders.insert(order, at: 0)
            return order
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    // MARK: - Administración (dueño)

    private struct UpdateStatusParams: Encodable {
        let pNewStatus: OrderStatus
        enum CodingKeys: String, CodingKey {
            case pNewStatus = "p_new_status"
        }
    }

    private struct OrderStatusRow: Decodable {
        let id: UUID
        let status: OrderStatus
    }

    @discardableResult
    func updateStatus(_ order: Order, to status: OrderStatus) async -> Bool {
        errorMessage = nil
        do {
            let updated: OrderStatusRow = try await APIClient.post("orders/\(order.id)/status", body: UpdateStatusParams(pNewStatus: status))
            if let index = orders.firstIndex(where: { $0.id == updated.id }) {
                orders[index].status = updated.status
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Cancelación por el comprador

    /// Cancela un pedido solo si todavía puede cancelarse (lo valida el backend).
    /// Devuelve `true` si la cancelación se realizó.
    @discardableResult
    func cancelByCustomer(_ order: Order) async -> Bool {
        errorMessage = nil
        do {
            let cancelled: OrderStatusRow = try await APIClient.post("orders/\(order.id)/cancel", body: EmptyBody())
            if let index = orders.firstIndex(where: { $0.id == cancelled.id }) {
                orders[index].status = cancelled.status
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Notificaciones

    /// Marca como leídos todos los avisos sin leer del usuario activo.
    func markAllNotificationsRead() async {
        for notification in notifications where !notification.isRead {
            do {
                let updated: AppNotification = try await APIClient.post("notifications/\(notification.id)/read", body: EmptyBody())
                if let index = notifications.firstIndex(where: { $0.id == updated.id }) {
                    notifications[index] = updated
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
