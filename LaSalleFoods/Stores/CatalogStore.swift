//
//  CatalogStore.swift
//  LaSalleFoods
//
//  Fuente de verdad de locales y productos. Expone operaciones de
//  consulta para alumnos y de administración (CRUD) para dueños,
//  todas respaldadas por Supabase (RLS valida los permisos reales).
//

import SwiftUI
import Supabase

@MainActor
final class CatalogStore: ObservableObject {
    @Published private(set) var restaurants: [Restaurant] = []
    @Published private(set) var products: [Product] = []
    @Published var errorMessage: String?
    @Published private(set) var isLoading = false

    private let client = SupabaseManager.client

    private static let restaurantSelection = "*, restaurant_categories(name), restaurant_tags(tags(name))"
    private static let productSelection = "*, product_categories(name)"

    /// Carga locales y productos visibles según RLS (locales activos y
    /// productos de locales activos para alumnos; los propios para dueños).
    func loadCatalog() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            async let restaurantsTask: [Restaurant] = client
                .from("restaurants")
                .select(Self.restaurantSelection)
                .execute()
                .value
            async let productsTask: [Product] = client
                .from("products")
                .select(Self.productSelection)
                .execute()
                .value

            restaurants = try await restaurantsTask
            products = try await productsTask
        } catch {
            errorMessage = error.localizedDescription
        }
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

    struct RestaurantCategory: Identifiable, Decodable {
        let id: Int
        let name: String
    }

    func loadRestaurantCategories() async -> [RestaurantCategory] {
        (try? await client
            .from("restaurant_categories")
            .select("id, name")
            .execute()
            .value) ?? []
    }

    // MARK: - Administración (panel de dueño)

    func addProduct(
        restaurantID: UUID,
        name: String,
        description: String,
        price: Double,
        category: ProductCategory,
        symbol: String,
        isAvailable: Bool,
        isPopular: Bool
    ) async {
        errorMessage = nil
        do {
            guard let categoryID = try await categoryID(forName: category.rawValue) else {
                errorMessage = "No se encontró la categoría seleccionada."
                return
            }

            struct NewProduct: Encodable {
                let restaurantID: UUID
                let categoryID: Int
                let name: String
                let description: String
                let price: Double
                let symbol: String
                let isAvailable: Bool
                let isPopular: Bool

                enum CodingKeys: String, CodingKey {
                    case name, description, price, symbol
                    case restaurantID = "restaurant_id"
                    case categoryID = "category_id"
                    case isAvailable = "is_available"
                    case isPopular = "is_popular"
                }
            }

            let payload = NewProduct(
                restaurantID: restaurantID,
                categoryID: categoryID,
                name: name,
                description: description,
                price: price,
                symbol: symbol,
                isAvailable: isAvailable,
                isPopular: isPopular
            )

            let created: Product = try await client
                .from("products")
                .insert(payload)
                .select(Self.productSelection)
                .single()
                .execute()
                .value

            products.append(created)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateProduct(
        _ product: Product,
        name: String,
        description: String,
        price: Double,
        category: ProductCategory,
        symbol: String,
        isAvailable: Bool,
        isPopular: Bool
    ) async {
        errorMessage = nil
        do {
            guard let categoryID = try await categoryID(forName: category.rawValue) else {
                errorMessage = "No se encontró la categoría seleccionada."
                return
            }

            struct ProductUpdate: Encodable {
                let categoryID: Int
                let name: String
                let description: String
                let price: Double
                let symbol: String
                let isAvailable: Bool
                let isPopular: Bool

                enum CodingKeys: String, CodingKey {
                    case name, description, price, symbol
                    case categoryID = "category_id"
                    case isAvailable = "is_available"
                    case isPopular = "is_popular"
                }
            }

            let payload = ProductUpdate(
                categoryID: categoryID,
                name: name,
                description: description,
                price: price,
                symbol: symbol,
                isAvailable: isAvailable,
                isPopular: isPopular
            )

            let updated: Product = try await client
                .from("products")
                .update(payload)
                .eq("id", value: product.id)
                .select(Self.productSelection)
                .single()
                .execute()
                .value

            if let index = products.firstIndex(where: { $0.id == updated.id }) {
                products[index] = updated
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteProduct(_ product: Product) async {
        errorMessage = nil
        do {
            try await client
                .from("products")
                .delete()
                .eq("id", value: product.id)
                .execute()
            products.removeAll { $0.id == product.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleAvailability(_ product: Product) async {
        errorMessage = nil
        do {
            struct AvailabilityUpdate: Encodable {
                let isAvailable: Bool
                enum CodingKeys: String, CodingKey { case isAvailable = "is_available" }
            }

            let updated: Product = try await client
                .from("products")
                .update(AvailabilityUpdate(isAvailable: !product.isAvailable))
                .eq("id", value: product.id)
                .select(Self.productSelection)
                .single()
                .execute()
                .value

            if let index = products.firstIndex(where: { $0.id == updated.id }) {
                products[index] = updated
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Registra un nuevo local (usado al crear una cuenta de dueño) y lo
    /// devuelve para asociarlo a su usuario. La política de `insert` exige
    /// `owner_id = auth.uid()` y que el perfil tenga rol "owner".
    func addRestaurant(
        name: String,
        categoryID: Int,
        location: String,
        symbol: String = "storefront.fill"
    ) async -> Restaurant? {
        errorMessage = nil
        do {
            let ownerID = try await client.auth.session.user.id

            struct NewRestaurant: Encodable {
                let ownerID: UUID
                let categoryID: Int
                let name: String
                let description: String
                let location: String
                let symbol: String
                let prepTimeMin: Int
                let prepTimeMax: Int

                enum CodingKeys: String, CodingKey {
                    case name, description, location, symbol
                    case ownerID = "owner_id"
                    case categoryID = "category_id"
                    case prepTimeMin = "prep_time_min"
                    case prepTimeMax = "prep_time_max"
                }
            }

            let payload = NewRestaurant(
                ownerID: ownerID,
                categoryID: categoryID,
                name: name,
                description: "Nuevo local en el campus.",
                location: location,
                symbol: symbol,
                prepTimeMin: 8,
                prepTimeMax: 15
            )

            let created: Restaurant = try await client
                .from("restaurants")
                .insert(payload)
                .select(Self.restaurantSelection)
                .single()
                .execute()
                .value

            restaurants.insert(created, at: 0)
            return created
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    // MARK: - Privado

    private func categoryID(forName name: String) async throws -> Int? {
        struct CategoryRow: Decodable { let id: Int }
        let row: CategoryRow? = try await client
            .from("product_categories")
            .select("id")
            .eq("name", value: name)
            .single()
            .execute()
            .value
        return row?.id
    }
}
