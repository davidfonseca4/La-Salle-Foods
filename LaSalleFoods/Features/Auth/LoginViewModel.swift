//
//  LoginViewModel.swift
//  LaSalleFoods
//
//  Lógica de presentación de la pantalla de inicio de sesión.
//  El estado de carga/error real vive en `SessionStore` (async, conectado
//  al backend Java); aquí solo se valida el formulario antes de llamar.
//

import SwiftUI

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""

    var isFormValid: Bool {
        email.contains("@") && password.count >= 6
    }

    func signIn(using session: SessionStore) {
        guard isFormValid else {
            session.errorMessage = "Ingresa un correo válido y una contraseña de al menos 6 caracteres."
            return
        }
        Task { await session.signIn(email: email, password: password) }
    }
}
