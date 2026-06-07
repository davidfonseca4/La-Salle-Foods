//
//  SessionStore.swift
//  LaSalleFoods
//
//  Maneja la sesión del usuario (login/logout y rol activo) contra
//  Supabase Auth. `profiles` guarda nombre y rol; el local de un dueño
//  se resuelve buscando `restaurants.owner_id`.
//

import SwiftUI
import Supabase

@MainActor
final class SessionStore: ObservableObject {
    @Published private(set) var currentUser: User?
    @Published var errorMessage: String?
    @Published private(set) var isLoading = false

    var isAuthenticated: Bool { currentUser != nil }
    var role: UserRole? { currentUser?.role }

    private let client = SupabaseManager.client

    /// Restaura la sesión activa (si existe) al iniciar la app, para que
    /// el usuario no tenga que volver a iniciar sesión cada vez que la abre.
    func restoreSession() async {
        guard let session = try? await client.auth.session else { return }
        await loadProfile(from: session)
    }

    func signIn(email: String, password: String) async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            let session = try await client.auth.signIn(email: email, password: password)
            await loadProfile(from: session)
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
            let response = try await client.auth.signUp(
                email: email,
                password: password,
                data: ["full_name": .string(name), "role": .string(role.rawValue)]
            )
            if let session = response.session {
                await loadProfile(from: session)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() async {
        try? await client.auth.signOut()
        currentUser = nil
    }

    // MARK: - Privado

    private func loadProfile(from session: Session) async {
        let authUser = session.user
        do {
            struct ProfileRow: Decodable {
                let fullName: String
                let role: UserRole

                enum CodingKeys: String, CodingKey {
                    case fullName = "full_name"
                    case role
                }
            }

            let profile: ProfileRow = try await client
                .from("profiles")
                .select("full_name, role")
                .eq("id", value: authUser.id)
                .single()
                .execute()
                .value

            var ownedRestaurantID: UUID?
            if profile.role == .owner {
                struct RestaurantIDRow: Decodable { let id: UUID }
                let restaurant: RestaurantIDRow? = try? await client
                    .from("restaurants")
                    .select("id")
                    .eq("owner_id", value: authUser.id)
                    .single()
                    .execute()
                    .value
                ownedRestaurantID = restaurant?.id
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
