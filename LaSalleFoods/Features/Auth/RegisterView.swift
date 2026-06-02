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
    @State private var localCategory = ""
    @State private var localLocation = ""

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
            LabeledInput(title: "Contraseña", placeholder: "Mínimo 4 caracteres", text: $password, icon: "lock.fill", isSecure: true)
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
            LabeledInput(title: "Tipo de comida", placeholder: "Ej. Mexicana · Tortas", text: $localCategory, icon: "fork.knife")
            LabeledInput(title: "Ubicación en el campus", placeholder: "Ej. Cafetería Central", text: $localLocation, icon: "mappin.and.ellipse")
        }
        .cardStyle()
    }

    // MARK: - Validación y registro

    private var isFormValid: Bool {
        let baseValid = !name.trimmingCharacters(in: .whitespaces).isEmpty &&
            email.contains("@") &&
            password.count >= 4 &&
            password == confirmPassword

        guard role == .owner else { return baseValid }
        return baseValid &&
            !localName.trimmingCharacters(in: .whitespaces).isEmpty &&
            !localCategory.trimmingCharacters(in: .whitespaces).isEmpty &&
            !localLocation.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func register() {
        guard isFormValid else {
            errorMessage = "Revisa los datos: el correo debe ser válido y las contraseñas deben coincidir."
            return
        }
        errorMessage = nil
        isLoading = true

        Task {
            try? await Task.sleep(for: .milliseconds(700))

            var restaurantID: UUID?
            if role == .owner {
                let restaurant = catalog.addRestaurant(
                    name: localName,
                    category: localCategory,
                    location: localLocation
                )
                restaurantID = restaurant.id
            }

            session.signUp(name: name, email: email, role: role, ownedRestaurantID: restaurantID)
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
