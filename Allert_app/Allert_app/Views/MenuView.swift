//
//  MenuView.swift
//  Allert_app
//
//  Created by Ashton Alva on 12/7/25.
//

import SwiftUI

struct MenuView: View {
    let restaurant: Restaurant
    @EnvironmentObject var profileManager: ProfileManager
    @StateObject private var yelpService = YelpService()
    @StateObject private var aiService = AIIngredientService.shared
    @State private var menuItems: [MenuItem] = []
    @State private var isLoading = true
    @State private var isAnalyzing = false
    @State private var selectedTab = 0 // 0 = Safe, 1 = Unsafe
    @State private var analysisProgress: Double = 0.0
    
    private var filteredItems: (safe: [MenuItem], unsafe: [MenuItem]) {
        MenuFilterService.shared.filterMenuItems(menuItems, for: profileManager.profile.allergies)
    }
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading menu...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if isAnalyzing {
                VStack(spacing: 16) {
                    ProgressView(value: analysisProgress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle())
                    Text("Analyzing ingredients with AI...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(Int(analysisProgress * 100))% complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Tab Selector
                Picker("Filter", selection: $selectedTab) {
                    Text("Safe Items (\(filteredItems.safe.count))").tag(0)
                    Text("Unsafe Items (\(filteredItems.unsafe.count))").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // AI Analysis Button
                Button(action: {
                    Task {
                        await analyzeMenuItems()
                    }
                }) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Analyze Ingredients with AI")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Menu Items List
                if selectedTab == 0 {
                    if filteredItems.safe.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.green)
                            Text("No safe items found")
                                .foregroundColor(.secondary)
                            Text("All menu items contain allergens from your profile")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List(filteredItems.safe) { item in
                            MenuItemRow(item: item, isSafe: true, allergies: profileManager.profile.allergies)
                        }
                    }
                } else {
                    if filteredItems.unsafe.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.green)
                            Text("All items are safe!")
                                .foregroundColor(.secondary)
                            Text("No menu items contain allergens from your profile")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List(filteredItems.unsafe) { item in
                            MenuItemRow(item: item, isSafe: false, allergies: profileManager.profile.allergies)
                        }
                    }
                }
            }
        }
        .navigationTitle(restaurant.name)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadMenu()
        }
    }
    
    private func loadMenu() async {
        isLoading = true
        do {
            let items = try await yelpService.getMenuItems(for: restaurant)
            await MainActor.run {
                self.menuItems = items
                self.isLoading = false
            }
            // Automatically analyze menu items after loading
            await analyzeMenuItems()
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    private func analyzeMenuItems() async {
        guard !menuItems.isEmpty else { return }
        
        await MainActor.run {
            self.isAnalyzing = true
            self.analysisProgress = 0.0
        }
        
        // Analyze items that don't already have explicit ingredients
        let itemsToAnalyze = menuItems.filter { $0.ingredients == nil || $0.ingredients?.isEmpty == true }
        
        guard !itemsToAnalyze.isEmpty else {
            await MainActor.run {
                self.isAnalyzing = false
            }
            return
        }
        
        let totalItems = Double(itemsToAnalyze.count)
        var analyzedCount = 0.0
        
        // Analyze items in batches to show progress
        for item in itemsToAnalyze {
            do {
                let ingredients = try await aiService.analyzeMenuItem(item)
                
                // Update the menu item with AI-detected ingredients
                if let index = menuItems.firstIndex(where: { $0.id == item.id }) {
                    await MainActor.run {
                        var updatedItem = menuItems[index]
                        updatedItem.aiDetectedIngredients = ingredients
                        menuItems[index] = updatedItem
                    }
                }
                
                analyzedCount += 1
                await MainActor.run {
                    self.analysisProgress = analyzedCount / totalItems
                }
            } catch {
                // Continue with next item if analysis fails
                analyzedCount += 1
                await MainActor.run {
                    self.analysisProgress = analyzedCount / totalItems
                }
            }
        }
        
        await MainActor.run {
            self.isAnalyzing = false
            self.analysisProgress = 1.0
        }
    }
}

struct MenuItemRow: View {
    let item: MenuItem
    let isSafe: Bool
    let allergies: [Allergy]
    
    private var matchingAllergens: [Allergy] {
        MenuFilterService.shared.getMatchingAllergens(for: item, allergies: allergies)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.name)
                    .font(.headline)
                
                Spacer()
                
                if isSafe {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                }
            }
            
            if let description = item.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Show AI-detected ingredients if available
            if let aiIngredients = item.aiDetectedIngredients, !aiIngredients.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.caption2)
                            .foregroundColor(.blue)
                        Text("AI Detected Ingredients:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    Text(aiIngredients.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(6)
            }
            
            if !isSafe && !matchingAllergens.isEmpty {
                HStack {
                    Text("Contains: ")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ForEach(matchingAllergens) { allergen in
                        Text(allergen.name)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(4)
                    }
                }
            }
            
            if let price = item.price {
                Text(price)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

