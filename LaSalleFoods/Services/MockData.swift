//
//  MockData.swift
//  LaSalleFoods
//
//  Datos de ejemplo para el prototipo de front-end. Toda la información
//  vive en memoria; no hay backend. Cuando se integre Firebase, estos
//  datos se reemplazarán por las respuestas reales del servicio.
//

import Foundation

enum MockData {

    // MARK: - IDs fijos para relacionar locales, productos y dueños

    static let tortasID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    static let sushiID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    static let healthyID = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
    static let coffeeID = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
    static let pizzaID = UUID(uuidString: "55555555-5555-5555-5555-555555555555")!
    static let snacksID = UUID(uuidString: "66666666-6666-6666-6666-666666666666")!

    // MARK: - Usuarios de ejemplo

    static let studentUser = User(
        name: "David Fonseca",
        email: "alumno@lasalle.edu.mx",
        role: .student
    )

    static let ownerUser = User(
        name: "Doña Mary",
        email: "local@lasalle.edu.mx",
        role: .owner,
        ownedRestaurantID: tortasID
    )

    // MARK: - Locales

    static let restaurants: [Restaurant] = [
        Restaurant(
            id: tortasID,
            name: "Tortas Doña Mary",
            category: "Mexicana · Tortas",
            description: "Las tortas más grandes del campus, recién hechas.",
            symbol: "takeoutbag.and.cup.and.straw.fill",
            coverHex: 0xFF7426,
            rating: 4.8,
            reviewCount: 320,
            prepTimeMinutes: 8...12,
            location: "Cafetería Central",
            tags: ["Popular", "Sin filas"]
        ),
        Restaurant(
            id: sushiID,
            name: "Sushi Lasalle",
            category: "Japonesa · Sushi",
            description: "Rollos frescos preparados al momento.",
            symbol: "fish.fill",
            coverHex: 0x0B3D91,
            rating: 4.6,
            reviewCount: 184,
            prepTimeMinutes: 12...18,
            location: "Edificio B, planta baja",
            tags: ["Nuevo"]
        ),
        Restaurant(
            id: healthyID,
            name: "Green & Fit",
            category: "Saludable · Bowls",
            description: "Ensaladas, bowls y jugos para recargar energía.",
            symbol: "leaf.fill",
            coverHex: 0x1FAA59,
            rating: 4.7,
            reviewCount: 142,
            prepTimeMinutes: 6...10,
            location: "Patio de comidas",
            tags: ["Saludable"]
        ),
        Restaurant(
            id: coffeeID,
            name: "Café La Salle",
            category: "Café · Postres",
            description: "Café de especialidad y postres caseros.",
            symbol: "cup.and.saucer.fill",
            coverHex: 0x8B5E34,
            rating: 4.9,
            reviewCount: 410,
            prepTimeMinutes: 4...8,
            location: "Biblioteca, primer piso",
            tags: ["Popular"]
        ),
        Restaurant(
            id: pizzaID,
            name: "Pizza Point",
            category: "Italiana · Pizza",
            description: "Rebanadas grandes y pizzas personales.",
            symbol: "triangle.fill",
            coverHex: 0xE23744,
            rating: 4.4,
            reviewCount: 96,
            prepTimeMinutes: 14...20,
            location: "Cafetería Central",
            isOpen: false,
            tags: []
        ),
        Restaurant(
            id: snacksID,
            name: "Snack Express",
            category: "Antojitos · Snacks",
            description: "Botanas, papas y bebidas para el recreo.",
            symbol: "popcorn.fill",
            coverHex: 0xFFA34D,
            rating: 4.3,
            reviewCount: 75,
            prepTimeMinutes: 3...6,
            location: "Edificio C, cafetería",
            tags: ["Rápido"]
        )
    ]

    // MARK: - Productos

