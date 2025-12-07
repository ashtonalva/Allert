//
//  ProfileManager.swift
//  Allert_app
//
//  Created by Ashton Alva on 12/7/25.
//

import Foundation
import Combine

class ProfileManager: ObservableObject {
    @Published var profile: UserProfile
    
    private let profileKey = "userProfile"
    
    init() {
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.profile = decoded
        } else {
            self.profile = UserProfile()
        }
    }
    
    func saveProfile() {
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: profileKey)
        }
    }
    
    func addAllergy(_ allergy: Allergy) {
        profile.allergies.append(allergy)
        saveProfile()
    }
    
    func removeAllergy(_ allergy: Allergy) {
        profile.allergies.removeAll { $0.id == allergy.id }
        saveProfile()
    }
    
    func updateName(_ name: String) {
        profile.name = name
        saveProfile()
    }
}

