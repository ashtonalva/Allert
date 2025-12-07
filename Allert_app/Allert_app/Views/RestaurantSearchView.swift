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
    @State private var restaurants: [Restaurant] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showChangeLocation = false
    @State private var tempLocationText = ""
    
    // Suggestion states
    @State private var restaurantSuggestions: [SearchSuggestion] = []
    @State private var locationSuggestions: [SearchSuggestion] = []
    @State private var showRestaurantSuggestions = false
    @State private var showLocationSuggestions = false
    @State private var searchTask: Task<Void, Never>? = nil
    @State private var locationTask: Task<Void, Never>? = nil
    
    // Computed property for current location
    private var currentLocation: String {
        let location = profileManager.profile.location
        return location.isEmpty ? "San Francisco, CA" : location
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    locationHeaderView
                    if showChangeLocation {
                        changeLocationView
                    }
                    searchSectionView
                    errorMessageView
                    resultsView
                }
            }
            .navigationTitle("Find Restaurants")
            .preferredColorScheme(.dark)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: restaurants.count)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isLoading)
        }
        .onDisappear {
            // Cancel any pending tasks when view disappears
            searchTask?.cancel()
            locationTask?.cancel()
        }
    }
    
    // MARK: - View Components
    
    private var locationHeaderView: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(Color.appGreen)
                Text("Searching in: \(currentLocation)")
                    .font(.subheadline)
                    .foregroundColor(Color.appSecondaryText)
            }
            
            Spacer()
            
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showChangeLocation.toggle()
                    if showChangeLocation {
                        tempLocationText = currentLocation
                        // Load suggestions when opening
                        Task {
                            await loadLocationSuggestions(for: currentLocation)
                        }
                    } else {
                        // Cancel any pending location tasks when closing
                        locationTask?.cancel()
                        showLocationSuggestions = false
                        tempLocationText = ""
                    }
                }
            }) {
                Text(showChangeLocation ? "Cancel" : "Change")
                    .font(.caption)
                    .foregroundColor(Color.appGreen)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var changeLocationView: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField("Enter location", text: $tempLocationText)
                .textFieldStyle(.plain)
                .padding()
                .background(Color.appCardBackground)
                .foregroundColor(Color.appPrimaryText)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.appGreen.opacity(0.3), lineWidth: 1)
                )
                .onChange(of: tempLocationText) { newValue in
                    locationTask?.cancel()
                    showLocationSuggestions = true
                    locationTask = Task {
                        try? await Task.sleep(nanoseconds: 200_000_000)
                        if !Task.isCancelled {
                            await loadLocationSuggestions(for: newValue)
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
                                tempLocationText = suggestion.text
                                showLocationSuggestions = false
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
                .padding(.top, 4)
                .shadow(color: .black.opacity(0.3), radius: 8)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
                .zIndex(1000)
            }
            
            HStack {
                Button("Cancel") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showChangeLocation = false
                        tempLocationText = ""
                        showLocationSuggestions = false
                        locationTask?.cancel()
                    }
                }
                .foregroundColor(Color.appSecondaryText)
                
                Spacer()
                
                Button("Save Location") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if !tempLocationText.trimmingCharacters(in: .whitespaces).isEmpty {
                            profileManager.updateLocation(tempLocationText.trimmingCharacters(in: .whitespaces))
                        }
                        showChangeLocation = false
                        tempLocationText = ""
                        showLocationSuggestions = false
                        locationTask?.cancel()
                    }
                }
                .disabled(tempLocationText.trimmingCharacters(in: .whitespaces).isEmpty)
                .foregroundColor(Color.appGreen)
                .fontWeight(.semibold)
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .padding(.bottom, 12)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    private var searchSectionView: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                TextField("Search restaurants...", text: $searchText)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color.appCardBackground)
                    .foregroundColor(Color.appPrimaryText)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(showRestaurantSuggestions ? Color.appGreen : Color.appGreen.opacity(0.3), lineWidth: showRestaurantSuggestions ? 2 : 1)
                    )
                    .onTapGesture {
                        showLocationSuggestions = false
                        if !searchText.isEmpty {
                            showRestaurantSuggestions = true
                            Task {
                                await loadRestaurantSuggestions()
                            }
                        }
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
                    .padding(.top, 4)
                    .shadow(color: .black.opacity(0.3), radius: 8)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showRestaurantSuggestions)
                    .zIndex(1000)
                }
            }
            
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showRestaurantSuggestions = false
                    showLocationSuggestions = false
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
    }
    
    private var errorMessageView: some View {
        Group {
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(Color.appGreen)
                    .padding()
                    .background(Color.appCardBackground)
                    .cornerRadius(8)
                    .padding(.horizontal)
            }
        }
    }
    
    private var resultsView: some View {
        Group {
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
    
    private func searchRestaurants() {
        // Cancel any pending suggestion tasks
        searchTask?.cancel()
        locationTask?.cancel()
        
        isLoading = true
        errorMessage = nil
        showRestaurantSuggestions = false
        showLocationSuggestions = false
        
        Task {
            do {
                let results = try await yelpService.searchRestaurants(query: searchText, location: currentLocation)
                await MainActor.run {
                    // Only update if task wasn't cancelled
                    if !Task.isCancelled {
                        self.restaurants = results
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    // Only update if task wasn't cancelled
                    if !Task.isCancelled {
                        self.errorMessage = "Failed to search restaurants: \(error.localizedDescription)"
                        self.isLoading = false
                    }
                }
            }
        }
    }
    
    private func loadRestaurantSuggestions() async {
        let suggestions = await yelpService.getRestaurantSuggestions(for: searchText, location: currentLocation)
        await MainActor.run {
            self.restaurantSuggestions = suggestions
            // Ensure suggestions are shown if we have results
            if !suggestions.isEmpty {
                self.showRestaurantSuggestions = true
            }
        }
    }
    
    private func loadLocationSuggestions(for query: String? = nil) async {
        let queryText = query ?? tempLocationText
        let suggestions = await yelpService.getLocationSuggestions(for: queryText)
        await MainActor.run {
            self.locationSuggestions = suggestions
            // Ensure suggestions are shown if we have results
            if !suggestions.isEmpty {
                self.showLocationSuggestions = true
            }
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

