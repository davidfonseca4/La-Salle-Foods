//
//  Product.swift
//  LaSalleFoods
//
//  Producto del menú de un local. Incluye disponibilidad para soportar
//  la funcionalidad de "inhabilitar productos agotados" del panel de dueño.
//

import Foundation

struct Product: Identifiable, Codable, Hashable {
    let id: UUID
    var restaurantID: UUID
    var name: String
    var description: String
    var price: Double
    var category: ProductCategory
    var symbol: String
    /// Indica si el producto está disponible (no agotado / no inhabilitado).
    var isAvailable: Bool
    var isPopular: Bool

    init(
        id: UUID = UUID(),
        restaurantID: UUID,
        name: String,
        description: String,
        price: Double,
        category: ProductCategory,
        symbol: String = "fork.knife",
        isAvailable: Bool = true,
        isPopular: Bool = false
    ) {
        self.id = id
        self.restaurantID = restaurantID
        self.name = name
        self.description = description
        self.price = price
        self.category = category
        self.symbol = symbol
        self.isAvailable = isAvailable
        self.isPopular = isPopular
    }
}

enum ProductCategory: String, Codable, CaseIterable, Identifiable {
    case popular = "Lo más pedido"
    case mains = "Platillos"
    case snacks = "Antojitos"
    case drinks = "Bebidas"
    case desserts = "Postres"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .popular: return "flame.fill"
        case .mains: return "fork.knife"
        case .snacks: return "takeoutbag.and.cup.and.straw.fill"
        case .drinks: return "cup.and.saucer.fill"
        case .desserts: return "birthday.cake.fill"
        }
    }
}
