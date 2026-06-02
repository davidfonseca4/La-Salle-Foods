//
//  CatalogStore.swift
//  LaSalleFoods
//
//  Fuente de verdad de locales y productos. Expone operaciones de
//  consulta para alumnos y de administración (CRUD) para dueños.
//

import SwiftUI

@MainActor
final class CatalogStore: ObservableObject {
    @Published var restaurants: [Restaurant]
    @Published var products: [Product]

    init(
        restaurants: [Restaurant] = MockData.restaurants,
        products: [Product] = MockData.products
    ) {
        self.restaurants = restaurants
        self.products = products
    }

    // MARK: - Consultas

    func restaurant(by id: UUID) -> Restaurant? {
        restaurants.first { $0.id == id }
    }

    func products(for restaurantID: UUID) -> [Product] {
        products.filter { $0.restaurantID == restaurantID }
    }

    /// Productos agrupados por categoría para un local (solo categorías con items).
    func groupedProducts(for restaurantID: UUID) -> [(category: ProductCategory, items: [Product])] {
        let items = products(for: restaurantID)
        return ProductCategory.allCases.compactMap { category in
            let matching = items.filter { $0.category == category }
            return matching.isEmpty ? nil : (category, matching)
        }
    }

    func popularProducts(limit: Int = 6) -> [Product] {
        products.filter { $0.isPopular && $0.isAvailable }.prefix(limit).map { $0 }
    }

    // MARK: - Administración (panel de dueño)

    func addProduct(_ product: Product) {
        products.append(product)
    }

    func updateProduct(_ product: Product) {
        guard let index = products.firstIndex(where: { $0.id == product.id }) else { return }
        products[index] = product
    }

    func deleteProduct(_ product: Product) {
        products.removeAll { $0.id == product.id }
    }

    func toggleAvailability(_ product: Product) {
        guard let index = products.firstIndex(where: { $0.id == product.id }) else { return }
        products[index].isAvailable.toggle()
    }

    /// Registra un nuevo local (usado al crear una cuenta de dueño) y lo
    /// devuelve para asociarlo a su usuario.
    @discardableResult
    func addRestaurant(
        name: String,
        category: String,
        location: String,
        symbol: String = "storefront.fill",
        coverHex: UInt = 0xFF7426
    ) -> Restaurant {
        let restaurant = Restaurant(
            name: name,
            category: category,
            description: "Nuevo local en el campus.",
            symbol: symbol,
            coverHex: coverHex,
            rating: 0,
            reviewCount: 0,
            prepTimeMinutes: 8...15,
            location: location,
            tags: ["Nuevo"]
        )
        restaurants.insert(restaurant, at: 0)
        return restaurant
    }
}
