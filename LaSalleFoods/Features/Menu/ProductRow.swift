//
//  ProductRow.swift
//  LaSalleFoods
//
//  Fila de producto dentro del menú de un local.
//

import SwiftUI

struct ProductRow: View {
    let product: Product
    var quantityInCart: Int = 0
    let onAdd: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                HStack(spacing: 6) {
                    Text(product.name)
                        .font(AppFont.callout())
                        .foregroundStyle(AppColor.textPrimary)
                    if product.isPopular {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(AppColor.orange)
                    }
                }
                Text(product.description)
                    .font(AppFont.caption())
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(2)
                Text(product.price.asCurrency)
                    .font(AppFont.price())
                    .foregroundStyle(AppColor.textPrimary)
                    .padding(.top, 2)

                if !product.isAvailable {
                    TagChip(
                        text: "Agotado",
                        foreground: AppColor.danger,
                        background: AppColor.danger.opacity(0.12)
                    )
                    .padding(.top, 2)
                }
            }

            Spacer(minLength: 0)

            ZStack(alignment: .bottomTrailing) {
                SymbolThumbnail(symbol: product.symbol, hex: product.isAvailable ? 0xFF7426 : 0x9CA3AF, size: 84)

                Button(action: onAdd) {
                    Image(systemName: quantityInCart > 0 ? "checkmark" : "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(product.isAvailable ? AppColor.orange : AppColor.textPlaceholder)
                        .frame(width: 30, height: 30)
                        .background(.white)
                        .clipShape(Circle())
                        .appShadow()
                }
                .buttonStyle(.plain)
                .disabled(!product.isAvailable)
                .offset(x: 6, y: 6)

                if quantityInCart > 0 {
                    Text("\(quantityInCart)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 20, height: 20)
                        .background(AppColor.orange)
                        .clipShape(Circle())
                        .offset(x: 8, y: -68)
                }
            }
        }
        .padding(.vertical, AppSpacing.xs)
        .opacity(product.isAvailable ? 1 : 0.6)
    }
}

#Preview {
    ProductRow(product: MockData.products[0], quantityInCart: 2) {}
        .padding()
}
