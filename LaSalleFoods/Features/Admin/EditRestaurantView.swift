//
//  EditRestaurantView.swift
//  LaSalleFoods
//
//  Hoja modal para que el dueño edite los datos de su propio local
//  (nombre, descripción, ubicación, tipo de comida, tiempo de preparación
//  y estado abierto/cerrado) y administre sus etiquetas. Usa los endpoints
//  PATCH /api/restaurants/{id} y PUT /api/restaurants/{id}/tags.
//

import SwiftUI

struct EditRestaurantView: View {
    let restaurant: Restaurant

    @EnvironmentObject private var catalog: CatalogStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var description: String
    @State private var location: String
    @State private var prepMin: Int
    @State private var prepMax: Int
    @State private var isOpen: Bool

    @State private var categories: [CatalogStore.RestaurantCategory] = []
    @State private var selectedCategoryID: Int?

    @State private var allTags: [CatalogStore.TagOption] = []
    @State private var selectedTagIDs: Set<Int> = []

    @State private var isLoading = false
    @State private var errorMessage: String?

    init(restaurant: Restaurant) {
        self.restaurant = restaurant
        _name = State(initialValue: restaurant.name)
        _description = State(initialValue: restaurant.description)
        _location = State(initialValue: restaurant.location)
        _prepMin = State(initialValue: restaurant.prepTimeMinutes.lowerBound)
        _prepMax = State(initialValue: restaurant.prepTimeMinutes.upperBound)
        _isOpen = State(initialValue: restaurant.isOpen)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    dataCard
                    categoryCard
                    prepCard
                    tagsCard

                    if let errorMessage {
                        Text(errorMessage)
                            .font(AppFont.caption())
                            .foregroundStyle(AppColor.danger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    AppButton(
                        title: "Guardar cambios",
                        icon: "checkmark.circle.fill",
                        isLoading: isLoading,
                        isEnabled: isFormValid
                    ) {
                        save()
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)
            }
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle("Editar local")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .task {
                categories = await catalog.loadRestaurantCategories()
                selectedCategoryID = categories.first { $0.name == restaurant.category }?.id
                allTags = await catalog.loadTags()
                selectedTagIDs = Set(allTags.filter { restaurant.tags.contains($0.name) }.map(\.id))
            }
        }
    }

    // MARK: - Secciones

    private var dataCard: some View {
        VStack(spacing: AppSpacing.md) {
            LabeledInput(title: "Nombre del local", placeholder: "Ej. Tortas Doña Mary", text: $name, icon: "tag.fill")
            LabeledInput(title: "Descripción", placeholder: "Breve descripción de tu local", text: $description, icon: "text.alignleft")
            LabeledInput(title: "Ubicación en el campus", placeholder: "Ej. Cafetería Central", text: $location, icon: "mappin.and.ellipse")
            Toggle(isOn: $isOpen) {
                Text("Local abierto")
                    .font(AppFont.callout())
                    .foregroundStyle(AppColor.textPrimary)
            }
            .tint(AppColor.orange)
        }
        .cardStyle()
    }

    private var categoryCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Tipo de comida")
                .font(AppFont.callout())
                .foregroundStyle(AppColor.textSecondary)
            Picker("Tipo de comida", selection: $selectedCategoryID) {
                Text("Selecciona una opción").tag(Int?.none)
                ForEach(categories) { category in
                    Text(category.name).tag(Optional(category.id))
                }
            }
            .pickerStyle(.menu)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var prepCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Tiempo de preparación (min)")
                .font(AppFont.callout())
                .foregroundStyle(AppColor.textSecondary)
            Stepper(value: $prepMin, in: 1...120) {
                Text("Mínimo: \(prepMin) min")
                    .font(AppFont.subheadline())
                    .foregroundStyle(AppColor.textPrimary)
            }
            Stepper(value: $prepMax, in: max(prepMin, 1)...180) {
                Text("Máximo: \(prepMax) min")
                    .font(AppFont.subheadline())
                    .foregroundStyle(AppColor.textPrimary)
            }
        }
        .cardStyle()
    }

    private var tagsCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Etiquetas")
                .font(AppFont.callout())
                .foregroundStyle(AppColor.textSecondary)
            if allTags.isEmpty {
                Text("Cargando etiquetas…")
                    .font(AppFont.caption())
                    .foregroundStyle(AppColor.textPlaceholder)
            } else {
                FlowTags(tags: allTags, selected: $selectedTagIDs)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Validación y guardado

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !location.trimmingCharacters(in: .whitespaces).isEmpty
            && selectedCategoryID != nil
            && prepMax >= prepMin
    }

    private func save() {
        guard let categoryID = selectedCategoryID else { return }
        errorMessage = nil
        isLoading = true
        Task {
            let ok = await catalog.updateRestaurant(
                id: restaurant.id,
                name: name,
                description: description,
                location: location,
                categoryID: categoryID,
                prepMin: prepMin,
                prepMax: prepMax,
                isOpen: isOpen
            )
            if ok {
                _ = await catalog.updateRestaurantTags(id: restaurant.id, tagIDs: Array(selectedTagIDs))
            }
            isLoading = false
            if ok {
                dismiss()
            } else {
                errorMessage = catalog.errorMessage ?? "No se pudieron guardar los cambios."
            }
        }
    }
}

/// Disposición tipo "wrap" de chips de etiquetas seleccionables.
private struct FlowTags: View {
    let tags: [CatalogStore.TagOption]
    @Binding var selected: Set<Int>

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: AppSpacing.xs)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: AppSpacing.xs) {
            ForEach(tags) { tag in
                FilterChip(title: tag.name, isSelected: selected.contains(tag.id)) {
                    if selected.contains(tag.id) {
                        selected.remove(tag.id)
                    } else {
                        selected.insert(tag.id)
                    }
                }
            }
        }
    }
}

#Preview {
    EditRestaurantView(restaurant: Restaurant(
        name: "Tortas Doña Mary",
        category: "Mexicana",
        description: "Tortas y aguas frescas.",
        symbol: "storefront.fill",
        coverHex: 0xE23744,
        rating: 4.6,
        reviewCount: 128,
        prepTimeMinutes: 8...15,
        location: "Cafetería Central",
        tags: ["Popular", "Sin filas"]
    ))
    .environmentObject(CatalogStore())
}
