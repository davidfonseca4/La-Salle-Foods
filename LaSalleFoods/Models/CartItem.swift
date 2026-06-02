//
//  CartItem.swift
//  LaSalleFoods
//
//  Línea del carrito: un producto con su cantidad y notas opcionales.
//

import Foundation

struct CartItem: Identifiable, Hashable {
    let id: UUID
    var product: Product
    var quantity: Int
    var notes: String

    init(id: UUID = UUID(), product: Product, quantity: Int = 1, notes: String = "") {
        self.id = id
        self.product = product
        self.quantity = quantity
        self.notes = notes
    }

    var subtotal: Double {
        product.price * Double(quantity)
    }
}
