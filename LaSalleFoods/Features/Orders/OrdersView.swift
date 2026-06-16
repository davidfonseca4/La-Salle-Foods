//
//  OrdersView.swift
//  LaSalleFoods
//
//  Pantalla 5: historial y búsqueda de pedidos del alumno.
//

import SwiftUI

struct OrdersView: View {
    @EnvironmentObject private var orders: OrderStore
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    SearchField(placeholder: "Busca por folio, local o producto", text: $searchText)

                    if !activeOrders.isEmpty {
                        SectionHeader(title: "En curso")
                        ForEach(activeOrders) { order in
                            NavigationLink(value: order) {
                                OrderCard(order: order)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if !pastOrders.isEmpty {
                        SectionHeader(title: "Historial")
                        ForEach(pastOrders) { order in
                            NavigationLink(value: order) {
                                OrderCard(order: order)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if results.isEmpty {
                        EmptyStateView(
                            icon: "bag.badge.questionmark",
                            title: "Sin pedidos",
                            message: searchText.isEmpty
                                ? "Aún no has realizado pedidos. ¡Haz el primero!"
                                : "No encontramos pedidos para “\(searchText)”."
                        )
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl)
            }
            .background(AppColor.background.ignoresSafeArea())
            .task { await orders.loadOrders() }
            .refreshable { await orders.loadOrders() }
            .navigationTitle("Mis pedidos")
            .navigationDestination(for: Order.self) { order in
                OrderDetailView(order: order)
            }
        }
    }

    private var results: [Order] {
        orders.search(searchText)
    }

    private var activeOrders: [Order] {
        results.filter { $0.status == .pending || $0.status == .preparing || $0.status == .ready }
    }

    private var pastOrders: [Order] {
        results.filter { $0.status == .completed || $0.status == .cancelled }
    }
}

#Preview {
    OrdersView()
        .environmentObject(SessionStore())
        .environmentObject(OrderStore())
}
