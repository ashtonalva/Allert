//
//  UserProfile.swift
//  Allert_app
//
//  Created by Ashton Alva on 12/7/25.
//

import Foundation

struct UserProfile: Codable, Identifiable {
    var id: UUID
    var name: String
    var allergies: [Allergy]
    
    init(id: UUID = UUID(), name: String = "", allergies: [Allergy] = []) {
        self.id = id
        self.name = name
        self.allergies = allergies
    }
}

struct Allergy: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var keywords: [String] // Keywords to search for in menu items
    
    init(id: UUID = UUID(), name: String, keywords: [String] = []) {
        self.id = id
        self.name = name
        // If no keywords provided, use the allergy name and common variations
        self.keywords = keywords.isEmpty ? [name.lowercased()] : keywords
    }
    
    // Common allergy keywords mapping
    static func defaultKeywords(for allergyName: String) -> [String] {
        let lowercased = allergyName.lowercased()
        let keywordMap: [String: [String]] = [
            "peanuts": ["peanut", "peanuts", "groundnut", "groundnuts", "arachis"],
            "tree nuts": ["almond", "almonds", "walnut", "walnuts", "cashew", "cashews", "pistachio", "pistachios", "pecan", "pecans", "hazelnut", "hazelnuts", "macadamia", "brazil nut", "brazil nuts"],
            "dairy": ["milk", "cheese", "butter", "cream", "yogurt", "yoghurt", "whey", "casein", "lactose", "dairy"],
            "eggs": ["egg", "eggs", "mayonnaise", "mayo", "albumin", "albumen"],
            "soy": ["soy", "soya", "soybean", "soybeans", "tofu", "tempeh", "miso", "edamame"],
            "wheat": ["wheat", "flour", "bread", "pasta", "gluten", "semolina", "couscous"],
            "fish": ["fish", "salmon", "tuna", "cod", "halibut", "sardine", "anchovy", "anchovies"],
            "shellfish": ["shrimp", "prawn", "crab", "lobster", "crayfish", "scallop", "scallops", "oyster", "oysters", "mussel", "mussels", "clam", "clams", "shellfish"],
            "sesame": ["sesame", "tahini", "sesame seed", "sesame seeds"],
            "sulfites": ["sulfite", "sulfites", "sulphite", "sulphites", "sulfur dioxide"]
        ]
        
        return keywordMap[lowercased] ?? [lowercased]
    }
}

