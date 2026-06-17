//
//  RegisterView.swift
//  LaSalleFoods
//
//  Registro de nuevas cuentas para ambos roles:
//  - Consumidor (alumno): nombre, correo y contraseña.
//  - Locatario (dueño): además da de alta su local.
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject private var session: SessionStore
    @EnvironmentObject private var catalog: CatalogStore
    @Environment(\.dismiss) private var dismiss

    @State private var role: UserRole = .student
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    // Datos del local (solo para locatario)
    @State private var localName = ""
    @State private var localLocation = ""
    @State private var categories: [CatalogStore.RestaurantCategory] = []
    @State private var selectedCategoryID: Int?

    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    roleSelector
                    accountForm
                    if role == .owner {
                        localForm
                    }
                    if let errorMessage {
                        Text(errorMessage)
                            .font(AppFont.caption())
                            .foregroundStyle(AppColor.danger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    AppButton(
                        title: "Crear cuenta",
                        icon: "checkmark.circle.fill",
                        isLoading: isLoading,
                        isEnabled: isFormValid
                    ) {
                        register()
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)
            }
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle("Crear cuenta")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .task {
                categories = await catalog.loadRestaurantCategories()
            }
        }
    }

    // MARK: - Selector de rol

    private var roleSelector: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Tipo de cuenta")
                .font(AppFont.callout())
                .foregroundStyle(AppColor.textSecondary)
            HStack(spacing: AppSpacing.sm) {
                ForEach(UserRole.allCases) { item in
                    Button {
                        withAnimation(.snappy) { role = item }
                    } label: {
                        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                            Image(systemName: item.icon)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(role == item ? .white : AppColor.orange)
                            Text(item.title)
                                .font(AppFont.callout())
                                .foregroundStyle(role == item ? .white : AppColor.textPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(AppSpacing.md)
                        .background(role == item ? AppColor.orange : AppColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                                .stroke(role == item ? Color.clear : AppColor.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Datos de la cuenta

    private var accountForm: some View {
        VStack(spacing: AppSpacing.md) {
            LabeledInput(title: "Nombre completo", placeholder: "Tu nombre", text: $name, icon: "person.fill")
            LabeledInput(title: "Correo institucional", placeholder: "tucorreo@lasalle.edu.mx", text: $email, icon: "envelope.fill", keyboard: .emailAddress)
            LabeledInput(title: "Contraseña", placeholder: "Mínimo 6 caracteres", text: $password, icon: "lock.fill", isSecure: true)
            LabeledInput(title: "Confirmar contraseña", placeholder: "Repite tu contraseña", text: $confirmPassword, icon: "lock.rotation", isSecure: true)
        }
        .cardStyle()
    }

    // MARK: - Datos del local (locatario)

    private var localForm: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: 6) {
                Image(systemName: "storefront.fill")
                    .foregroundStyle(AppColor.orange)
                Text("Datos de tu local")
                    .font(AppFont.headline())
                    .foregroundStyle(AppColor.textPrimary)
            }
            LabeledInput(title: "Nombre del local", placeholder: "Ej. Tortas Doña Mary", text: $localName, icon: "tag.fill")
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
            LabeledInput(title: "Ubicación en el campus", placeholder: "Ej. Cafetería Central", text: $localLocation, icon: "mappin.and.ellipse")
        }
        .cardStyle()
    }

    // MARK: - Validación y registro

    private var isFormValid: Bool {
        let baseValid = !name.trimmingCharacters(in: .whitespaces).isEmpty &&
            email.isInstitutionalEmail &&
            password.count >= 6 &&
            password == confirmPassword

        guard role == .owner else { return baseValid }
        return baseValid &&
            !localName.trimmingCharacters(in: .whitespaces).isEmpty &&
            selectedCategoryID != nil &&
            !localLocation.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func register() {
        guard isFormValid else {
            if !email.isInstitutionalEmail {
                errorMessage = "Usa tu correo institucional @lasallebajio.edu.mx"
            } else {
                errorMessage = "Revisa los datos: las contraseñas deben coincidir y la contraseña debe tener al menos 6 caracteres."
            }
            return
        }
        errorMessage = nil
        isLoading = true

        Task {
            await session.signUp(name: name, email: email, password: password, role: role)
            if let error = session.errorMessage {
                errorMessage = error
                isLoading = false
                return
            }

            if role == .owner {
                if let restaurant = await catalog.addRestaurant(
                    name: localName,
                    categoryID: selectedCategoryID!,
                    location: localLocation
                ) {
                    session.setOwnedRestaurant(restaurant.id)
                } else {
                    errorMessage = catalog.errorMessage ?? "No se pudo crear el local. Intenta de nuevo."
                    isLoading = false
                    return
                }
            }

            isLoading = false
            dismiss()
        }
    }
}

#Preview {
    RegisterView()
        .environmentObject(SessionStore())
        .environmentObject(CatalogStore())
}
