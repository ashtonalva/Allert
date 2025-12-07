//
//  Restaurant.swift
//  Allert_app
//
//  Created by Ashton Alva on 12/7/25.
//

import Foundation

struct Restaurant: Codable, Identifiable {
    var id: String
    var name: String
    var rating: Double?
    var price: String?
    var imageUrl: String?
    var location: RestaurantLocation?
    var phone: String?
    var url: String?
    var menuUrl: String?
    
    struct RestaurantLocation: Codable {
        var address1: String?
        var city: String?
        var state: String?
        var zipCode: String?
        var displayAddress: [String]?
    }
}

struct MenuItem: Codable, Identifiable {
    var id: String
    var name: String
    var description: String?
    var price: String?
    var category: String?
    var ingredients: [String]?
    var aiDetectedIngredients: [String]? // Ingredients detected by AI analysis
    
    // Get all ingredients (explicit + AI-detected)
    var allIngredients: [String] {
        var all: Set<String> = []
        if let explicit = ingredients {
            all.formUnion(explicit)
        }
        if let aiDetected = aiDetectedIngredients {
            all.formUnion(aiDetected)
        }
        return Array(all).sorted()
    }
    
    // Computed property to check if item is safe
    func isSafe(for allergies: [Allergy]) -> Bool {
        guard !allergies.isEmpty else { return true }
        
        let itemText = "\(name) \(description ?? "")".lowercased()
        
        // Check name and description
        for allergy in allergies {
            for keyword in allergy.keywords {
                if itemText.contains(keyword.lowercased()) {
                    return false
                }
            }
        }
        
        // Check all ingredients (explicit + AI-detected)
        let allIngredientsText = allIngredients.joined(separator: " ").lowercased()
        for allergy in allergies {
            for keyword in allergy.keywords {
                if allIngredientsText.contains(keyword.lowercased()) {
                    return false
                }
            }
        }
        
        return true
    }
    
    func containsAllergen(_ allergy: Allergy) -> Bool {
        let itemText = "\(name) \(description ?? "")".lowercased()
        
        // Check name and description
        for keyword in allergy.keywords {
            if itemText.contains(keyword.lowercased()) {
                return true
            }
        }
        
        // Check all ingredients
        let allIngredientsText = allIngredients.joined(separator: " ").lowercased()
        for keyword in allergy.keywords {
            if allIngredientsText.contains(keyword.lowercased()) {
                return true
            }
        }
        
        return false
    }
}

struct Menu: Codable {
    var items: [MenuItem]
    var categories: [String]
}