    static let products: [Product] = [
        // Tortas Doña Mary
        Product(restaurantID: tortasID, name: "Torta de milanesa", description: "Milanesa de res, aguacate, jitomate y frijoles.", price: 65, category: .popular, symbol: "takeoutbag.and.cup.and.straw.fill", isPopular: true),
        Product(restaurantID: tortasID, name: "Torta cubana", description: "Surtido de carnes, queso y aguacate.", price: 75, category: .mains, symbol: "takeoutbag.and.cup.and.straw.fill", isPopular: true),
        Product(restaurantID: tortasID, name: "Torta de jamón", description: "Clásica con jamón, queso y vegetales.", price: 45, category: .mains),
        Product(restaurantID: tortasID, name: "Agua de horchata", description: "Vaso de 500 ml bien fría.", price: 20, category: .drinks, symbol: "cup.and.saucer.fill"),
        Product(restaurantID: tortasID, name: "Refresco", description: "Lata 355 ml.", price: 22, category: .drinks, symbol: "cup.and.saucer.fill", isAvailable: false),

        // Sushi Lasalle
        Product(restaurantID: sushiID, name: "California Roll", description: "8 piezas con surimi, aguacate y pepino.", price: 95, category: .popular, symbol: "fish.fill", isPopular: true),
        Product(restaurantID: sushiID, name: "Tampico Roll", description: "Empanizado con camarón y queso crema.", price: 110, category: .mains, symbol: "fish.fill"),
        Product(restaurantID: sushiID, name: "Edamames", description: "Vainas de soya al vapor con sal.", price: 45, category: .snacks, symbol: "leaf.fill"),
        Product(restaurantID: sushiID, name: "Té verde", description: "Caliente o frío.", price: 30, category: .drinks, symbol: "cup.and.saucer.fill"),

        // Green & Fit
        Product(restaurantID: healthyID, name: "Bowl de pollo", description: "Arroz integral, pollo, aguacate y vegetales.", price: 85, category: .popular, symbol: "leaf.fill", isPopular: true),
        Product(restaurantID: healthyID, name: "Ensalada César", description: "Lechuga, crutones, parmesano y aderezo.", price: 70, category: .mains, symbol: "leaf.fill"),
        Product(restaurantID: healthyID, name: "Jugo verde", description: "Apio, nopal, piña y limón.", price: 38, category: .drinks, symbol: "cup.and.saucer.fill"),

        // Café La Salle
        Product(restaurantID: coffeeID, name: "Capuccino", description: "Espresso con leche vaporizada.", price: 42, category: .popular, symbol: "cup.and.saucer.fill", isPopular: true),
        Product(restaurantID: coffeeID, name: "Latte vainilla", description: "Suave con jarabe de vainilla.", price: 48, category: .drinks, symbol: "cup.and.saucer.fill"),
        Product(restaurantID: coffeeID, name: "Brownie", description: "Con nuez y chispas de chocolate.", price: 35, category: .desserts, symbol: "birthday.cake.fill", isPopular: true),
        Product(restaurantID: coffeeID, name: "Galleta avena", description: "Hecha en casa.", price: 25, category: .desserts, symbol: "birthday.cake.fill"),

        // Snack Express
        Product(restaurantID: snacksID, name: "Papas con limón", description: "Bolsa grande con salsas.", price: 30, category: .popular, symbol: "popcorn.fill"),
        Product(restaurantID: snacksID, name: "Hot dog", description: "Con todo y aderezos.", price: 40, category: .mains, symbol: "takeoutbag.and.cup.and.straw.fill")
    ]

    // MARK: - Pedidos de ejemplo (historial)

    static func sampleOrders(for customerName: String) -> [Order] {
        [
            Order(
                folio: "LSF-2048",
                restaurantID: tortasID,
                restaurantName: "Tortas Doña Mary",
                customerName: customerName,
                lines: [
                    OrderLine(productName: "Torta de milanesa", quantity: 1, unitPrice: 65),
                    OrderLine(productName: "Agua de horchata", quantity: 1, unitPrice: 20)
                ],
                paymentMethod: .cash,
                status: .preparing,
                createdAt: Date().addingTimeInterval(-600),
                pickupCode: "A12"
            ),
            Order(
                folio: "LSF-1990",
                restaurantID: coffeeID,
                restaurantName: "Café La Salle",
                customerName: customerName,
                lines: [
                    OrderLine(productName: "Capuccino", quantity: 1, unitPrice: 42),
                    OrderLine(productName: "Brownie", quantity: 1, unitPrice: 35)
                ],
                paymentMethod: .card,
                status: .completed,
                createdAt: Date().addingTimeInterval(-86_400),
                pickupCode: "C07"
            ),
            Order(
                folio: "LSF-1834",
                restaurantID: sushiID,
                restaurantName: "Sushi Lasalle",
                customerName: customerName,
                lines: [
                    OrderLine(productName: "California Roll", quantity: 2, unitPrice: 95)
                ],
                paymentMethod: .card,
                status: .completed,
                createdAt: Date().addingTimeInterval(-3 * 86_400),
                pickupCode: "B22"
            )
        ]
    }
}
