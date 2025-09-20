//
//  ProjectsScreen.swift
//  LLM_Organizing_Thoughts
//
//  Created by Aryan Rogye on 9/18/25.
//

import SwiftUI

private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ProjectsScreen: View {
    @State private var hideTabBar = false

    var body: some View {
        ScrollView {
            // Track scroll offset at the very top of the scroll view
            GeometryReader { geo in
                Color.clear
                    .preference(key: ScrollOffsetKey.self, value: geo.frame(in: .named("projectsScroll")).minY)
            }
            .frame(height: 0)

            // Demo content to make the behavior visible
        }
        .onPreferenceChange(ScrollOffsetKey.self) { y in
            // Negative y means we scrolled down
            withAnimation(.snappy) {
                hideTabBar = y < -50
            }
        }
//        // Glassy, modern look for tab bar and navigation bar
//        .toolbar(hideTabBar ? .hidden : .visible, for: .tabBar)
//        .toolbarBackground(.automatic, for: .tabBar)
//        .toolbarBackground(.visible, for: .tabBar)
//        .toolbarBackground(.automatic, for: .navigationBar)
//        .toolbarBackground(.visible, for: .navigationBar)
    }
}

#Preview {
    ProjectsScreen()
}
