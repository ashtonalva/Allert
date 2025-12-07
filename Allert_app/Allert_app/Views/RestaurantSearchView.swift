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
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Section
                VStack(spacing: 12) {
                    TextField("Search restaurants...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    TextField("Location", text: $locationText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    Button(action: searchRestaurants) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "magnifyingglass")
                            }
                            Text("Search")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .disabled(isLoading || searchText.isEmpty)
                }
                .padding(.vertical)
                
                // Error Message
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
                
                // Results
                if restaurants.isEmpty && !isLoading {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("Search for restaurants to get started")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List(restaurants) { restaurant in
                        NavigationLink(destination: MenuView(restaurant: restaurant)) {
                            RestaurantRow(restaurant: restaurant)
                        }
                    }
                }
            }
            .navigationTitle("Find Restaurants")
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
}

struct RestaurantRow: View {
    let restaurant: Restaurant
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Restaurant Icon
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(restaurant.name)
                    .font(.headline)
                
                if let rating = restaurant.rating {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text(String(format: "%.1f", rating))
                            .font(.caption)
                    }
                }
                
                if let address = restaurant.location?.displayAddress?.first {
                    Text(address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let price = restaurant.price {
                    Text(price)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

