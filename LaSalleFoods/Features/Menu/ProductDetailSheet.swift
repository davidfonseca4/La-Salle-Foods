//
//  ProductDetailSheet.swift
//  LaSalleFoods
//
//  Hoja de detalle de un producto con selector de cantidad, notas
//  y botón para agregar al carrito.
//

import SwiftUI

struct ProductDetailSheet: View {
    let product: Product
    @EnvironmentObject private var cart: CartStore
    @Environment(\.dismiss) private var dismiss

    @State private var quantity = 1
    @State private var notes = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    SymbolBanner(symbol: product.symbol, hex: 0xFF7426, height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))

                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        HStack {
                            Text(product.name)
                                .font(AppFont.title())
                                .foregroundStyle(AppColor.textPrimary)
                            Spacer()
                            Text(product.price.asCurrency)
                                .font(AppFont.title())
                                .foregroundStyle(AppColor.orange)
                        }
                        Text(product.description)
                            .font(AppFont.body())
                            .foregroundStyle(AppColor.textSecondary)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Notas para el local")
                            .font(AppFont.headline())
                            .foregroundStyle(AppColor.textPrimary)
                        TextField("Ej. sin cebolla, salsa aparte…", text: $notes, axis: .vertical)
                            .font(AppFont.body())
                            .lineLimit(2...4)
                            .padding(AppSpacing.md)
                            .background(AppColor.surfaceMuted)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                    }
                }
                .padding(AppSpacing.lg)
            }

            bottomBar
        }
        .background(AppColor.background.ignoresSafeArea())
        .presentationDragIndicator(.visible)
    }

    private var bottomBar: some View {
        HStack(spacing: AppSpacing.md) {
            QuantityStepper(quantity: $quantity)

            AppButton(title: "Agregar  ·  \(itemTotal.asCurrency)", icon: "cart.badge.plus") {
                cart.add(product, quantity: quantity, notes: notes)
                dismiss()
            }
        }
        .padding(AppSpacing.md)
        .background(
            AppColor.surface
                .ignoresSafeArea(edges: .bottom)
                .appShadow(.floating)
        )
    }

    private var itemTotal: Double {
        product.price * Double(quantity)
    }
}

#Preview {
    ProductDetailSheet(product: Product(restaurantID: UUID(), name: "Torta de milanesa", description: "Milanesa de res, aguacate, jitomate y frijoles.", price: 65, category: .mains, symbol: "takeoutbag.and.cup.and.straw.fill", isPopular: true))
        .environmentObject(CartStore())
}
