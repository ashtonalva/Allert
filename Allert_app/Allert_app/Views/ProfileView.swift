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
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                Form {
                    Section(header: Text("Profile Information")
                        .foregroundColor(Color.appGreen)) {
                        TextField("Your Name", text: Binding(
                            get: { profileManager.profile.name },
                            set: { profileManager.updateName($0) }
                        ))
                        .foregroundColor(Color.appPrimaryText)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Location")
                                .font(.caption)
                                .foregroundColor(Color.appSecondaryText)
                            
                            TextField("City, State", text: Binding(
                                get: { profileManager.profile.location },
                                set: { profileManager.updateLocation($0) }
                            ))
                            .foregroundColor(Color.appPrimaryText)
                        }
                    }
                    .listRowBackground(Color.appCardBackground)
                    
                    Section(header: Text("Allergies")
                        .foregroundColor(Color.appGreen)) {
                        if profileManager.profile.allergies.isEmpty {
                            Text("No allergies added yet")
                                .foregroundColor(Color.appSecondaryText)
                        } else {
                            ForEach(profileManager.profile.allergies) { allergy in
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(Color.appGreen)
                                    Text(allergy.name)
                                        .foregroundColor(Color.appPrimaryText)
                                    Spacer()
                                }
                            }
                            .onDelete(perform: deleteAllergies)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: profileManager.profile.allergies.count)
                        }
                    }
                    .listRowBackground(Color.appCardBackground)
                    
                    Section(header: Text("Quick Add Common Allergies")
                        .foregroundColor(Color.appGreen)) {
                        ForEach(YelpService.commonAllergies, id: \.self) { allergyName in
                            if !profileManager.profile.allergies.contains(where: { $0.name.lowercased() == allergyName.lowercased() }) {
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        let keywords = Allergy.defaultKeywords(for: allergyName)
                                        let allergy = Allergy(name: allergyName, keywords: keywords)
                                        profileManager.addAllergy(allergy)
                                    }
                                }) {
                                    HStack {
                                        Text(allergyName)
                                            .foregroundColor(Color.appPrimaryText)
                                        Spacer()
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(Color.appGreen)
                                            .scaleEffect(1.0)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .listRowBackground(Color.appCardBackground)
                    
                    Section(header: Text("Add Custom Allergy")
                        .foregroundColor(Color.appGreen)) {
                        HStack {
                            TextField("Allergy name", text: $newAllergyName)
                                .foregroundColor(Color.appPrimaryText)
                            Button("Add") {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    if !newAllergyName.isEmpty {
                                        let keywords = Allergy.defaultKeywords(for: newAllergyName)
                                        let allergy = Allergy(name: newAllergyName, keywords: keywords)
                                        profileManager.addAllergy(allergy)
                                        newAllergyName = ""
                                    }
                                }
                            }
                            .disabled(newAllergyName.isEmpty)
                            .foregroundColor(newAllergyName.isEmpty ? Color.appSecondaryText : Color.appGreen)
                            .scaleEffect(newAllergyName.isEmpty ? 1.0 : 1.05)
                            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: newAllergyName.isEmpty)
                        }
                    }
                    .listRowBackground(Color.appCardBackground)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("My Profile")
            .preferredColorScheme(.dark)
        }
    }
    
    private func deleteAllergies(at offsets: IndexSet) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            // Iterate in reverse order to avoid index shifting issues
            for index in offsets.sorted(by: >) {
                profileManager.removeAllergy(profileManager.profile.allergies[index])
            }
        }
    }
}
