//
//  User.swift
//  LaSalleFoods
//
//  Modelo de usuario y los dos roles que contempla la aplicación
//  según la documentación: alumno y dueño/encargado de local.
//

import Foundation

enum UserRole: String, Codable, CaseIterable, Identifiable {
    case student   // Alumno
    case owner     // Dueño o encargado de local

    var id: String { rawValue }

    var title: String {
        switch self {
        case .student: return "Alumno"
        case .owner: return "Dueño de local"
        }
    }

    var subtitle: String {
        switch self {
        case .student: return "Pide y recoge tu comida"
        case .owner: return "Administra tu local"
        }
    }

    var icon: String {
        switch self {
        case .student: return "graduationcap.fill"
        case .owner: return "storefront.fill"
        }
    }
}

struct User: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var email: String
    var role: UserRole
    /// Local asociado cuando el usuario es dueño.
    var ownedRestaurantID: UUID?

    init(
        id: UUID = UUID(),
        name: String,
        email: String,
        role: UserRole,
        ownedRestaurantID: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.role = role
        self.ownedRestaurantID = ownedRestaurantID
    }
}
