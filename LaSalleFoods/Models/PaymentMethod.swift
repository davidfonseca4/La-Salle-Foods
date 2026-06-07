//
//  PaymentMethod.swift
//  LaSalleFoods
//
//  Métodos de pago contemplados en la documentación:
//  efectivo al recoger y tarjeta (débito/crédito).
//

import Foundation

enum PaymentMethod: String, CaseIterable, Identifiable {
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

    // MARK: - Mapeo con el enum `payment_method` del backend
    //
    // El front usa descripciones en español como `rawValue`, pero el
    // backend guarda valores en inglés en minúsculas (`cash`, `card`).
    // No puede derivarse `Codable` desde `rawValue`: se mapea a mano.

    private var backendValue: String {
        switch self {
        case .cash: return "cash"
        case .card: return "card"
        }
    }

    private init?(backendValue: String) {
        switch backendValue {
        case "cash": self = .cash
        case "card": self = .card
        default: return nil
        }
    }
}

extension PaymentMethod: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        guard let method = PaymentMethod(backendValue: raw) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Método de pago desconocido: \(raw)"
            )
        }
        self = method
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(backendValue)
    }
}
