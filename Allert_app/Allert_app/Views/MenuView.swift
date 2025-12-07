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
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack {
                if isLoading {
                    ProgressView("Loading menu...")
                        .foregroundColor(Color.appGreen)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .transition(.opacity.combined(with: .scale))
                } else if isAnalyzing {
                    VStack(spacing: 16) {
                        ProgressView(value: analysisProgress, total: 1.0)
                            .progressViewStyle(LinearProgressViewStyle(tint: Color.appGreen))
                        Text("Analyzing ingredients with AI...")
                            .font(.subheadline)
                            .foregroundColor(Color.appPrimaryText)
                        Text("\(Int(analysisProgress * 100))% complete")
                            .font(.caption)
                            .foregroundColor(Color.appSecondaryText)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity.combined(with: .scale))
                } else {
                    // Tab Selector
                    Picker("Filter", selection: $selectedTab) {
                        Text("Safe Items (\(filteredItems.safe.count))").tag(0)
                        Text("Unsafe Items (\(filteredItems.unsafe.count))").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
                    
                    // AI Analysis Button
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            Task {
                                await analyzeMenuItems()
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "sparkles")
                                .rotationEffect(.degrees(isAnalyzing ? 360 : 0))
                                .animation(isAnalyzing ? .linear(duration: 2).repeatForever(autoreverses: false) : .default, value: isAnalyzing)
                            Text("Analyze Ingredients with AI")
                        }
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isAnalyzing)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appGreen)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .scaleEffect(isAnalyzing ? 0.98 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isAnalyzing)
                
                    // Menu Items List
                    Group {
                        if selectedTab == 0 {
                            if filteredItems.safe.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(Color.appGreen)
                                    Text("No safe items found")
                                        .foregroundColor(Color.appPrimaryText)
                                    Text("All menu items contain allergens from your profile")
                                        .font(.caption)
                                        .foregroundColor(Color.appSecondaryText)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .transition(.opacity.combined(with: .scale))
                            } else {
                                List(filteredItems.safe) { item in
                                    MenuItemRow(item: item, isSafe: true, allergies: profileManager.profile.allergies)
                                        .listRowBackground(Color.appCardBackground)
                                }
                                .scrollContentBackground(.hidden)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                            }
                        } else {
                            if filteredItems.unsafe.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "checkmark.shield.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(Color.appGreen)
                                    Text("All items are safe!")
                                        .foregroundColor(Color.appPrimaryText)
                                    Text("No menu items contain allergens from your profile")
                                        .font(.caption)
                                        .foregroundColor(Color.appSecondaryText)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .transition(.opacity.combined(with: .scale))
                            } else {
                                List(filteredItems.unsafe) { item in
                                    MenuItemRow(item: item, isSafe: false, allergies: profileManager.profile.allergies)
                                        .listRowBackground(Color.appCardBackground)
                                }
                                .scrollContentBackground(.hidden)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                            }
                        }
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedTab)
                }
            }
        }
        .navigationTitle(restaurant.name)
        .navigationBarTitleDisplayMode(.large)
        .preferredColorScheme(.dark)
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
    @State private var appear = false
    
    private var matchingAllergens: [Allergy] {
        MenuFilterService.shared.getMatchingAllergens(for: item, allergies: allergies)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.name)
                    .font(.headline)
                    .foregroundColor(Color.appPrimaryText)
                
                Spacer()
                
                if isSafe {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.appGreen)
                        .scaleEffect(appear ? 1.0 : 0.5)
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(Color.appGreen.opacity(0.7))
                        .scaleEffect(appear ? 1.0 : 0.5)
                }
            }
            
            if let description = item.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(Color.appSecondaryText)
            }
            
            // Show AI-detected ingredients if available
            if let aiIngredients = item.aiDetectedIngredients, !aiIngredients.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.caption2)
                            .foregroundColor(Color.appGreen)
                            .rotationEffect(.degrees(appear ? 360 : 0))
                        Text("AI Detected Ingredients:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.appGreen)
                    }
                    Text(aiIngredients.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(Color.appSecondaryText)
                        .lineLimit(2)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.appGreen.opacity(0.15))
                .cornerRadius(6)
                .opacity(appear ? 1.0 : 0.0)
                .offset(x: appear ? 0 : -20)
            }
            
            if !isSafe && !matchingAllergens.isEmpty {
                HStack {
                    Text("Contains: ")
                        .font(.caption)
                        .foregroundColor(Color.appSecondaryText)
                    ForEach(Array(matchingAllergens.enumerated()), id: \.element.id) { index, allergen in
                        Text(allergen.name)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.appGreen.opacity(0.2))
                            .foregroundColor(Color.appGreen)
                            .cornerRadius(4)
                            .opacity(appear ? 1.0 : 0.0)
                            .offset(x: appear ? 0 : 20)
                    }
                }
            }
            
            if let price = item.price {
                Text(price)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.appGreen)
                    .opacity(appear ? 1.0 : 0.0)
            }
        }
        .padding(.vertical, 4)
        .opacity(appear ? 1.0 : 0.0)
        .offset(y: appear ? 0 : 10)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                appear = true
            }
        }
    }
}

