//
//  YelpService.swift
//  Allert_app
//
//  Created by Ashton Alva on 12/7/25.
//

import Foundation
import Combine

class YelpService: ObservableObject {
    // NOTE: You'll need to get your own Yelp API key from https://www.yelp.com/developers
    // For now, this is a placeholder. Replace with your actual API key.
    private let apiKey = "YOUR_YELP_API_KEY_HERE"
    private let baseURL = "https://api.yelp.com/v3"
    
    // Common allergies for quick selection
    static let commonAllergies: [String] = [
        "Peanuts",
        "Tree Nuts",
        "Dairy",
        "Eggs",
        "Soy",
        "Wheat",
        "Fish",
        "Shellfish",
        "Sesame",
        "Sulfites"
    ]
    
    func searchRestaurants(query: String, location: String = "San Francisco, CA") async throws -> [Restaurant] {
        guard apiKey != "YOUR_YELP_API_KEY_HERE" else {
            // Return mock data for development
            return mockRestaurants()
        }
        
        var components = URLComponents(string: "\(baseURL)/businesses/search")!
        components.queryItems = [
            URLQueryItem(name: "term", value: query),
            URLQueryItem(name: "location", value: location),
            URLQueryItem(name: "categories", value: "restaurants,food")
        ]
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(YelpSearchResponse.self, from: data)
        
        return response.businesses.map { business in
            Restaurant(
                id: business.id,
                name: business.name,
                rating: business.rating,
                price: business.price,
                imageUrl: business.image_url,
                location: Restaurant.RestaurantLocation(
                    address1: business.location?.address1,
                    city: business.location?.city,
                    state: business.location?.state,
                    zipCode: business.location?.zip_code,
                    displayAddress: business.location?.display_address
                ),
                phone: business.phone,
                url: business.url,
                menuUrl: nil
            )
        }
    }
    
    func getMenuItems(for restaurant: Restaurant) async throws -> [MenuItem] {
        // Yelp API doesn't directly provide menu items
        // In a real app, you might:
        // 1. Use a menu scraping service
        // 2. Use restaurant's website API
        // 3. Use a third-party menu service
        
        // For now, return mock menu items
        return mockMenuItems(for: restaurant)
    }
    
    // MARK: - Mock Data for Development
    
    func mockRestaurants() -> [Restaurant] {
        return [
            Restaurant(
                id: "1",
                name: "The Local Cafe",
                rating: 4.5,
                price: "$$",
                imageUrl: nil,
                location: Restaurant.RestaurantLocation(
                    address1: "123 Main St",
                    city: "San Francisco",
                    state: "CA",
                    zipCode: "94102",
                    displayAddress: ["123 Main St", "San Francisco, CA 94102"]
                ),
                phone: "(415) 555-1234",
                url: nil,
                menuUrl: nil
            ),
            Restaurant(
                id: "2",
                name: "Ocean Breeze Seafood",
                rating: 4.8,
                price: "$$$",
                imageUrl: nil,
                location: Restaurant.RestaurantLocation(
                    address1: "456 Ocean Ave",
                    city: "San Francisco",
                    state: "CA",
                    zipCode: "94112",
                    displayAddress: ["456 Ocean Ave", "San Francisco, CA 94112"]
                ),
                phone: "(415) 555-5678",
                url: nil,
                menuUrl: nil
            ),
            Restaurant(
                id: "3",
                name: "Garden Fresh Bistro",
                rating: 4.3,
                price: "$$",
                imageUrl: nil,
                location: Restaurant.RestaurantLocation(
                    address1: "789 Market St",
                    city: "San Francisco",
                    state: "CA",
                    zipCode: "94103",
                    displayAddress: ["789 Market St", "San Francisco, CA 94103"]
                ),
                phone: "(415) 555-9012",
                url: nil,
                menuUrl: nil
            )
        ]
    }
    
    private func mockMenuItems(for restaurant: Restaurant) -> [MenuItem] {
        let baseItems: [MenuItem] = [
            MenuItem(
                id: "1",
                name: "Caesar Salad",
                description: "Fresh romaine lettuce with caesar dressing, parmesan cheese, and croutons",
                price: "$12.99",
                category: "Salads",
                ingredients: ["romaine", "caesar dressing", "parmesan cheese", "croutons", "wheat"]
            ),
            MenuItem(
                id: "2",
                name: "Grilled Chicken Breast",
                description: "Tender grilled chicken served with seasonal vegetables",
                price: "$18.99",
                category: "Main Courses",
                ingredients: ["chicken", "vegetables", "olive oil"]
            ),
            MenuItem(
                id: "3",
                name: "Peanut Butter Chocolate Cake",
                description: "Rich chocolate cake with peanut butter frosting",
                price: "$8.99",
                category: "Desserts",
                ingredients: ["chocolate", "peanut butter", "flour", "eggs", "sugar", "butter"]
            ),
            MenuItem(
                id: "4",
                name: "Fish Tacos",
                description: "Fresh cod tacos with cabbage slaw and chipotle aioli",
                price: "$15.99",
                category: "Main Courses",
                ingredients: ["cod", "tortillas", "cabbage", "mayonnaise", "chipotle"]
            ),
            MenuItem(
                id: "5",
                name: "Vegan Quinoa Bowl",
                description: "Quinoa with roasted vegetables, avocado, and tahini dressing",
                price: "$14.99",
                category: "Main Courses",
                ingredients: ["quinoa", "vegetables", "avocado", "tahini", "sesame"]
            ),
            MenuItem(
                id: "6",
                name: "Shrimp Scampi",
                description: "Garlic shrimp with pasta in white wine sauce",
                price: "$22.99",
                category: "Main Courses",
                ingredients: ["shrimp", "pasta", "garlic", "white wine", "butter", "wheat"]
            ),
            MenuItem(
                id: "7",
                name: "Almond Crusted Salmon",
                description: "Salmon fillet with almond crust, served with rice and vegetables",
                price: "$24.99",
                category: "Main Courses",
                ingredients: ["salmon", "almonds", "rice", "vegetables"]
            ),
            MenuItem(
                id: "8",
                name: "Caprese Salad",
                description: "Fresh mozzarella, tomatoes, and basil with balsamic glaze",
                price: "$11.99",
                category: "Salads",
                ingredients: ["mozzarella", "tomatoes", "basil", "balsamic", "dairy"]
            )
        ]
        
        // Add restaurant-specific items
        if restaurant.name.contains("Seafood") {
            return baseItems + [
                MenuItem(
                    id: "9",
                    name: "Lobster Roll",
                    description: "Fresh lobster with mayonnaise on a buttered roll",
                    price: "$28.99",
                    category: "Main Courses",
                    ingredients: ["lobster", "mayonnaise", "butter", "bread", "eggs", "dairy"]
                ),
                MenuItem(
                    id: "10",
                    name: "Crab Cakes",
                    description: "Pan-seared crab cakes with remoulade sauce",
                    price: "$19.99",
                    category: "Appetizers",
                    ingredients: ["crab", "breadcrumbs", "mayonnaise", "eggs", "wheat"]
                )
            ]
        }
        
        return baseItems
    }
}

// MARK: - Yelp API Response Models

private struct YelpSearchResponse: Codable {
    let businesses: [YelpBusiness]
}

private struct YelpBusiness: Codable {
    let id: String
    let name: String
    let rating: Double?
    let price: String?
    let image_url: String?
    let location: YelpLocation?
    let phone: String?
    let url: String?
}

private struct YelpLocation: Codable {
    let address1: String?
    let city: String?
    let state: String?
    let zip_code: String?
    let display_address: [String]?
}

