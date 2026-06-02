//
//  Restaurant.swift
//  LaSalleFoods
//
//  Representa un "local" o puesto de comida dentro del campus.
//

import Foundation

struct Restaurant: Identifiable, Codable, Hashable {
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
}
