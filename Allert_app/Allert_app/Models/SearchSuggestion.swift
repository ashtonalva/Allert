//
//  SearchSuggestion.swift
//  Allert_app
//
//  Created by Ashton Alva on 12/7/25.
//

import Foundation

struct SearchSuggestion: Identifiable, Hashable {
    let id: String
    let text: String
    let type: SuggestionType
    
    enum SuggestionType {
        case restaurant
        case location
    }
}

