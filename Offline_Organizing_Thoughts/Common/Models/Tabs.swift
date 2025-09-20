//
//  Tabs.swift
//  Offline_Organizing_Thoughts
//
//  Created by Aryan Rogye on 9/18/25.
//

import SwiftUI

enum Tabs: String, CaseIterable, Hashable {
    case home = "Home"
    case library = "Library"
//    case settings = "Settings"
    
    var icon: String {
        switch self {
        case .home:
            return "house.fill"
        case .library:
            return "books.vertical.fill"
//        case .settings:
//            return "gearshape.fill"
        }
    }
    
    @ViewBuilder
    var view: some View {
        switch self {
        case .home:
            ProjectsScreen()
        case .library:
            LibraryView()
//        case .settings:
//            SettingsScreen()
        }
    }
}
