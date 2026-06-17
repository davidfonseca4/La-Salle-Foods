//
//  Order.swift
//  LaSalleFoods
//
//  Pedido realizado por un alumno. Incluye el estado para soportar el
//  seguimiento del pedido y el historial descritos en la documentación.
//

import Foundation

enum OrderStatus: String, CaseIterable, Identifiable {
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

    // MARK: - Mapeo con el enum `order_status` del backend
    //
    // El front usa los nombres en español como `rawValue` para mostrarlos
    // directamente en la UI, pero el backend guarda valores en inglés en
    // minúsculas (`pending`, `preparing`, `ready`, `completed`, `cancelled`).
    // Por eso no puede derivarse `Codable` desde `rawValue`: se mapea a mano.

    private var backendValue: String {
        switch self {
        case .pending: return "pending"
        case .preparing: return "preparing"
        case .ready: return "ready"
        case .completed: return "completed"
        case .cancelled: return "cancelled"
        }
    }

    private init?(backendValue: String) {
        switch backendValue {
        case "pending": self = .pending
        case "preparing": self = .preparing
        case "ready": self = .ready
        case "completed": self = .completed
        case "cancelled": self = .cancelled
        default: return nil
        }
    }
}

extension OrderStatus: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        guard let status = OrderStatus(backendValue: raw) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Estado de pedido desconocido: \(raw)"
            )
        }
        self = status
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(backendValue)
    }
}

struct OrderLine: Identifiable, Decodable, Hashable {
    let id: UUID
    var productName: String
    var quantity: Int
    var unitPrice: Double
    var notes: String?

    init(id: UUID = UUID(), productName: String, quantity: Int, unitPrice: Double, notes: String? = nil) {
        self.id = id
        self.productName = productName
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.notes = notes
    }

    var subtotal: Double { unitPrice * Double(quantity) }

    private enum CodingKeys: String, CodingKey {
        case id, quantity, notes
        case productName = "product_name"
        case unitPrice = "unit_price"
    }
}

struct Order: Identifiable, Decodable, Hashable {
    let id: UUID
    /// Folio corto legible para el alumno (ej. "LSF-2048"), generado por el backend.
    var folio: String
    var restaurantID: UUID
    /// Obtenido vía join a `restaurants` al consultar (no se guarda como columna).
    var restaurantName: String
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

    // MARK: - Decodificación desde la API

    private enum CodingKeys: String, CodingKey {
        case id, folio, lines, status
        case restaurantID = "restaurant_id"
        case restaurantRelation = "restaurants"
        case paymentMethod = "payment_method"
        case createdAt = "created_at"
        case pickupCode = "pickup_code"
        case orderLinesRelation = "order_lines"
    }

    private struct RestaurantRelation: Decodable { let name: String }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        folio = try container.decode(String.self, forKey: .folio)
        restaurantID = try container.decode(UUID.self, forKey: .restaurantID)
        restaurantName = (try? container.decode(RestaurantRelation.self, forKey: .restaurantRelation))?.name ?? ""
        lines = try container.decodeIfPresent([OrderLine].self, forKey: .orderLinesRelation) ?? []
        paymentMethod = try container.decode(PaymentMethod.self, forKey: .paymentMethod)
        status = try container.decode(OrderStatus.self, forKey: .status)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        pickupCode = try container.decode(String.self, forKey: .pickupCode)
    }
}
