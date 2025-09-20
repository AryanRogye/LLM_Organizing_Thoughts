//
//  RecordingScreen.swift
//  AudioRecorder
//
//
//  This is the Recording Screen
//  "Thing User Sees once u click record"
//
//  Created by Aryan Rogye on 9/17/25.
//


import SwiftUI

// MARK: - Recording Screen (refactored into smaller parts)
struct RecordingScreen: View {
    let level: Float
    let elapsed: TimeInterval
    let stopAction: () -> Void
    
    var body: some View {
        Group {
            if #available(iOS 18.0, *) {
                GlassEffectContainer(spacing: 24) {
                    VStack(spacing: 24) {
                        RecordingTitleView(elapsed: elapsed)
                        LevelMeter(level: level)
                        StopRecordButton(stopAction: stopAction)
                    }
                    .padding(24)
                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.clear)
            } else {
                VStack(spacing: 24) {
                    RecordingTitleView(elapsed: elapsed)
                    LevelMeter(level: level)
                    StopRecordButton(stopAction: stopAction)
                }
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ultraThinMaterial)
            }
        }
        .animation(.easeOut(duration: 0.15), value: level)
    }
}

// MARK: - Recording Title
struct RecordingTitleView: View {
    let elapsed: TimeInterval
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Recording")
                .font(.largeTitle).bold()
            Text(formatTime(elapsed))
                .font(.system(size: 48, weight: .medium, design: .rounded))
                .monospacedDigit()
                .accessibilityLabel("Elapsed time")
        }
    }
}


// MARK: - Not Sure Yet
struct LevelMeter: View {
    let level: Float
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<20, id: \.self) { i in
                let h = CGFloat(level) * CGFloat((i % 5) + 1) * 12
                RoundedRectangle(cornerRadius: 3)
                    .fill(LinearGradient(colors: [.red, .orange], startPoint: .bottom, endPoint: .top))
                    .frame(width: 6, height: max(6, h))
                    .accessibilityHidden(true)
            }
        }
        .frame(height: 100)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .modifier(GlassCard())
    }
}

// MARK: - Stop Record Button
struct StopRecordButton: View {
    let stopAction: () -> Void
    
    var body: some View {
        Button(action: stopAction) {
            Image(systemName: "stop.fill")
                .font(.system(size: 28))
                .foregroundStyle(.white)
                .frame(width: 80, height: 80)
                .background(Circle().fill(.red))
                .shadow(color: .red.opacity(0.25), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Stop Recording")
    }
}
