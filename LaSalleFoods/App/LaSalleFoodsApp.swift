//
//  LaSalleFoodsApp.swift
//  LaSalleFoods
//
//  Punto de entrada de la aplicación. Inyecta los stores globales
//  (sesión, carrito, pedidos y productos) en el entorno de SwiftUI.
//

import SwiftUI

@main
struct LaSalleFoodsApp: App {
    @StateObject private var session = SessionStore()
    @StateObject private var catalog = CatalogStore()
    @StateObject private var cart = CartStore()
    @StateObject private var orders = OrderStore()
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                .environmentObject(catalog)
                .environmentObject(cart)
                .environmentObject(orders)
                .environmentObject(appState)
                .tint(AppColor.orange)
        }
    }
}
