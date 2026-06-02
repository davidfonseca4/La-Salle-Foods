//
//  LoginViewModel.swift
//  LaSalleFoods
//
//  Lógica de presentación de la pantalla de inicio de sesión.
//

import SwiftUI

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var role: UserRole = .student
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    var isFormValid: Bool {
        email.contains("@") && password.count >= 4
    }

    /// Simula una llamada de autenticación con un pequeño retardo.
    func signIn(using session: SessionStore) {
        guard isFormValid else {
            errorMessage = "Ingresa un correo válido y una contraseña de al menos 4 caracteres."
            return
        }
        errorMessage = nil
        isLoading = true

        Task {
            try? await Task.sleep(for: .milliseconds(700))
            session.signIn(email: email, password: password, role: role)
            isLoading = false
        }
    }

    /// Autocompleta credenciales de demostración según el rol.
    func fillDemoCredentials() {
        switch role {
        case .student:
            email = "alumno@lasalle.edu.mx"
        case .owner:
            email = "local@lasalle.edu.mx"
        }
        password = "demo1234"
    }
}
