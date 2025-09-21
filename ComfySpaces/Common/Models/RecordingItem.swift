//
//  RecordingItem.swift
//  Offline_Organizing_Thoughts
//
//  Created by Aryan Rogye on 9/20/25.
//

import Foundation

public struct RecordingItem: Identifiable, Equatable {
    public var id: URL { url }
    public let url: URL
    public let date: Date
    public let duration: TimeInterval
    public var emoji: String?
    public var name: String?
    
    public init(url: URL, date: Date, duration: TimeInterval, emoji: String? = nil, name: String? = nil) {
        self.url = url
        self.date = date
        self.duration = duration
        self.emoji = emoji
        self.name = name
    }
}

@inlinable
public func formatTime(_ t: TimeInterval) -> String {
    let total = Int(t.rounded())
    let h = total / 3600
    let m = (total % 3600) / 60
    let s = total % 60
    if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
    return String(format: "%02d:%02d", m, s)
}
