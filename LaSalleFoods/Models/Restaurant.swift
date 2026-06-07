//
//  Restaurant.swift
//  LaSalleFoods
//
//  Representa un "local" o puesto de comida dentro del campus.
//

import Foundation

struct Restaurant: Identifiable, Decodable, Hashable {
    let id: UUID
    var name: String
    var category: String
    var description: String
    /// Nombre del símbolo SF Symbol usado como portada (front sin assets reales).
    var symbol: String
    /// Color de fondo de la portada (entero hexadecimal).
    var coverHex: UInt
    var rating: Double
    var reviewCount: Int
    /// Tiempo estimado de preparación en minutos (rango).
    var prepTimeMinutes: ClosedRange<Int>
    var location: String
    var isOpen: Bool
    /// Etiquetas como "Sin filas", "Popular", etc.
    var tags: [String]

    init(
        id: UUID = UUID(),
        name: String,
        category: String,
        description: String,
        symbol: String,
        coverHex: UInt,
        rating: Double,
        reviewCount: Int,
        prepTimeMinutes: ClosedRange<Int>,
        location: String,
        isOpen: Bool = true,
        tags: [String] = []
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.description = description
        self.symbol = symbol
        self.coverHex = coverHex
        self.rating = rating
        self.reviewCount = reviewCount
        self.prepTimeMinutes = prepTimeMinutes
        self.location = location
        self.isOpen = isOpen
        self.tags = tags
    }

    var prepTimeText: String {
        "\(prepTimeMinutes.lowerBound)–\(prepTimeMinutes.upperBound) min"
    }

    // MARK: - Decodificación desde Supabase
    //
    // El backend separa lo que aquí es un solo `category: String` en una
    // relación (`restaurant_categories`) y `tags` en una tabla puente
    // (`restaurant_tags` -> `tags`); además guarda el rango de preparación
    // como dos columnas (`prep_time_min`/`prep_time_max`) y el color como
    // texto hexadecimal con "#" (`cover_color`). Se arman aquí para
    // conservar el modelo de presentación que ya usa el resto de la app.

    private enum CodingKeys: String, CodingKey {
        case id, name, description, location, symbol, rating
        case categoryRelation = "restaurant_categories"
        case coverColor = "cover_color"
        case reviewCount = "review_count"
        case prepTimeMin = "prep_time_min"
        case prepTimeMax = "prep_time_max"
        case isOpen = "is_open"
        case tagsRelation = "restaurant_tags"
    }

    private struct CategoryRelation: Decodable { let name: String }
    private struct TagRelation: Decodable {
        struct Tag: Decodable { let name: String }
        let tags: Tag
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        location = try container.decodeIfPresent(String.self, forKey: .location) ?? ""
        symbol = try container.decode(String.self, forKey: .symbol)
        isOpen = try container.decode(Bool.self, forKey: .isOpen)
        rating = try container.decode(Double.self, forKey: .rating)
        reviewCount = try container.decode(Int.self, forKey: .reviewCount)

        let hex = try container.decode(String.self, forKey: .coverColor)
            .trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        coverHex = UInt(hex, radix: 16) ?? 0xFF7426

        let prepMin = try container.decode(Int.self, forKey: .prepTimeMin)
        let prepMax = try container.decode(Int.self, forKey: .prepTimeMax)
        prepTimeMinutes = prepMin...max(prepMin, prepMax)

        category = (try? container.decode(CategoryRelation.self, forKey: .categoryRelation))?.name ?? ""
        let tagRelations = (try? container.decode([TagRelation].self, forKey: .tagsRelation)) ?? []
        tags = tagRelations.map(\.tags.name)
    }
}
