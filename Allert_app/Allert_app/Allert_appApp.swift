//
//  Allert_appApp.swift
//  Allert_app
//
//  Created by Ashton Alva on 12/7/25.
//

import SwiftUI

@main
struct Allert_appApp: App {
    @StateObject private var profileManager = ProfileManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(profileManager)
        }
    }
}
