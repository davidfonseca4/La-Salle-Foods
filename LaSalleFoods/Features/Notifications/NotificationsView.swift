//
//  NotificationsView.swift
//  LaSalleFoods
//
//  Bandeja de avisos del alumno: cambios de estado de sus pedidos
//  (en preparación, listo, entregado o cancelado por el local).
//

import SwiftUI

struct NotificationsView: View {
    /// Identificador del destinatario (nombre del cliente para el alumno).
    let audienceID: String

    @EnvironmentObject private var orders: OrderStore

    private var items: [AppNotification] {
        orders.notifications(forAudience: audienceID)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                if items.isEmpty {
                    EmptyStateView(
                        icon: "bell.slash",
                        title: "Sin avisos",
                        message: "Aquí verás el avance de tus pedidos: cuando el local los prepare, estén listos o se entreguen."
                    )
                } else {
                    ForEach(items) { notification in
                        NotificationRow(notification: notification)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.xl)
        }
        .background(AppColor.background.ignoresSafeArea())
        .navigationTitle("Notificaciones")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { orders.markNotificationsRead(forAudience: audienceID) }
    }
}

struct NotificationRow: View {
    let notification: AppNotification

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            ZStack {
                Circle()
                    .fill(Color(hex: notification.tintHex).opacity(0.14))
                    .frame(width: 40, height: 40)
                Image(systemName: notification.iconName)
                    .font(.system(size: 18))
                    .foregroundStyle(Color(hex: notification.tintHex))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(notification.title)
                    .font(AppFont.callout())
                    .foregroundStyle(AppColor.textPrimary)
                Text(notification.message)
                    .font(AppFont.subheadline())
                    .foregroundStyle(AppColor.textSecondary)
                Text(notification.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(AppFont.caption())
                    .foregroundStyle(AppColor.textPlaceholder)
            }
            Spacer()
            if !notification.isRead {
                Circle()
                    .fill(AppColor.orange)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
            }
        }
        .cardStyle(padding: AppSpacing.sm)
    }
}

#Preview {
    NavigationStack {
        NotificationsView(audienceID: MockData.studentUser.name)
            .environmentObject(OrderStore())
    }
}
