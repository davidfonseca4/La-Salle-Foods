//
//  AppNotification.swift
//  LaSalleFoods
//
//  Aviso dentro de la app. Sirve tanto para el dueño del local (ej. el
//  comprador canceló un pedido) como para el alumno (ej. su pedido ya
//  está listo para recoger). El destinatario es siempre `profiles.id`,
//  sin importar el rol — el backend garantiza que cada quien solo vea lo suyo.
//

import Foundation

struct AppNotification: Identifiable, Decodable, Hashable {
    let id: UUID
    var recipientID: UUID
    var orderID: UUID
    var relatedStatus: OrderStatus?
    var title: String
    var message: String
    var createdAt: Date
    var isRead: Bool

    init(
        id: UUID = UUID(),
        recipientID: UUID,
        orderID: UUID,
        relatedStatus: OrderStatus? = nil,
        title: String,
        message: String,
        createdAt: Date = .now,
        isRead: Bool = false
    ) {
        self.id = id
        self.recipientID = recipientID
        self.orderID = orderID
        self.relatedStatus = relatedStatus
        self.title = title
        self.message = message
        self.createdAt = createdAt
        self.isRead = isRead
    }

    /// El backend solo guarda `related_status`; ícono y color se derivan
    /// en el momento desde las computed properties que ya existen en
    /// `OrderStatus` — no se duplican datos de presentación.
    var iconName: String {
        relatedStatus?.icon ?? "bell.fill"
    }

    var tintHex: UInt {
        relatedStatus?.colorHex ?? 0x0B3D91
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, message
        case recipientID = "recipient_id"
        case orderID = "order_id"
        case relatedStatus = "related_status"
        case createdAt = "created_at"
        case isRead = "is_read"
    }
}
