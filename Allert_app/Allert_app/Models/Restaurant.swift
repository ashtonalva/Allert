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
    
    // Computed property to check if item is safe
    func isSafe(for allergies: [Allergy]) -> Bool {
        guard !allergies.isEmpty else { return true }
        
        let itemText = "\(name) \(description ?? "")".lowercased()
        
        for allergy in allergies {
            for keyword in allergy.keywords {
                if itemText.contains(keyword.lowercased()) {
                    return false
                }
            }
        }
        
        // Also check ingredients if available
        if let ingredients = ingredients {
            let ingredientsText = ingredients.joined(separator: " ").lowercased()
            for allergy in allergies {
                for keyword in allergy.keywords {
                    if ingredientsText.contains(keyword.lowercased()) {
                        return false
                    }
                }
            }
        }
        
        return true
    }
    
    func containsAllergen(_ allergy: Allergy) -> Bool {
        let itemText = "\(name) \(description ?? "")".lowercased()
        
        for keyword in allergy.keywords {
            if itemText.contains(keyword.lowercased()) {
                return true
            }
        }
        
        if let ingredients = ingredients {
            let ingredientsText = ingredients.joined(separator: " ").lowercased()
            for keyword in allergy.keywords {
                if ingredientsText.contains(keyword.lowercased()) {
                    return true
                }
            }
        }
        
        return false
    }
}

struct Menu: Codable {
    var items: [MenuItem]
    var categories: [String]
}

