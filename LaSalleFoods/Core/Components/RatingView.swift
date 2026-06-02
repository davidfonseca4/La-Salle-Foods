//
//  RatingView.swift
//  LaSalleFoods
//
//  Muestra una calificación con la estrella amarilla de la paleta.
//

import SwiftUI

struct RatingView: View {
    let rating: Double
    var reviewCount: Int? = nil
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "star.fill")
                .font(.system(size: compact ? 11 : 13))
                .foregroundStyle(AppColor.rating)
            Text(String(format: "%.1f", rating))
                .font(.system(size: compact ? 12 : 14, weight: .semibold))
                .foregroundStyle(AppColor.textPrimary)
            if let reviewCount {
                Text("(\(reviewCount))")
                    .font(.system(size: compact ? 11 : 13))
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        RatingView(rating: 4.8, reviewCount: 320)
        RatingView(rating: 4.6, compact: true)
    }
    .padding()
}
