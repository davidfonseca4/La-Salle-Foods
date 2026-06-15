//
//  SessionStore.swift
//  LaSalleFoods
//
//  Maneja la sesión del usuario (login/logout y rol activo) contra el
//  backend Java (`/api/auth/*`, `/api/profile`). `profiles` guarda nombre
//  y rol; el local de un dueño se resuelve buscando `restaurants.owner_id`
//  vía el proxy genérico `/api/db/...`.
//

import SwiftUI

@MainActor
final class SessionStore: ObservableObject {
    @Published private(set) var currentUser: User?
    @Published var errorMessage: String?
    @Published private(set) var isLoading = false

    var isAuthenticated: Bool { currentUser != nil }
    var role: UserRole? { currentUser?.role }

    /// Restaura la sesión activa (si existe) al iniciar la app, para que
    /// el usuario no tenga que volver a iniciar sesión cada vez que la abre.
    func restoreSession() async {
        guard APIClient.refreshToken != nil else { return }
        guard await APIClient.refreshSession() else {
            APIClient.clearTokens()
            return
        }
        await loadProfile()
    }

    func signIn(email: String, password: String) async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            struct LoginBody: Encodable { let email: String; let password: String }
            let session: AuthSession = try await APIClient.post(
                "auth/login",
                body: LoginBody(email: email, password: password),
                authenticated: false
            )
            guard let access = session.accessToken, let refresh = session.refreshToken else {
                errorMessage = "No se pudo iniciar sesión."
                return
            }
            APIClient.accessToken = access
            APIClient.refreshToken = refresh
            await loadProfile()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Crea la cuenta. El trigger `handle_new_user` llena `profiles` a partir
    /// de los metadatos `full_name`/`role`. Si el proyecto exige confirmar el
    /// correo, todavía no habrá sesión activa (`isAuthenticated` seguirá en
    /// `false`) hasta que el usuario confirme e inicie sesión.
    func signUp(name: String, email: String, password: String, role: UserRole) async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            struct RegisterBody: Encodable {
                let email: String
                let password: String
                let data: [String: String]
            }
            let body = RegisterBody(
                email: email,
                password: password,
                data: ["full_name": name, "role": role.rawValue]
            )
            let session: AuthSession = try await APIClient.post("auth/register", body: body, authenticated: false)
            if let access = session.accessToken, let refresh = session.refreshToken {
                APIClient.accessToken = access
                APIClient.refreshToken = refresh
                await loadProfile()
            }
        } catch {
            let description = error.localizedDescription
            if description.contains("Database error saving new user") {
                errorMessage = "Usa tu correo institucional @lasallebajio.edu.mx"
            } else {
                errorMessage = description
            }
        }
    }

    func signOut() async {
        try? await APIClient.postNoContent("auth/logout", body: EmptyBody())
        APIClient.clearTokens()
        currentUser = nil
    }

    /// Actualiza el local asociado a la sesión actual (llamado tras crear el
    /// local de un dueño recién registrado).
    func setOwnedRestaurant(_ id: UUID) {
        currentUser?.ownedRestaurantID = id
    }

    func updateProfile(fullName: String) async -> Bool {
        errorMessage = nil
        do {
            struct ProfileUpdate: Encodable { let fullName: String
                enum CodingKeys: String, CodingKey { case fullName = "full_name" }
            }
            try await APIClient.patchNoContent("profile", body: ProfileUpdate(fullName: fullName))
            currentUser?.name = fullName
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Privado

    private func loadProfile() async {
        do {
            let authUser: AuthUser = try await APIClient.get("auth/me")

            struct ProfileRow: Decodable {
                let fullName: String
                let role: UserRole

                enum CodingKeys: String, CodingKey {
                    case fullName = "full_name"
                    case role
                }
            }

            let profiles: [ProfileRow] = try await APIClient.get("profile")
            guard let profile = profiles.first else {
                errorMessage = "No se encontró el perfil."
                return
            }

            var ownedRestaurantID: UUID?
            if profile.role == .owner {
                struct RestaurantIDRow: Decodable { let id: UUID }
                let rows: [RestaurantIDRow] = try await APIClient.get("db/restaurants", query: [
                    URLQueryItem(name: "owner_id", value: "eq.\(authUser.id)"),
                    URLQueryItem(name: "select", value: "id")
                ])
                ownedRestaurantID = rows.first?.id
            }

            currentUser = User(
                id: authUser.id,
                name: profile.fullName,
                email: authUser.email ?? "",
                role: profile.role,
                ownedRestaurantID: ownedRestaurantID
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
