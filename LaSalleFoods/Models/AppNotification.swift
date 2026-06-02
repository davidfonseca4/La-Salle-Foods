//
//  AppNotification.swift
//  LaSalleFoods
//
//  Aviso dentro de la app. Sirve tanto para el dueño del local (ej. el
//  comprador canceló un pedido) como para el alumno (ej. su pedido ya
//  está listo para recoger). El destinatario se identifica con
//  `audienceID`: el id del local para el dueño, o el nombre del cliente
//  para el alumno.
//

import Foundation

struct AppNotification: Identifiable, Codable, Hashable {
    let id: UUID
    var audienceID: String
    var title: String
    var message: String
    var orderFolio: String
    var iconName: String
    var tintHex: UInt
    var createdAt: Date
    var isRead: Bool

    init(
        id: UUID = UUID(),
        audienceID: String,
        title: String,
        message: String,
        orderFolio: String,
        iconName: String,
        tintHex: UInt,
        createdAt: Date = .now,
        isRead: Bool = false
    ) {
        self.id = id
        self.audienceID = audienceID
        self.title = title
        self.message = message
        self.orderFolio = orderFolio
        self.iconName = iconName
        self.tintHex = tintHex
        self.createdAt = createdAt
        self.isRead = isRead
    }
}
