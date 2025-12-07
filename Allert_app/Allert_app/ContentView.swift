//
//  ContentView.swift
//  Allert_app
//
//  Created by Ashton Alva on 12/7/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var profileManager: ProfileManager
    
    var body: some View {
        TabView {
            RestaurantSearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
            
            ProfileView(profileManager: profileManager)
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
        }
        .preferredColorScheme(.dark)
        .background(Color.appBackground)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: profileManager.profile.allergies.count)
    }
}

#Preview {
    ContentView()
        .environmentObject(ProfileManager())
}