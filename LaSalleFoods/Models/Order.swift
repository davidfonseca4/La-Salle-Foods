//
//  Order.swift
//  LaSalleFoods
//
//  Pedido realizado por un alumno. Incluye el estado para soportar el
//  seguimiento del pedido y el historial descritos en la documentación.
//

import Foundation

enum OrderStatus: String, Codable, CaseIterable, Identifiable {
    case pending = "Pendiente"
    case preparing = "En preparación"
    case ready = "Listo para recoger"
    case completed = "Entregado"
    case cancelled = "Cancelado"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .pending: return "clock.fill"
        case .preparing: return "flame.fill"
        case .ready: return "bag.fill.badge.plus"
        case .completed: return "checkmark.seal.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }

    var colorHex: UInt {
        switch self {
        case .pending: return 0xFFC107
        case .preparing: return 0xFF7426
        case .ready: return 0x1FAA59
        case .completed: return 0x1FAA59
        case .cancelled: return 0xE23744
        }
    }

    /// Paso dentro del flujo (para barras de progreso).
    var step: Int {
        switch self {
        case .pending: return 0
        case .preparing: return 1
        case .ready: return 2
        case .completed: return 3
        case .cancelled: return -1
        }
    }
}

struct OrderLine: Identifiable, Codable, Hashable {
    let id: UUID
    var productName: String
    var quantity: Int
    var unitPrice: Double

    init(id: UUID = UUID(), productName: String, quantity: Int, unitPrice: Double) {
        self.id = id
        self.productName = productName
        self.quantity = quantity
        self.unitPrice = unitPrice
    }

    var subtotal: Double { unitPrice * Double(quantity) }
}

struct Order: Identifiable, Codable, Hashable {
    let id: UUID
    /// Folio corto legible para el alumno (ej. "LSF-2048").
    var folio: String
    var restaurantID: UUID
    var restaurantName: String
    var customerName: String
    var lines: [OrderLine]
    var paymentMethod: PaymentMethod
    var status: OrderStatus
    var createdAt: Date
    var pickupCode: String

    init(
        id: UUID = UUID(),
        folio: String,
        restaurantID: UUID,
        restaurantName: String,
        customerName: String,
        lines: [OrderLine],
        paymentMethod: PaymentMethod,
        status: OrderStatus = .pending,
        createdAt: Date = .now,
        pickupCode: String
    ) {
        self.id = id
        self.folio = folio
        self.restaurantID = restaurantID
        self.restaurantName = restaurantName
        self.customerName = customerName
        self.lines = lines
        self.paymentMethod = paymentMethod
        self.status = status
        self.createdAt = createdAt
        self.pickupCode = pickupCode
    }

    var total: Double {
        lines.reduce(0) { $0 + $1.subtotal }
    }

    var itemCount: Int {
        lines.reduce(0) { $0 + $1.quantity }
    }

    /// El comprador solo puede cancelar mientras el pedido siga "Pendiente".
    /// Una vez que el local lo pasa a "En preparación" (o más adelante),
    /// ya no se permite cancelar.
    var canBeCancelledByCustomer: Bool {
        status == .pending
    }
}
