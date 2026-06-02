//
//  RestaurantCard.swift
//  LaSalleFoods
//
//  Tarjeta de local estilo Uber Eats: portada, nombre, rating y tiempo.
//

import SwiftUI

struct RestaurantCard: View {
    let restaurant: Restaurant

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                SymbolBanner(symbol: restaurant.symbol, hex: restaurant.coverHex, height: 150)

                if !restaurant.isOpen {
                    Color.black.opacity(0.45)
                        .frame(height: 150)
                    Text("Cerrado")
                        .font(AppFont.headline())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, maxHeight: 150)
                }

                HStack {
                    ForEach(restaurant.tags.prefix(2), id: \.self) { tag in
                        TagChip(
                            text: tag,
                            foreground: AppColor.navy,
                            background: .white
                        )
                    }
                    Spacer()
                    HStack(spacing: 3) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text(restaurant.prepTimeText)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(AppColor.navy)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, 6)
                    .background(.white)
                    .clipShape(Capsule())
                }
                .padding(AppSpacing.sm)
            }

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                HStack {
                    Text(restaurant.name)
                        .font(AppFont.headline())
                        .foregroundStyle(AppColor.textPrimary)
                        .lineLimit(1)
                    Spacer()
                    RatingView(rating: restaurant.rating, reviewCount: restaurant.reviewCount, compact: true)
                }
                Text(restaurant.category)
                    .font(AppFont.subheadline())
                    .foregroundStyle(AppColor.textSecondary)
                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 11))
                    Text(restaurant.location)
                        .font(AppFont.caption())
                }
                .foregroundStyle(AppColor.textPlaceholder)
            }
            .padding(AppSpacing.md)
        }
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        .appShadow()
        .opacity(restaurant.isOpen ? 1 : 0.85)
    }
}

#Preview {
    RestaurantCard(restaurant: MockData.restaurants[0])
        .padding()
        .background(AppColor.background)
}
