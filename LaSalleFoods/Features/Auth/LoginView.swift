//
//  LoginView.swift
//  LaSalleFoods
//
//  Pantalla 1: inicio de sesión para alumnos y dueños de local.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var session: SessionStore
    @StateObject private var viewModel = LoginViewModel()
    @FocusState private var focusedField: Field?
    @State private var showRegister = false

    private enum Field { case email, password }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                header
                form
                footer
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xl)
        }
        .background(AppColor.background.ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
        .sheet(isPresented: $showRegister) {
            RegisterView()
        }
    }

    // MARK: - Encabezado de marca

    private var header: some View {
        VStack(spacing: AppSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                    .fill(AppColor.brandGradient)
                    .frame(height: 200)
                    .appShadow(.floating)

                VStack(spacing: AppSpacing.xs) {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.white)
                    Text("La Salle Foods")
                        .font(AppFont.largeTitle())
                        .foregroundStyle(.white)
                    Text("Pide, paga y recoge sin filas")
                        .font(AppFont.callout())
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            .padding(.top, AppSpacing.xl)
        }
    }

    // MARK: - Formulario

    private var form: some View {
        VStack(spacing: AppSpacing.md) {
            LabeledInput(
                title: "Correo institucional",
                placeholder: "tucorreo@lasalle.edu.mx",
                text: $viewModel.email,
                icon: "envelope.fill",
                keyboard: .emailAddress
            )
            .focused($focusedField, equals: .email)
            .submitLabel(.next)
            .onSubmit { focusedField = .password }

            LabeledInput(
                title: "Contraseña",
                placeholder: "••••••••",
                text: $viewModel.password,
                icon: "lock.fill",
                isSecure: true
            )
            .focused($focusedField, equals: .password)
            .submitLabel(.go)
            .onSubmit { viewModel.signIn(using: session) }

            if let error = session.errorMessage {
                Text(error)
                    .font(AppFont.caption())
                    .foregroundStyle(AppColor.danger)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            AppButton(
                title: "Iniciar sesión",
                icon: "arrow.right",
                isLoading: session.isLoading,
                isEnabled: viewModel.isFormValid
            ) {
                focusedField = nil
                viewModel.signIn(using: session)
            }
        }
        .cardStyle()
    }

    // MARK: - Pie

    private var footer: some View {
        VStack(spacing: AppSpacing.xs) {
            HStack(spacing: 4) {
                Text("¿No tienes cuenta?")
                    .foregroundStyle(AppColor.textSecondary)
                Button("Regístrate") { showRegister = true }
                    .foregroundStyle(AppColor.orange)
                    .fontWeight(.semibold)
            }
            .font(AppFont.subheadline())

            Text("Universidad De La Salle Bajío · ISSC-612")
                .font(AppFont.caption())
                .foregroundStyle(AppColor.textPlaceholder)
        }
        .padding(.top, AppSpacing.xs)
    }
}

// MARK: - Input etiquetado

struct LabeledInput: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var isSecure: Bool = false
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            Text(title)
                .font(AppFont.caption())
                .foregroundStyle(AppColor.textSecondary)
            HStack(spacing: AppSpacing.xs) {
                if let icon {
                    Image(systemName: icon)
                        .foregroundStyle(AppColor.textPlaceholder)
                        .frame(width: 20)
                }
                Group {
                    if isSecure {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                            .keyboardType(keyboard)
                            .textInputAutocapitalization(.never)
                    }
                }
                .font(AppFont.body())
                .autocorrectionDisabled()
            }
            .padding(.horizontal, AppSpacing.md)
            .frame(height: 52)
            .background(AppColor.surfaceMuted)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(SessionStore())
}
