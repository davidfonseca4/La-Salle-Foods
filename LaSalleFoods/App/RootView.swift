//
//  RootView.swift
//  LaSalleFoods
//
//  Punto de bifurcación de la navegación: muestra login, la experiencia
//  de alumno (TabBar) o el panel de dueño según la sesión.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var session: SessionStore

    var body: some View {
        Group {
            switch session.role {
            case .none:
                LoginView()
                    .transition(.opacity)
            case .student:
                StudentTabView()
                    .transition(.opacity)
            case .owner:
                OwnerTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: session.role)
        .task {
            await session.restoreSession()
        }
    }
}

// MARK: - Experiencia del alumno

struct StudentTabView: View {
    @EnvironmentObject private var cart: CartStore
    @EnvironmentObject private var appState: AppState

    var body: some View {
        TabView(selection: $appState.studentTab) {
            HomeView()
                .tabItem { Label("Inicio", systemImage: "house.fill") }
                .tag(AppState.StudentTab.home)

            OrdersView()
                .tabItem { Label("Pedidos", systemImage: "bag.fill") }
                .tag(AppState.StudentTab.orders)

            ProfileView()
                .tabItem { Label("Cuenta", systemImage: "person.fill") }
                .tag(AppState.StudentTab.profile)
        }
        .tint(AppColor.orange)
    }
}

// MARK: - Experiencia del dueño

struct OwnerTabView: View {
    var body: some View {
        TabView {
            AdminDashboardView()
                .tabItem { Label("Panel", systemImage: "square.grid.2x2.fill") }

            ProfileView()
                .tabItem { Label("Cuenta", systemImage: "person.fill") }
        }
        .tint(AppColor.orange)
    }
}

#Preview("Login") {
    RootView()
        .environmentObject(SessionStore())
        .environmentObject(CatalogStore())
        .environmentObject(CartStore())
        .environmentObject(OrderStore())
        .environmentObject(AppState())
}
