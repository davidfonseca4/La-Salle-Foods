//
//  HomeViewModel.swift
//  LaSalleFoods
//
//  Filtra y busca locales para la pantalla principal del alumno.
//

import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var selectedCategory: String = "Todos"

    let categories: [String] = ["Todos", "Mexicana", "Japonesa", "Saludable", "Café", "Pizza", "Snacks"]

    func filteredRestaurants(from restaurants: [Restaurant]) -> [Restaurant] {
        restaurants.filter { restaurant in
            let matchesSearch = searchText.isEmpty ||
                restaurant.name.localizedCaseInsensitiveContains(searchText) ||
                restaurant.category.localizedCaseInsensitiveContains(searchText)

            let matchesCategory = selectedCategory == "Todos" ||
                restaurant.category.localizedCaseInsensitiveContains(selectedCategory)

            return matchesSearch && matchesCategory
        }
    }
}
