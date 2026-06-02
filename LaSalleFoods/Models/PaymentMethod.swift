//
//  PaymentMethod.swift
//  LaSalleFoods
//
//  Métodos de pago contemplados en la documentación:
//  efectivo al recoger y tarjeta (débito/crédito).
//

import Foundation

enum PaymentMethod: String, Codable, CaseIterable, Identifiable {
    case cash = "Efectivo al recoger"
    case card = "Tarjeta de débito/crédito"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .cash: return "banknote.fill"
        case .card: return "creditcard.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .cash: return "Paga cuando recojas tu pedido"
        case .card: return "Pago seguro con tarjeta"
        }
    }
}
