//
//  MenuView.swift
//  LaSalleFoods
//
//  Pantalla 3: menú de productos de un local, agrupado por categoría,
//  con barra inferior que lleva al carrito.
//

import SwiftUI

struct MenuView: View {
    let restaurant: Restaurant

    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var cart: CartStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedProduct: Product?
    @State private var goToCart = false

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    headerCard
                    menuSections
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, 110)
            }
            .background(AppColor.background.ignoresSafeArea())

            if !cart.isEmpty {
                cartBar
            }
        }
        .navigationTitle(restaurant.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedProduct) { product in
            ProductDetailSheet(product: product)
        }
        .navigationDestination(isPresented: $goToCart) {
            CartView()
        }
    }

    // MARK: - Encabezado del local

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            SymbolBanner(symbol: restaurant.symbol, hex: restaurant.coverHex, height: 160)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(restaurant.name)
                    .font(AppFont.title())
                    .foregroundStyle(AppColor.textPrimary)
                Text(restaurant.description)
                    .font(AppFont.subheadline())
                    .foregroundStyle(AppColor.textSecondary)

                HStack(spacing: AppSpacing.md) {
                    RatingView(rating: restaurant.rating, reviewCount: restaurant.reviewCount)
                    Label(restaurant.prepTimeText, systemImage: "clock.fill")
                        .font(AppFont.caption())
                        .foregroundStyle(AppColor.textSecondary)
                    Label(restaurant.location, systemImage: "mappin.and.ellipse")
                        .font(AppFont.caption())
                        .foregroundStyle(AppColor.textSecondary)
                        .lineLimit(1)
                }
                .padding(.top, 2)
            }
            .padding(.top, AppSpacing.md)
        }
    }

    // MARK: - Secciones de menú

    private var menuSections: some View {
        let groups = catalog.groupedProducts(for: restaurant.id)
        return ForEach(groups, id: \.category) { group in
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack(spacing: 6) {
                    Image(systemName: group.category.icon)
                        .foregroundStyle(AppColor.orange)
                    Text(group.category.rawValue)
                        .font(AppFont.headline())
                        .foregroundStyle(AppColor.textPrimary)
                }
                ForEach(group.items) { product in
                    Button {
                        if product.isAvailable { selectedProduct = product }
                    } label: {
                        ProductRow(
                            product: product,
                            quantityInCart: cart.quantity(of: product)
                        ) {
                            cart.add(product)
                        }
                    }
                    .buttonStyle(.plain)
                    if product.id != group.items.last?.id {
                        Divider()
                    }
                }
            }
            .cardStyle()
        }
    }

    // MARK: - Barra del carrito

    private var cartBar: some View {
        Button {
            goToCart = true
        } label: {
            HStack {
                ZStack {
                    Image(systemName: "bag.fill")
                        .font(.system(size: 20))
                    Text("\(cart.totalQuantity)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppColor.orange)
                        .frame(width: 18, height: 18)
                        .background(.white)
                        .clipShape(Circle())
                        .offset(x: 12, y: -12)
                }
                .foregroundStyle(.white)

                Text("Ver carrito")
                    .font(AppFont.headline())
                    .foregroundStyle(.white)
                Spacer()
                Text(cart.subtotal.asCurrency)
                    .font(AppFont.headline())
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, AppSpacing.lg)
            .frame(height: 58)
            .background(AppColor.orange)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            .appShadow(.floating)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xs)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        MenuView(restaurant: Restaurant(
            name: "Tortas Doña Mary",
            category: "Mexicana · Tortas",
            description: "Las tortas más grandes del campus, recién hechas.",
            symbol: "takeoutbag.and.cup.and.straw.fill",
            coverHex: 0xFF7426,
            rating: 4.8,
            reviewCount: 320,
            prepTimeMinutes: 8...12,
            location: "Cafetería Central",
            tags: ["Popular", "Sin filas"]
        ))
            .environmentObject(CatalogStore())
            .environmentObject(CartStore())
    }
}
