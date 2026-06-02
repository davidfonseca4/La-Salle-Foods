//
//  CartStore.swift
//  LaSalleFoods
//
//  Carrito de compras. Solo permite productos de un mismo local a la vez
//  (los pedidos son por local, como en la documentación).
//

import SwiftUI

@MainActor
final class CartStore: ObservableObject {
    @Published private(set) var items: [CartItem] = []
    @Published private(set) var restaurantID: UUID?

    // MARK: - Derivados

    var isEmpty: Bool { items.isEmpty }

    var totalQuantity: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    var subtotal: Double {
        items.reduce(0) { $0 + $1.subtotal }
    }

    /// Cuota de servicio simbólica para el resumen.
    var serviceFee: Double {
        items.isEmpty ? 0 : 5
    }

    var total: Double {
        subtotal + serviceFee
    }

    func quantity(of product: Product) -> Int {
        items.first { $0.product.id == product.id }?.quantity ?? 0
    }

    // MARK: - Mutaciones

    /// Agrega un producto. Si el carrito pertenece a otro local, lo reinicia.
    func add(_ product: Product, quantity: Int = 1, notes: String = "") {
        if let current = restaurantID, current != product.restaurantID {
            items.removeAll()
        }
        restaurantID = product.restaurantID

        if let index = items.firstIndex(where: { $0.product.id == product.id }) {
            items[index].quantity += quantity
            if !notes.isEmpty { items[index].notes = notes }
        } else {
            items.append(CartItem(product: product, quantity: quantity, notes: notes))
        }
    }

    func increment(_ item: CartItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].quantity += 1
    }

    func decrement(_ item: CartItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].quantity -= 1
        if items[index].quantity <= 0 {
            items.remove(at: index)
        }
        if items.isEmpty { restaurantID = nil }
    }

    func remove(_ item: CartItem) {
        items.removeAll { $0.id == item.id }
        if items.isEmpty { restaurantID = nil }
    }

    func clear() {
        items.removeAll()
        restaurantID = nil
    }
}
