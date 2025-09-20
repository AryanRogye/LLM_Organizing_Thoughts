# Repository Guidelines

## Project Structure & Modules
- App code: `Offline_Organizing_Thoughts/` (SwiftUI). Key areas:
  - `Common/` (`App/`, `Auth/`, `Models/`) for shared state, auth, and data types.
  - `Views/` (`Projects/`, `Library/`, `Settings/`) for UI screens, plus `RootView.swift`.
  - `Assets.xcassets/` for images and colors.
- Tests: `Offline_Organizing_ThoughtsTests/` (unit) and `Offline_Organizing_ThoughtsUITests/` (UI).
- Xcode project: `Offline_Organizing_Thoughts.xcodeproj`.

## Build, Test, and Run
- Xcode: Open the project and use Product > Run/Test.
- CLI build:
  ```bash
  xcodebuild -project Offline_Organizing_Thoughts.xcodeproj \
    -scheme Offline_Organizing_Thoughts -configuration Debug build
  ```
- CLI tests (pick your simulator):
  ```bash
  xcodebuild -project Offline_Organizing_Thoughts.xcodeproj \
    -scheme Offline_Organizing_Thoughts \
    -destination 'platform=iOS Simulator,name=iPhone 15' test
  ```

## Coding Style & Naming
- Language: Swift 5+/SwiftUI.
- Indentation: 4 spaces; keep lines concise (<120 cols).
- Types/Protocols/Enums: UpperCamelCase (e.g., `AuthState`, `Tabs`).
- Cases/vars/functions: lowerCamelCase (e.g., `shouldShowAuth`, `authenticate()`).
- Files: One primary type per file, named after the type (e.g., `LibraryView.swift`).
- Follow Swift API Design Guidelines; prefer composable views and `@StateObject`/`@EnvironmentObject` for state.

## Testing Guidelines
- Unit tests: Swift Testing in `Offline_Organizing_ThoughtsTests`.
  - Use `@Test` and `#expect(...)` assertions.
- UI tests: XCTest in `Offline_Organizing_ThoughtsUITests`.
  - Prefer stable identifiers and avoid timing flakiness; use `XCTExpectations` if needed.
- Naming: Mirror the type under test (e.g., `AuthStateTests`); group by feature.
- Coverage: Aim for critical paths (auth flow, tab routing, defaults persistence).

## Commit & PR Guidelines
- Commits: Imperative mood, concise subject (≤72 chars), optional scope.
  - Examples: `feat(auth): add Face ID gate`, `fix(ui): stabilize tab visibility on scroll`.
- PRs: Clear description, linked issues, screenshots for UI, test plan, and risk/rollback notes.
- Keep diffs focused; include migration notes if touching `UserDefaults` keys (`AuthState.Keys`).

## Security & Configuration Tips
- Auth: Uses LocalAuthentication; handle fallback gracefully and test without biometrics.
- Secrets: Do not commit credentials. Use system Keychain when needed.
- Defaults: Register via `AuthState.registerDefaults(...)`; avoid hard‑coding magic strings outside `Keys`.

