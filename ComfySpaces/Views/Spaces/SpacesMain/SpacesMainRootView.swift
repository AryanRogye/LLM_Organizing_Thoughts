//
//  SpacesView.swift
//  Offline_Organizing_Thoughts
//
//  Created by Aryan Rogye on 9/20/25.
//

import SwiftUI

struct SpacesMainRootView: View {
    
    @Binding var space: Space?
    
    var body: some View {
        if let spaceBinding = Binding($space) {
            SpacesMainView(space: spaceBinding)
        } else {
            VStack {
                Text("No Space Selected")
                Text("Create One!!")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}
