//
//  ProfileView.swift
//  LaSalleFoods
//
//  Perfil del usuario con opciones básicas y cierre de sesión.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var session: SessionStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    profileHeader
                    optionsCard
                    AppButton(title: "Cerrar sesión", icon: "rectangle.portrait.and.arrow.right", kind: .destructive) {
                        Task { await session.signOut() }
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl)
            }
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle("Mi cuenta")
        }
    }

    private var profileHeader: some View {
        VStack(spacing: AppSpacing.sm) {
            ZStack {
                Circle()
                    .fill(AppColor.brandGradient)
                    .frame(width: 88, height: 88)
                Text(initials)
                    .font(AppFont.title())
                    .foregroundStyle(.white)
            }
            Text(session.currentUser?.name ?? "Usuario")
                .font(AppFont.title())
                .foregroundStyle(AppColor.textPrimary)
            Text(session.currentUser?.email ?? "")
                .font(AppFont.subheadline())
                .foregroundStyle(AppColor.textSecondary)
            TagChip(
                text: session.role?.title ?? "",
                icon: session.role?.icon,
                foreground: AppColor.orange,
                background: AppColor.orange.opacity(0.12)
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppSpacing.md)
    }

    private var optionsCard: some View {
        VStack(spacing: 0) {
            optionLink(icon: "person.fill", title: "Datos personales") {
                PersonalDataView()
            }
            Divider()
            optionLink(icon: "creditcard.fill", title: "Métodos de pago") {
                PaymentMethodsView()
            }
            Divider()
            optionLink(icon: "bell.fill", title: "Notificaciones") {
                NotificationSettingsView()
            }
            Divider()
            optionLink(icon: "questionmark.circle.fill", title: "Ayuda y soporte") {
                HelpSupportView()
            }
        }
        .cardStyle(padding: 0)
    }

    private func optionLink<Destination: View>(
        icon: String,
        title: String,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: icon)
                    .foregroundStyle(AppColor.orange)
                    .frame(width: 28)
                Text(title)
                    .font(AppFont.body())
                    .foregroundStyle(AppColor.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColor.textPlaceholder)
            }
            .padding(AppSpacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var initials: String {
        let parts = (session.currentUser?.name ?? "U").components(separatedBy: " ")
        return parts.prefix(2).compactMap { $0.first }.map(String.init).joined().uppercased()
    }
}

// MARK: - Datos personales

private struct PersonalDataView: View {
    @EnvironmentObject private var session: SessionStore

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.md) {
                infoCard
            }
            .padding(AppSpacing.lg)
        }
        .background(AppColor.background.ignoresSafeArea())
        .navigationTitle("Datos personales")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var infoCard: some View {
        VStack(spacing: 0) {
            infoRow(icon: "person.fill", title: "Nombre", value: session.currentUser?.name ?? "—")
            Divider()
            infoRow(icon: "envelope.fill", title: "Correo", value: session.currentUser?.email ?? "—")
            Divider()
            infoRow(icon: session.role?.icon ?? "person", title: "Rol", value: session.role?.title ?? "—")
        }
        .cardStyle(padding: 0)
    }

    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .foregroundStyle(AppColor.orange)
                .frame(width: 28)
            Text(title)
                .font(AppFont.body())
                .foregroundStyle(AppColor.textPrimary)
            Spacer()
            Text(value)
                .font(AppFont.subheadline())
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.trailing)
        }
        .padding(AppSpacing.md)
    }
}

// MARK: - Métodos de pago

private struct PaymentMethodsView: View {
    @AppStorage("preferredPaymentMethod") private var preferred: String = PaymentMethod.cash.rawValue

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Elige tu método de pago preferido para tus próximos pedidos.")
                    .font(AppFont.subheadline())
                    .foregroundStyle(AppColor.textSecondary)
                ForEach(PaymentMethod.allCases) { method in
                    Button {
                        withAnimation(.snappy) { preferred = method.rawValue }
                    } label: {
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: method.icon)
                                .font(.system(size: 20))
                                .foregroundStyle(preferred == method.rawValue ? AppColor.orange : AppColor.textSecondary)
                                .frame(width: 32)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(method.rawValue)
                                    .font(AppFont.callout())
                                    .foregroundStyle(AppColor.textPrimary)
                                Text(method.subtitle)
                                    .font(AppFont.caption())
                                    .foregroundStyle(AppColor.textSecondary)
                            }
                            Spacer()
                            Image(systemName: preferred == method.rawValue ? "largecircle.fill.circle" : "circle")
                                .foregroundStyle(preferred == method.rawValue ? AppColor.orange : AppColor.border)
                        }
                        .cardStyle()
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(AppSpacing.lg)
        }
        .background(AppColor.background.ignoresSafeArea())
        .navigationTitle("Métodos de pago")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Ajustes de notificaciones

private struct NotificationSettingsView: View {
    @AppStorage("notifyOrderUpdates") private var orderUpdates = true
    @AppStorage("notifyReady") private var readyAlerts = true
    @AppStorage("notifyPromos") private var promos = false

    var body: some View {
        Form {
            Section {
                Toggle("Avances de mis pedidos", isOn: $orderUpdates)
                Toggle("Aviso cuando esté listo", isOn: $readyAlerts)
            } header: {
                Text("Pedidos")
            } footer: {
                Text("Recibe avisos cuando el local prepare, tenga listo o entregue tu pedido.")
            }

            Section {
                Toggle("Promociones y novedades", isOn: $promos)
            } header: {
                Text("Marketing")
            }
        }
        .tint(AppColor.orange)
        .scrollContentBackground(.hidden)
        .background(AppColor.background.ignoresSafeArea())
        .navigationTitle("Notificaciones")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Ayuda y soporte

private struct HelpSupportView: View {
    private let faqs: [(q: String, a: String)] = [
        ("¿Cómo hago un pedido?", "Elige un local, agrega productos al carrito y confirma tu pedido con el método de pago que prefieras."),
        ("¿Puedo cancelar un pedido?", "Sí, mientras el local no haya comenzado a prepararlo. Cuando pasa a “En preparación” ya no se puede cancelar."),
        ("¿Dónde recojo mi pedido?", "En el local que elegiste. Muestra tu código de recogida que aparece en el detalle del pedido."),
        ("¿Cómo pago?", "Puedes pagar en efectivo al recoger o con tarjeta de débito/crédito.")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    SectionHeader(title: "Preguntas frecuentes")
                    ForEach(faqs, id: \.q) { item in
                        DisclosureGroup {
                            Text(item.a)
                                .font(AppFont.subheadline())
                                .foregroundStyle(AppColor.textSecondary)
                                .padding(.top, AppSpacing.xxs)
                        } label: {
                            Text(item.q)
                                .font(AppFont.callout())
                                .foregroundStyle(AppColor.textPrimary)
                        }
                        .tint(AppColor.orange)
                        .padding(.vertical, AppSpacing.xxs)
                        if item.q != faqs.last?.q { Divider() }
                    }
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    SectionHeader(title: "Contacto")
                    Label("soporte@lasallefoods.mx", systemImage: "envelope.fill")
                        .font(AppFont.body())
                        .foregroundStyle(AppColor.textPrimary)
                    Label("Lun a Vie · 8:00 a 18:00", systemImage: "clock.fill")
                        .font(AppFont.subheadline())
                        .foregroundStyle(AppColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()
            }
            .padding(AppSpacing.lg)
        }
        .background(AppColor.background.ignoresSafeArea())
        .navigationTitle("Ayuda y soporte")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ProfileView()
        .environmentObject(SessionStore())
}
