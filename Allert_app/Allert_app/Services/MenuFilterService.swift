//
//  MenuFilterService.swift
//  Allert_app
//
//  Created by Ashton Alva on 12/7/25.
//

import Foundation

class MenuFilterService {
    static let shared = MenuFilterService()
    
    func filterMenuItems(_ items: [MenuItem], for allergies: [Allergy]) -> (safe: [MenuItem], unsafe: [MenuItem]) {
        var safeItems: [MenuItem] = []
        var unsafeItems: [MenuItem] = []
        
        for item in items {
            if item.isSafe(for: allergies) {
                safeItems.append(item)
            } else {
                unsafeItems.append(item)
            }
        }
        
        return (safe: safeItems, unsafe: unsafeItems)
    }
    
    func getMatchingAllergens(for item: MenuItem, allergies: [Allergy]) -> [Allergy] {
        return allergies.filter { item.containsAllergen($0) }
    }
}

