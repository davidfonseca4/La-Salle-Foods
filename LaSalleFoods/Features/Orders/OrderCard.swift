//
//  OrderCard.swift
//  LaSalleFoods
//
//  Tarjeta resumen de un pedido para el historial.
//

import SwiftUI

struct OrderCard: View {
    let order: Order

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(order.restaurantName)
                        .font(AppFont.headline())
                        .foregroundStyle(AppColor.textPrimary)
                    Text("Folio \(order.folio) · \(order.createdAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(AppFont.caption())
                        .foregroundStyle(AppColor.textSecondary)
                }
                Spacer()
                StatusBadge(status: order.status)
            }

            Divider()

            Text(order.lines.map { "\($0.quantity)× \($0.productName)" }.joined(separator: ", "))
                .font(AppFont.subheadline())
                .foregroundStyle(AppColor.textSecondary)
                .lineLimit(2)

            HStack {
                Label("\(order.itemCount) productos", systemImage: "bag.fill")
                    .font(AppFont.caption())
                    .foregroundStyle(AppColor.textPlaceholder)
                Spacer()
                Text(order.total.asCurrency)
                    .font(AppFont.price())
                    .foregroundStyle(AppColor.textPrimary)
            }
        }
        .cardStyle()
    }
}

#Preview {
    OrderCard(order: Order(
        folio: "LSF-2048",
        restaurantID: UUID(),
        restaurantName: "Tortas Doña Mary",
        lines: [
            OrderLine(productName: "Torta de milanesa", quantity: 1, unitPrice: 65),
            OrderLine(productName: "Agua de horchata", quantity: 1, unitPrice: 20)
        ],
        paymentMethod: .cash,
        status: .preparing,
        createdAt: Date().addingTimeInterval(-600),
        pickupCode: "A12"
    ))
    .padding()
    .background(AppColor.background)
}
