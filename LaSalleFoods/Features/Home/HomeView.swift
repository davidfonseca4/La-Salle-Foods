//
//  HomeView.swift
//  LaSalleFoods
//
//  Pantalla 2: lista de locales disponibles dentro de la universidad.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var session: SessionStore
    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var orders: OrderStore
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = HomeViewModel()
    @State private var showNotifications = false

    var body: some View {
        NavigationStack(path: $appState.homePath) {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    greeting
                    SearchField(placeholder: "Busca un local o tipo de comida", text: $viewModel.searchText)
                    promoBanner
                    categoryFilters
                    popularSection
                    restaurantsSection
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl)
            }
            .background(AppColor.background.ignoresSafeArea())
            .refreshable { await catalog.loadCatalog() }
            .navigationDestination(for: Restaurant.self) { restaurant in
                MenuView(restaurant: restaurant)
            }
            .navigationDestination(for: Product.self) { product in
                if let restaurant = catalog.restaurant(by: product.restaurantID) {
                    MenuView(restaurant: restaurant)
                }
            }
            .navigationDestination(isPresented: $showNotifications) {
                NotificationsView()
            }
        }
        .task {
            await catalog.loadCatalog()
            await orders.loadOrders()
            await orders.loadNotifications()
        }
    }

    // MARK: - Saludo

    private var greeting: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Hola, \(firstName) 👋")
                    .font(AppFont.title())
                    .foregroundStyle(AppColor.textPrimary)
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(AppColor.orange)
                    Text("Campus La Salle Bajío")
                        .font(AppFont.subheadline())
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
            Spacer()
            Button {
                showNotifications = true
            } label: {
                ZStack {
                    Circle()
                        .fill(AppColor.surface)
                        .frame(width: 48, height: 48)
                        .appShadow()
                    Image(systemName: unreadCount > 0 ? "bell.badge.fill" : "bell.fill")
                        .foregroundStyle(AppColor.navy)
                    if unreadCount > 0 {
                        Text("\(unreadCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(4)
                            .background(AppColor.danger, in: Circle())
                            .offset(x: 16, y: -16)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.top, AppSpacing.xs)
    }

    private var firstName: String {
        session.currentUser?.name.components(separatedBy: " ").first ?? "Alumno"
    }

    private var unreadCount: Int {
        orders.unreadCount
    }

    // MARK: - Banner promocional

    private var promoBanner: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .fill(AppColor.warmGradient)
                .frame(height: 120)

            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Pide antes de tu clase")
                        .font(AppFont.headline())
                        .foregroundStyle(.white)
                    Text("Ordena ahora y recoge sin\nhacer fila entre clases.")
                        .font(AppFont.subheadline())
                        .foregroundStyle(.white.opacity(0.9))
                }
                Spacer()
                Image(systemName: "bag.fill.badge.plus")
                    .font(.system(size: 52))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(AppSpacing.md)
        }
        .appShadow()
    }

    // MARK: - Filtros de categoría

    private var categoryFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.xs) {
                ForEach(viewModel.categories, id: \.self) { category in
                    FilterChip(
                        title: category,
                        isSelected: viewModel.selectedCategory == category
                    ) {
                        withAnimation(.snappy) { viewModel.selectedCategory = category }
                    }
                }
            }
        }
    }

    // MARK: - Populares

    @ViewBuilder private var popularSection: some View {
        let populars = catalog.popularProducts()
        if viewModel.searchText.isEmpty && viewModel.selectedCategory == "Todos" && !populars.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                SectionHeader(title: "Lo más pedido 🔥")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.sm) {
                        ForEach(populars) { product in
                            NavigationLink(value: product) {
                                PopularProductCard(product: product)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Lista de locales

    private var restaurantsSection: some View {
        let restaurants = viewModel.filteredRestaurants(from: catalog.restaurants)
        return VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionHeader(title: "Locales en el campus")
            if restaurants.isEmpty {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "Sin resultados",
                    message: "No encontramos locales que coincidan con tu búsqueda."
                )
            } else {
                ForEach(restaurants) { restaurant in
                    NavigationLink(value: restaurant) {
                        RestaurantCard(restaurant: restaurant)
                    }
                    .buttonStyle(.plain)
                    .disabled(!restaurant.isOpen)
                }
            }
        }
    }
}

// MARK: - Tarjeta horizontal de producto popular

private struct PopularProductCard: View {
    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            SymbolThumbnail(symbol: product.symbol, hex: 0xFF7426, size: 140, cornerRadius: AppRadius.md)
                .frame(width: 160)
            Text(product.name)
                .font(AppFont.callout())
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)
            Text(product.price.asCurrency)
                .font(AppFont.price())
                .foregroundStyle(AppColor.orange)
        }
        .frame(width: 160, alignment: .leading)
    }
}

#Preview {
    HomeView()
        .environmentObject(SessionStore())
        .environmentObject(CatalogStore())
        .environmentObject(OrderStore())
        .environmentObject(AppState())
}
