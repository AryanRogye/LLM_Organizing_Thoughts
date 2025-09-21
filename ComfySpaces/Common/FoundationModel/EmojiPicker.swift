//
//  EmojiPicker.swift
//  Offline_Organizing_Thoughts
//
//  Created by Aryan Rogye on 9/20/25.
//

import FoundationModels

@Generable
struct EmojiResult: Equatable {
    @Guide(.anyOf([
        // Faces - core emotions
        "😀","😅","😂","🤣","🥲","😊","😍","😘","😎","🤓","😇","🥰",
        "😭","😢","😡","🤬","🤯","😱","😨","😴","🥱","🤔","🙃","😏",
        "😤","😳","🤡","💀","👻","👽","🤠","🥺","🤩","🥳","🤪","😵",
        "😵‍💫","🤢","🤮","🤕","🤒","😔","😖","😩","😞","😤","🫠",
        // Hands / gestures
        "👍","👎","👌","✌️","🤟","🤘","👊","👏","🙌","🙏","🫶",
        // Weather / nature
        "🔥","💧","🌊","🌪️","❄️","🌈","☀️","🌙","⭐️","⚡️",
        // Celebration / fun
        "🎉","🎊","🎶","🎵","🎧","🎂","🍕","🍔","🍟","🍎","🍩","🍺","🍷","☕️",
        // Objects / work / daily
        "📱","💻","🧠","🤖","📚","✍️","📝","📖","📊","💡","⏰","🕹️","🎮",
        // Media / camera
        "📷","📸","🎥","🎬",
        // Symbols
        "❤️","🧡","💛","💚","💙","💜","🖤","🤍","💔","❣️","💯",
        "✅","❌","⚠️","🔒","🔓","💎","🪙","💵","📈","📉"
    ]))
    let emoji: String
}

protocol EmojiPickerProviding {
    func pick(from transcript: String) async throws -> String
}

final class EmojiPickerService: EmojiPickerProviding {
    
    private static let session = LanguageModelSession(
        instructions: """
            You are an emoji selector. Return exactly one emoji from the provided schema. 
            Rules:
            - If the transcript mentions recording, audio, mic, music → prefer 🎙️, 🎧, 🎶, 🎵.
            - If it mentions camera, video, filming, photo → prefer 📷, 📸, 🎥, 🎬.
            - If it mentions studying, writing, notes → prefer 📚, 📝, ✍️.
            - Otherwise, return the best overall vibe or emotion (faces, gestures, symbols).
            Output only the emoji, no text.
            """
    )
    
    func pick(from transcript: String) async throws -> String {
        
        do {
            let cleaned = try await Cleaner.shared.clean(transcript)
            
            let res = try await Self.session.respond(
                generating: EmojiResult.self,
                options: .init(sampling: .greedy) // deterministic
            ) {
                Prompt {
                    "Transcript:\n\(cleaned)\n"
                    "Return only one emoji via the `emoji` field."
                }
            }
            return res.content.emoji
        } catch {
            return "🤔"
        }
    }
}
