//
//  Product.swift
//  LaSalleFoods
//
//  Producto del menú de un local. Incluye disponibilidad para soportar
//  la funcionalidad de "inhabilitar productos agotados" del panel de dueño.
//

import Foundation

struct Product: Identifiable, Decodable, Hashable {
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

    // MARK: - Decodificación desde Supabase
    //
    // El backend referencia la categoría por `category_id` (FK a
    // `product_categories`); aquí se obtiene su nombre vía join
    // (`select("*, product_categories(name)")`) y se mapea al `rawValue`
    // del enum, que coincide textualmente con `product_categories.name`.

    private enum CodingKeys: String, CodingKey {
        case id, name, description, price, symbol
        case restaurantID = "restaurant_id"
        case categoryRelation = "product_categories"
        case isAvailable = "is_available"
        case isPopular = "is_popular"
    }

    private struct CategoryRelation: Decodable { let name: String }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        restaurantID = try container.decode(UUID.self, forKey: .restaurantID)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        price = try container.decode(Double.self, forKey: .price)
        symbol = try container.decode(String.self, forKey: .symbol)
        isAvailable = try container.decode(Bool.self, forKey: .isAvailable)
        isPopular = try container.decode(Bool.self, forKey: .isPopular)

        let relation = try container.decode(CategoryRelation.self, forKey: .categoryRelation)
        guard let mapped = ProductCategory(rawValue: relation.name) else {
            throw DecodingError.dataCorruptedError(
                forKey: .categoryRelation,
                in: container,
                debugDescription: "Categoría de producto desconocida: \(relation.name)"
            )
        }
        category = mapped
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
