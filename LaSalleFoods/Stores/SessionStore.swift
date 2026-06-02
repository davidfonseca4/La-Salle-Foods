//
//  SessionStore.swift
//  LaSalleFoods
//
//  Maneja la sesión del usuario (login/logout y rol activo).
//  Front-end únicamente: la autenticación es simulada.
//

import SwiftUI

@MainActor
final class SessionStore: ObservableObject {
    @Published private(set) var currentUser: User?

    var isAuthenticated: Bool { currentUser != nil }
    var role: UserRole? { currentUser?.role }

    /// Inicio de sesión simulado. En producción validaría contra Firebase.
    func signIn(email: String, password: String, role: UserRole) {
        switch role {
        case .student:
            currentUser = User(
                name: email.components(separatedBy: "@").first?.capitalized ?? "Alumno",
                email: email,
                role: .student
            )
        case .owner:
            currentUser = MockData.ownerUser
        }
    }

    /// Registro simulado de un nuevo usuario. Para dueños, se asocia el local
    /// recién creado mediante `ownedRestaurantID`.
    func signUp(name: String, email: String, role: UserRole, ownedRestaurantID: UUID? = nil) {
        currentUser = User(
            name: name,
            email: email,
            role: role,
            ownedRestaurantID: ownedRestaurantID
        )
    }

    func signOut() {
        currentUser = nil
    }
}
