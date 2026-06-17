//
//  CatalogStore.swift
//  LaSalleFoods
//
//  Fuente de verdad de locales y productos. Expone operaciones de
//  consulta para alumnos y de administración (CRUD) para dueños contra
//  el backend Java (`/api/restaurants`, `/api/products`, `/api/db/...`).
//

import SwiftUI

@MainActor
final class CatalogStore: ObservableObject {
    @Published private(set) var restaurants: [Restaurant] = []
    @Published private(set) var products: [Product] = []
    @Published var errorMessage: String?
    @Published private(set) var isLoading = false

    /// Selección con joins usada por `/api/db/restaurants` para obtener un
    /// local con su categoría y tags (igual que `GET /api/restaurants`).
    private static let restaurantSelection = "*,restaurant_categories(name),restaurant_tags(tags(name))"

    /// Carga locales (con categoría y tags) y todos los productos visibles
    /// según el rol (alumnos ven los de locales activos; dueños, también los
    /// propios aunque su local esté inactivo).
    func loadCatalog() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            async let restaurantsTask: [Restaurant] = APIClient.get("restaurants")
            async let productsTask: [Product] = APIClient.get("db/products", query: [
                URLQueryItem(name: "select", value: "*,product_categories(name)")
            ])

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
        (try? await APIClient.get("restaurant-categories")) ?? []
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

            try await APIClient.postNoContent("products", body: payload)
            await reloadProducts(for: restaurantID)
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

            try await APIClient.patchNoContent("products/\(product.id)", body: payload)
            await reloadProducts(for: product.restaurantID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteProduct(_ product: Product) async {
        errorMessage = nil
        do {
            try await APIClient.delete("products/\(product.id)")
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

            try await APIClient.patchNoContent("products/\(product.id)", body: AvailabilityUpdate(isAvailable: !product.isAvailable))
            await reloadProducts(for: product.restaurantID)
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
            let me: AuthUser = try await APIClient.get("auth/me")

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
                ownerID: me.id,
                categoryID: categoryID,
                name: name,
                description: "Nuevo local en el campus.",
                location: location,
                symbol: symbol,
                prepTimeMin: 8,
                prepTimeMax: 15
            )

            try await APIClient.postNoContent("restaurants", body: payload)

            // El POST no devuelve el registro creado (sin `Prefer:
            // return=representation`); se vuelve a consultar por owner_id.
            // Retry once: Java backend may write async, so the first GET
            // can race and return [] even when the insert succeeded.
            let query = [
                URLQueryItem(name: "owner_id", value: "eq.\(me.id)"),
                URLQueryItem(name: "select", value: Self.restaurantSelection)
            ]
            var created: [Restaurant] = try await APIClient.get("db/restaurants", query: query)
            if created.isEmpty {
                try await Task.sleep(for: .milliseconds(600))
                created = try await APIClient.get("db/restaurants", query: query)
            }
            guard let restaurant = created.first else { return nil }
            restaurants.insert(restaurant, at: 0)
            return restaurant
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    /// Edita los datos del propio local (nombre, descripción, ubicación,
    /// categoría, tiempo de preparación y si está abierto).
    func updateRestaurant(
        id: UUID,
        name: String,
        description: String,
        location: String,
        categoryID: Int,
        prepMin: Int,
        prepMax: Int,
        isOpen: Bool
    ) async -> Bool {
        errorMessage = nil
        do {
            struct RestaurantUpdate: Encodable {
                let name: String
                let description: String
                let location: String
                let categoryID: Int
                let prepMin: Int
                let prepMax: Int
                let isOpen: Bool

                enum CodingKeys: String, CodingKey {
                    case name, description, location
                    case categoryID = "category_id"
                    case prepMin = "prep_time_min"
                    case prepMax = "prep_time_max"
                    case isOpen = "is_open"
                }
            }

            let payload = RestaurantUpdate(
                name: name,
                description: description,
                location: location,
                categoryID: categoryID,
                prepMin: prepMin,
                prepMax: max(prepMin, prepMax),
                isOpen: isOpen
            )

            try await APIClient.patchNoContent("restaurants/\(id)", body: payload)
            await loadCatalog()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// Reemplaza el conjunto de etiquetas del propio local.
    func updateRestaurantTags(id: UUID, tagIDs: [Int]) async -> Bool {
        errorMessage = nil
        do {
            struct TagsBody: Encodable {
                let tagIDs: [Int]
                enum CodingKeys: String, CodingKey { case tagIDs = "tag_ids" }
            }
            try await APIClient.putNoContent("restaurants/\(id)/tags", body: TagsBody(tagIDs: tagIDs))
            await loadCatalog()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// Etiquetas disponibles en la plataforma (para asignarlas a un local).
    func loadTags() async -> [TagOption] {
        (try? await APIClient.get("tags")) ?? []
    }

    struct TagOption: Identifiable, Decodable, Hashable {
        let id: Int
        let name: String
    }

    // MARK: - Privado

    private func reloadProducts(for restaurantID: UUID) async {
        guard let fresh: [Product] = try? await APIClient.get("restaurants/\(restaurantID)/products") else { return }
        products.removeAll { $0.restaurantID == restaurantID }
        products.append(contentsOf: fresh)
    }

    private func categoryID(forName name: String) async throws -> Int? {
        struct CategoryRow: Decodable { let id: Int; let name: String }
        let rows: [CategoryRow] = try await APIClient.get("product-categories")
        return rows.first { $0.name == name }?.id
    }
}
