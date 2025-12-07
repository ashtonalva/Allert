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
    @State private var menuItems: [MenuItem] = []
    @State private var isLoading = true
    @State private var selectedTab = 0 // 0 = Safe, 1 = Unsafe
    
    private var filteredItems: (safe: [MenuItem], unsafe: [MenuItem]) {
        MenuFilterService.shared.filterMenuItems(menuItems, for: profileManager.profile.allergies)
    }
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading menu...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Tab Selector
                Picker("Filter", selection: $selectedTab) {
                    Text("Safe Items (\(filteredItems.safe.count))").tag(0)
                    Text("Unsafe Items (\(filteredItems.unsafe.count))").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
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
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
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

