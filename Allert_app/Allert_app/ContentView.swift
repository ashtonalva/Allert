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
    }
}

#Preview {
    ContentView()
}