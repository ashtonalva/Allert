//
//  AIIngredientService.swift
//  Allert_app
//
//  Created by Ashton Alva on 12/7/25.
//

import Foundation
import Combine

class AIIngredientService: ObservableObject {
    static let shared = AIIngredientService()
    
    // NOTE: You'll need to get your own OpenAI API key from https://platform.openai.com/api-keys
    // For now, this is a placeholder. Replace with your actual API key.
    private let openAIAPIKey = "YOUR_OPENAI_API_KEY_HERE"
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    // Cache to avoid redundant API calls
    private var ingredientCache: [String: [String]] = [:]
    
    private init() {}
    
    /// Analyzes a menu item and returns likely ingredients using AI
    func analyzeMenuItem(_ item: MenuItem) async throws -> [String] {
        // Create a cache key from item name and description
        let cacheKey = "\(item.name) \(item.description ?? "")"
        
        // Check cache first
        if let cached = ingredientCache[cacheKey] {
            return cached
        }
        
        // If we have explicit ingredients, use those
        if let ingredients = item.ingredients, !ingredients.isEmpty {
            ingredientCache[cacheKey] = ingredients
            return ingredients
        }
        
        // Use AI to analyze if API key is configured
        if openAIAPIKey != "YOUR_OPENAI_API_KEY_HERE" {
            do {
                let ingredients = try await analyzeWithOpenAI(item)
                ingredientCache[cacheKey] = ingredients
                return ingredients
            } catch {
                // Fall back to keyword-based analysis if API fails
                return analyzeWithKeywords(item)
            }
        } else {
            // Fall back to keyword-based analysis if no API key
            return analyzeWithKeywords(item)
        }
    }
    
    /// Analyzes menu item using OpenAI API
    private func analyzeWithOpenAI(_ item: MenuItem) async throws -> [String] {
        guard let url = URL(string: baseURL) else {
            throw URLError(.badURL)
        }
        
        let prompt = """
        Analyze this restaurant menu item and list all common ingredients it typically contains. 
        Be thorough and include all potential allergens (dairy, eggs, nuts, gluten, etc.).
        
        Menu Item: \(item.name)
        Description: \(item.description ?? "No description provided")
        
        Return ONLY a comma-separated list of ingredients, nothing else. Be specific about allergens.
        Example format: flour, eggs, butter, milk, sugar, vanilla extract
        """
        
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                [
                    "role": "system",
                    "content": "You are a food ingredient analyzer. List all common ingredients in menu items, especially allergens."
                ],
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_tokens": 200,
            "temperature": 0.3
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = json?["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw URLError(.badServerResponse)
        }
        
        // Parse the comma-separated ingredients
        let ingredients = content
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        return ingredients
    }
    
    /// Fallback method: Analyzes menu item using keyword matching and common food knowledge
    private func analyzeWithKeywords(_ item: MenuItem) -> [String] {
        var detectedIngredients: Set<String> = []
        
        let itemText = "\(item.name) \(item.description ?? "")".lowercased()
        
        // Common ingredient patterns
        let ingredientPatterns: [String: [String]] = [
            "flour": ["flour", "wheat", "bread", "pasta", "dough", "crust", "batter", "breading"],
            "eggs": ["egg", "eggs", "mayonnaise", "mayo", "aioli", "hollandaise", "benedict"],
            "dairy": ["cheese", "butter", "cream", "milk", "yogurt", "yoghurt", "sour cream", "ricotta", "mozzarella", "parmesan", "cheddar"],
            "nuts": ["almond", "walnut", "pecan", "cashew", "pistachio", "hazelnut", "peanut", "nut"],
            "soy": ["soy", "soya", "tofu", "tempeh", "miso", "edamame", "soybean"],
            "fish": ["salmon", "tuna", "cod", "halibut", "sardine", "anchovy", "fish"],
            "shellfish": ["shrimp", "prawn", "crab", "lobster", "scallop", "oyster", "mussel", "clam"],
            "sesame": ["sesame", "tahini"],
            "gluten": ["flour", "bread", "pasta", "wheat", "barley", "rye", "couscous"]
        ]
        
        // Detect ingredients based on keywords
        for (ingredient, keywords) in ingredientPatterns {
            for keyword in keywords {
                if itemText.contains(keyword) {
                    detectedIngredients.insert(ingredient)
                    break
                }
            }
        }
        
        // Add common base ingredients based on dish type
        if itemText.contains("salad") {
            detectedIngredients.insert("lettuce")
            detectedIngredients.insert("vegetables")
        }
        
        if itemText.contains("pizza") || itemText.contains("pasta") {
            detectedIngredients.insert("flour")
            detectedIngredients.insert("gluten")
        }
        
        if itemText.contains("cake") || itemText.contains("dessert") || itemText.contains("cookie") {
            detectedIngredients.insert("flour")
            detectedIngredients.insert("sugar")
            detectedIngredients.insert("eggs")
        }
        
        if itemText.contains("soup") {
            detectedIngredients.insert("vegetables")
        }
        
        return Array(detectedIngredients).sorted()
    }
    
    /// Batch analyze multiple menu items
    func analyzeMenuItems(_ items: [MenuItem]) async -> [String: [String]] {
        var results: [String: [String]] = [:]
        
        await withTaskGroup(of: (String, [String]).self) { group in
            for item in items {
                group.addTask {
                    do {
                        let ingredients = try await self.analyzeMenuItem(item)
                        return (item.id, ingredients)
                    } catch {
                        // Use fallback analysis
                        let ingredients = self.analyzeWithKeywords(item)
                        return (item.id, ingredients)
                    }
                }
            }
            
            for await (itemId, ingredients) in group {
                results[itemId] = ingredients
            }
        }
        
        return results
    }
    
    /// Clear the ingredient cache
    func clearCache() {
        ingredientCache.removeAll()
    }
}

