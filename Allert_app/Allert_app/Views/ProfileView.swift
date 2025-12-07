//
//  ProfileView.swift
//  Allert_app
//
//  Created by Ashton Alva on 12/7/25.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var profileManager: ProfileManager
    @State private var showingAddAllergy = false
    @State private var newAllergyName = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Information")) {
                    TextField("Your Name", text: Binding(
                        get: { profileManager.profile.name },
                        set: { profileManager.updateName($0) }
                    ))
                }
                
                Section(header: Text("Allergies")) {
                    if profileManager.profile.allergies.isEmpty {
                        Text("No allergies added yet")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(profileManager.profile.allergies) { allergy in
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text(allergy.name)
                                Spacer()
                            }
                        }
                        .onDelete(perform: deleteAllergies)
                    }
                }
                
                Section(header: Text("Quick Add Common Allergies")) {
                    ForEach(YelpService.commonAllergies, id: \.self) { allergyName in
                        if !profileManager.profile.allergies.contains(where: { $0.name.lowercased() == allergyName.lowercased() }) {
                            Button(action: {
                                let keywords = Allergy.defaultKeywords(for: allergyName)
                                let allergy = Allergy(name: allergyName, keywords: keywords)
                                profileManager.addAllergy(allergy)
                            }) {
                                HStack {
                                    Text(allergyName)
                                    Spacer()
                                    Image(systemName: "plus.circle")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Add Custom Allergy")) {
                    HStack {
                        TextField("Allergy name", text: $newAllergyName)
                        Button("Add") {
                            if !newAllergyName.isEmpty {
                                let keywords = Allergy.defaultKeywords(for: newAllergyName)
                                let allergy = Allergy(name: newAllergyName, keywords: keywords)
                                profileManager.addAllergy(allergy)
                                newAllergyName = ""
                            }
                        }
                        .disabled(newAllergyName.isEmpty)
                    }
                }
            }
            .navigationTitle("My Profile")
        }
    }
    
    private func deleteAllergies(at offsets: IndexSet) {
        for index in offsets {
            profileManager.removeAllergy(profileManager.profile.allergies[index])
        }
    }
}

