//
//  QuantityStepper.swift
//  LaSalleFoods
//
//  Control + / - para ajustar cantidades en el carrito y detalle de producto.
//

import SwiftUI

struct QuantityStepper: View {
    @Binding var quantity: Int
    var minValue: Int = 1
    var compact: Bool = false

    var body: some View {
        HStack(spacing: compact ? 10 : AppSpacing.md) {
            stepperButton(symbol: "minus") {
                if quantity > minValue { quantity -= 1 }
            }
            .disabled(quantity <= minValue)

            Text("\(quantity)")
                .font(.system(size: compact ? 15 : 17, weight: .bold, design: .rounded))
                .foregroundStyle(AppColor.textPrimary)
                .frame(minWidth: 22)

            stepperButton(symbol: "plus") {
                quantity += 1
            }
        }
        .padding(.horizontal, compact ? 6 : AppSpacing.xs)
        .padding(.vertical, compact ? 4 : 6)
        .background(AppColor.surfaceMuted)
        .clipShape(Capsule())
    }

    private func stepperButton(symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: compact ? 12 : 14, weight: .bold))
                .foregroundStyle(AppColor.orange)
                .frame(width: compact ? 24 : 30, height: compact ? 24 : 30)
                .background(AppColor.surface)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    QuantityStepper(quantity: .constant(2))
        .padding()
}
