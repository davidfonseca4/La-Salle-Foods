//
//  ProductFormView.swift
//  LaSalleFoods
//
//  Formulario para dar de alta o editar un producto (panel de dueño).
//

import SwiftUI

struct ProductFormView: View {
    enum Mode {
        case create(restaurantID: UUID)
        case edit(Product)

        var title: String {
            switch self {
            case .create: return "Nuevo producto"
            case .edit: return "Editar producto"
            }
        }
    }

    let mode: Mode
    @EnvironmentObject private var catalog: CatalogStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var description = ""
    @State private var priceText = ""
    @State private var category: ProductCategory = .mains
    @State private var symbol = "fork.knife"
    @State private var isAvailable = true
    @State private var isPopular = false

    private let symbols = ["fork.knife", "takeoutbag.and.cup.and.straw.fill", "cup.and.saucer.fill", "fish.fill", "leaf.fill", "birthday.cake.fill", "popcorn.fill", "triangle.fill"]

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && Double(priceText) != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    SymbolThumbnail(symbol: symbol, hex: 0xFF7426, size: 96)
                        .padding(.top, AppSpacing.md)

                    symbolPicker

                    VStack(spacing: AppSpacing.md) {
                        LabeledInput(title: "Nombre", placeholder: "Ej. Torta de milanesa", text: $name, icon: "tag.fill")
                        LabeledInput(title: "Descripción", placeholder: "Ingredientes y detalles", text: $description, icon: "text.alignleft")
                        LabeledInput(title: "Precio (MXN)", placeholder: "0.00", text: $priceText, icon: "dollarsign.circle.fill", keyboard: .decimalPad)
                    }

                    categoryPicker
                    togglesCard
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl)
            }
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { save() }
                        .fontWeight(.semibold)
                        .disabled(!isValid)
                }
            }
            .onAppear(perform: load)
        }
    }

    private var symbolPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.xs) {
                ForEach(symbols, id: \.self) { item in
                    Button {
                        symbol = item
                    } label: {
                        Image(systemName: item)
                            .font(.system(size: 18))
                            .foregroundStyle(symbol == item ? .white : AppColor.textSecondary)
                            .frame(width: 48, height: 48)
                            .background(symbol == item ? AppColor.orange : AppColor.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                    .stroke(AppColor.border, lineWidth: symbol == item ? 0 : 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Categoría")
                .font(AppFont.caption())
                .foregroundStyle(AppColor.textSecondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.xs) {
                    ForEach(ProductCategory.allCases) { cat in
                        FilterChip(title: cat.rawValue, icon: cat.icon, isSelected: category == cat) {
                            category = cat
                        }
                    }
                }
            }
        }
    }

    private var togglesCard: some View {
        VStack(spacing: AppSpacing.sm) {
            Toggle(isOn: $isAvailable) {
                Label("Disponible", systemImage: "checkmark.circle.fill")
                    .font(AppFont.callout())
                    .foregroundStyle(AppColor.textPrimary)
            }
            .tint(AppColor.success)
            Divider()
            Toggle(isOn: $isPopular) {
                Label("Marcar como popular", systemImage: "flame.fill")
                    .font(AppFont.callout())
                    .foregroundStyle(AppColor.textPrimary)
            }
            .tint(AppColor.orange)
        }
        .cardStyle()
    }

    private func load() {
        if case let .edit(product) = mode {
            name = product.name
            description = product.description
            priceText = String(format: "%.0f", product.price)
            category = product.category
            symbol = product.symbol
            isAvailable = product.isAvailable
            isPopular = product.isPopular
        }
    }

    private func save() {
        let price = Double(priceText) ?? 0
        switch mode {
        case let .create(restaurantID):
            let product = Product(
                restaurantID: restaurantID,
                name: name,
                description: description,
                price: price,
                category: category,
                symbol: symbol,
                isAvailable: isAvailable,
                isPopular: isPopular
            )
            catalog.addProduct(product)
        case let .edit(existing):
            var updated = existing
            updated.name = name
            updated.description = description
            updated.price = price
            updated.category = category
            updated.symbol = symbol
            updated.isAvailable = isAvailable
            updated.isPopular = isPopular
            catalog.updateProduct(updated)
        }
        dismiss()
    }
}

#Preview {
    ProductFormView(mode: .create(restaurantID: MockData.tortasID))
        .environmentObject(CatalogStore())
}
