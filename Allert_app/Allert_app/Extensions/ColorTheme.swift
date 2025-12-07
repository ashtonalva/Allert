//
//  ColorTheme.swift
//  Allert_app
//
//  Created by Ashton Alva on 12/7/25.
//

import SwiftUI

extension Color {
    // Primary theme colors
    static let appBlack = Color(red: 0.05, green: 0.05, blue: 0.05)
    static let appDarkGray = Color(red: 0.15, green: 0.15, blue: 0.15)
    static let appGreen = Color(red: 0.2, green: 0.8, blue: 0.4)
    static let appLightGreen = Color(red: 0.3, green: 0.9, blue: 0.5)
    static let appWhite = Color.white
    static let appOffWhite = Color(red: 0.95, green: 0.95, blue: 0.95)
    
    // Semantic colors
    static let appBackground = appBlack
    static let appCardBackground = appDarkGray
    static let appPrimaryText = appWhite
    static let appSecondaryText = Color(red: 0.7, green: 0.7, blue: 0.7)
    static let appAccent = appGreen
}

