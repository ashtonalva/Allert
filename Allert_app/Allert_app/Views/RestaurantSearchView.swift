//
//  RestaurantSearchView.swift
//  Allert_app
//
//  Created by Ashton Alva on 12/7/25.
//

import SwiftUI

struct RestaurantSearchView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @StateObject private var yelpService = YelpService()
    @State private var searchText = ""
    @State private var locationText = "San Francisco, CA"
    @State private var restaurants: [Restaurant] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // Suggestion states
    @State private var restaurantSuggestions: [SearchSuggestion] = []
    @State private var locationSuggestions: [SearchSuggestion] = []
    @State private var showRestaurantSuggestions = false
    @State private var showLocationSuggestions = false
    @State private var focusedField: FieldType? = nil
    @State private var searchTask: Task<Void, Never>? = nil
    @State private var locationTask: Task<Void, Never>? = nil
    
    enum FieldType {
        case restaurant
        case location
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Section
                    VStack(spacing: 12) {
                        ZStack(alignment: .topLeading) {
                            TextField("Search restaurants...", text: $searchText)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color.appCardBackground)
                                .foregroundColor(Color.appPrimaryText)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(focusedField == .restaurant ? Color.appGreen : Color.appGreen.opacity(0.3), lineWidth: focusedField == .restaurant ? 2 : 1)
                                )
                                .onTapGesture {
                                    focusedField = .restaurant
                                    showLocationSuggestions = false
                                }
                                .onChange(of: searchText) { newValue in
                                    // Cancel previous task
                                    searchTask?.cancel()
                                    
                                    if !newValue.isEmpty {
                                        showRestaurantSuggestions = true
                                        // Debounce: wait 300ms before loading suggestions
                                        searchTask = Task {
                                            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
                                            if !Task.isCancelled {
                                                await loadRestaurantSuggestions()
                                            }
                                        }
                                    } else {
                                        showRestaurantSuggestions = false
                                        restaurantSuggestions = []
                                    }
                                }
                                .padding(.horizontal)
                            
                            // Restaurant Suggestions
                            if showRestaurantSuggestions && !restaurantSuggestions.isEmpty {
                                VStack(spacing: 0) {
                                    ForEach(Array(restaurantSuggestions.enumerated()), id: \.element.id) { index, suggestion in
                                        Button(action: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                searchText = suggestion.text
                                                showRestaurantSuggestions = false
                                                focusedField = nil
                                            }
                                        }) {
                                            HStack {
                                                Image(systemName: "magnifyingglass")
                                                    .foregroundColor(Color.appGreen)
                                                    .font(.caption)
                                                Text(suggestion.text)
                                                    .foregroundColor(Color.appPrimaryText)
                                                Spacer()
                                            }
                                            .padding()
                                            .background(Color.appCardBackground)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .scaleEffect(1.0)
                                        .onTapGesture {
                                            withAnimation(.spring(response: 0.2)) {
                                                // Button press animation handled in action
                                            }
                                        }
                                        
                                        if suggestion.id != restaurantSuggestions.last?.id {
                                            Divider()
                                                .background(Color.appDarkGray)
                                        }
                                    }
                                }
                                .background(Color.appCardBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.appGreen.opacity(0.3), lineWidth: 1)
                                )
                                .padding(.horizontal)
                                .padding(.top, 50)
                                .shadow(color: .black.opacity(0.3), radius: 8)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .move(edge: .top).combined(with: .opacity)
                                ))
                                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showRestaurantSuggestions)
                            }
                        }
                        
                        ZStack(alignment: .topLeading) {
                            TextField("Location", text: $locationText)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color.appCardBackground)
                                .foregroundColor(Color.appPrimaryText)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(focusedField == .location ? Color.appGreen : Color.appGreen.opacity(0.3), lineWidth: focusedField == .location ? 2 : 1)
                                )
                                .onTapGesture {
                                    focusedField = .location
                                    showRestaurantSuggestions = false
                                    showLocationSuggestions = true
                                    if locationSuggestions.isEmpty {
                                        Task {
                                            await loadLocationSuggestions()
                                        }
                                    }
                                }
                                .onChange(of: locationText) { newValue in
                                    // Cancel previous task
                                    locationTask?.cancel()
                                    
                                    // Always show suggestions for location
                                    showLocationSuggestions = true
                                    // Debounce: wait 200ms before loading suggestions
                                    locationTask = Task {
                                        try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
                                        if !Task.isCancelled {
                                            await loadLocationSuggestions()
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            
                            // Location Suggestions
                            if showLocationSuggestions && !locationSuggestions.isEmpty {
                                VStack(spacing: 0) {
                                    ForEach(Array(locationSuggestions.enumerated()), id: \.element.id) { index, suggestion in
                                        Button(action: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                locationText = suggestion.text
                                                showLocationSuggestions = false
                                                focusedField = nil
                                            }
                                        }) {
                                            HStack {
                                                Image(systemName: "mappin.circle.fill")
                                                    .foregroundColor(Color.appGreen)
                                                    .font(.caption)
                                                Text(suggestion.text)
                                                    .foregroundColor(Color.appPrimaryText)
                                                Spacer()
                                            }
                                            .padding()
                                            .background(Color.appCardBackground)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        
                                        if suggestion.id != locationSuggestions.last?.id {
                                            Divider()
                                                .background(Color.appDarkGray)
                                        }
                                    }
                                }
                                .background(Color.appCardBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.appGreen.opacity(0.3), lineWidth: 1)
                                )
                                .padding(.horizontal)
                                .padding(.top, 50)
                                .shadow(color: .black.opacity(0.3), radius: 8)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .move(edge: .top).combined(with: .opacity)
                                ))
                                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showLocationSuggestions)
                            }
                        }
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showRestaurantSuggestions = false
                                showLocationSuggestions = false
                                focusedField = nil
                            }
                            searchRestaurants()
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "magnifyingglass")
                                }
                                Text("Search")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isLoading || searchText.isEmpty ? Color.appDarkGray : Color.appGreen)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .disabled(isLoading || searchText.isEmpty)
                        .scaleEffect(isLoading ? 0.98 : 1.0)
                        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isLoading)
                    }
                    .padding(.vertical)
                    .onTapGesture {
                        // Hide suggestions when tapping outside
                        if focusedField != nil {
                            showRestaurantSuggestions = false
                            showLocationSuggestions = false
                            focusedField = nil
                        }
                    }
                    
                    // Error Message
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(Color.appGreen)
                            .padding()
                            .background(Color.appCardBackground)
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                    
                // Results
                if restaurants.isEmpty && !isLoading {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 50))
                            .foregroundColor(Color.appGreen)
                        Text("Search for restaurants to get started")
                            .foregroundColor(Color.appSecondaryText)
                    }
                    Spacer()
                    .transition(.opacity)
                } else if !restaurants.isEmpty {
                    List(restaurants) { restaurant in
                        NavigationLink(destination: MenuView(restaurant: restaurant)) {
                            RestaurantRow(restaurant: restaurant)
                        }
                        .listRowBackground(Color.appCardBackground)
                    }
                    .scrollContentBackground(.hidden)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
                }
                }
            }
            .navigationTitle("Find Restaurants")
            .preferredColorScheme(.dark)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: restaurants.count)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isLoading)
        }
        .onAppear {
            // Load mock data on appear for demo
            loadMockData()
        }
    }
    
    private func searchRestaurants() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let results = try await yelpService.searchRestaurants(query: searchText, location: locationText)
                await MainActor.run {
                    self.restaurants = results
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to search restaurants: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func loadMockData() {
        // Load mock data for demonstration
        restaurants = yelpService.mockRestaurants()
    }
    
    private func loadRestaurantSuggestions() async {
        let suggestions = await yelpService.getRestaurantSuggestions(for: searchText, location: locationText)
        await MainActor.run {
            self.restaurantSuggestions = suggestions
        }
    }
    
    private func loadLocationSuggestions() async {
        let suggestions = await yelpService.getLocationSuggestions(for: locationText)
        await MainActor.run {
            self.locationSuggestions = suggestions
        }
    }
}

struct RestaurantRow: View {
    let restaurant: Restaurant
    @State private var isPressed = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Restaurant Icon
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(Color.appGreen)
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(restaurant.name)
                    .font(.headline)
                    .foregroundColor(Color.appPrimaryText)
                
                if let rating = restaurant.rating {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(Color.appGreen)
                            .font(.caption)
                        Text(String(format: "%.1f", rating))
                            .font(.caption)
                            .foregroundColor(Color.appPrimaryText)
                    }
                }
                
                if let address = restaurant.location?.displayAddress?.first {
                    Text(address)
                        .font(.caption)
                        .foregroundColor(Color.appSecondaryText)
                }
                
                if let price = restaurant.price {
                    Text(price)
                        .font(.caption)
                        .foregroundColor(Color.appSecondaryText)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

