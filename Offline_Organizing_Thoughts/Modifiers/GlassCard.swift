//
//  GlassCard.swift
//  AudioRecorder
//
//  Created by Aryan Rogye on 9/17/25.
//

import SwiftUI

struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        Group {
            if #available(iOS 18.0, *) {
                content
                    .padding(12)
                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
            } else {
                content
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
            }
        }
    }
}
