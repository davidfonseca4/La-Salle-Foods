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
    @EnvironmentObject private var orders: OrderStore
    @Environment(\.scenePhase) private var scenePhase

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
            await activateLiveUpdatesIfNeeded()
        }
        .onChange(of: session.isAuthenticated) { _, isAuthenticated in
            Task {
                if isAuthenticated {
                    await activateLiveUpdatesIfNeeded()
                } else {
                    orders.clear()
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                Task { await resumeLiveUpdatesIfNeeded() }
            case .background, .inactive:
                orders.stopAutoRefresh()
            @unknown default:
                break
            }
        }
    }

    /// Tras login o arranque: carga inicial con indicador de carga.
    private func activateLiveUpdatesIfNeeded() async {
        guard session.isAuthenticated else { return }
        await orders.refreshAll(showLoading: true)
        orders.startAutoRefresh()
    }

    /// Al volver a primer plano: refresco silencioso sin spinner.
    private func resumeLiveUpdatesIfNeeded() async {
        guard session.isAuthenticated else { return }
        await orders.refreshAll(showLoading: false)
        orders.startAutoRefresh()
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
