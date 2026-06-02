//
//  AppState.swift
//  LaSalleFoods
//
//  Estado de navegación de alto nivel para el alumno: pestaña activa y
//  pila de navegación de Inicio. Permite, por ejemplo, que la pantalla de
//  confirmación lleve al usuario a "Mis pedidos" o de vuelta al inicio.
//

import SwiftUI

@MainActor
final class AppState: ObservableObject {
    enum StudentTab: Hashable {
        case home, orders, profile
    }

    @Published var studentTab: StudentTab = .home
    @Published var homePath = NavigationPath()

    /// Lleva al alumno a su historial de pedidos.
    func goToMyOrders() {
        homePath = NavigationPath()
        studentTab = .orders
    }

    /// Regresa al inicio (raíz) descartando la navegación del carrito.
    func goToHomeRoot() {
        homePath = NavigationPath()
        studentTab = .home
    }
}
