# AGENTS GUIDE FOR PRAYTIME
This document equips agentic developers with the commands and conventions needed to evolve the praytime macOS menubar app safely.
Use it as the canonical reference for quick execution, stylistic alignment, and debugging expectations.
## 1. Repository Snapshot
- Target app: `praytime` SwiftUI macOS menubar utility defined by `praytime.xcodeproj`.
- Source root: `praytime/` currently contains `praytimeApp.swift`, `PrayerTimesStore.swift`, `PrayerMenuView.swift`, `SettingsView.swift`, entitlements, and assets.
- Product type: `com.apple.product-type.application` built for macOS 15+ with hardened runtime and sandboxing enabled.
- Uses a Swift Package dependency for prayer time calculation (`Adhan`).
- No server components—treat this repository as a single Xcode project with local-only state for now.
- App goal: surface upcoming salah times with at-a-glance menu bar popover, notifications, and lightweight settings.
- Keep commit history linear and easy to scan; avoid unrelated refactors mixed with feature commits.
## 2. Toolchain Requirements
- macOS 15 Sequoia or newer; development verified on Apple Silicon.
- Xcode 16.2+ (project `CreatedOnToolsVersion 26.2`) with command line tools installed (`xcode-select --install`).
- Swift 5.10 toolchain bundled in Xcode; do not override unless testing compatibility.
- `xcodebuild`, `xcrun simctl`, and `plutil` for automations; install `xcbeautify` if you want prettier CI logs.
- Optional but encouraged: `swift-format` 509+ and `swiftlint` 0.55+ for local lint passes.
- Ensure an Apple Developer Team ID with access to `V3HN8HXZYK` or configure personal team when running locally.
## 3. Local Setup Checklist
1. Clone repo, run `xed .` once so Xcode registers the scheme.
2. Confirm automatic signing is enabled in the project (Signing & Capabilities tab) and bundle id `com.stringsaeed.praytime` matches your team.
3. Trust developer tools if prompted by macOS security dialogs.
4. Create a dedicated build folder (`mkdir -p build`) for archives and derived artifacts when scripting.
5. Menu bar UI is implemented with `MenuBarExtra`; keep the icon/title behavior aligned with macOS conventions when iterating.
6. Current entitlements include `com.apple.developer.aps-environment = development`; document every entitlement or permission change in this file immediately.
## 4. Build, Run, and Archive Commands
- **Debug build (default destination)**:
  ```sh
  xcodebuild build     -project praytime.xcodeproj     -scheme praytime     -configuration Debug     -destination 'platform=macOS,arch=arm64'
  ```
- **Release archive (for distribution + notarization)**:
  ```sh
  xcodebuild archive     -project praytime.xcodeproj     -scheme praytime     -configuration Release     -archivePath build/praytime.xcarchive
  ```
- **Clean derived data**: `xcodebuild clean -project praytime.xcodeproj -scheme praytime` (append `-destination ...` if needed).
- **Run via CLI**: `xed -project praytime.xcodeproj` opens Xcode; press `Cmd+R` targeting "My Mac".
- **Kill stale menu bar instances**: `pkill -f praytime` prior to a rebuild to avoid duplicate status items.
- **CI tip**: `set -o pipefail && xcodebuild ... | xcbeautify --quiet` keeps logs readable without hiding failures.
## 5. Testing Strategy and Commands
- XCTest targets have not been created yet; add `praytimeTests` before implementing business logic.
- Full-suite template (once tests exist):
  ```sh
  xcodebuild test     -project praytime.xcodeproj     -scheme praytime     -destination 'platform=macOS,arch=arm64'
  ```
- Single-test template:
  ```sh
  xcodebuild test     -project praytime.xcodeproj     -scheme praytime     -destination 'platform=macOS,arch=arm64'     -only-testing:praytimeTests/PrayerScheduleServiceTests/testNextPrayerComputation
  ```
- Prefer fast, deterministic tests—no live network, CoreLocation, or async sleeps; inject clocks and schedule providers.
- Use SwiftUI preview tests (Xcode Previews or `PreviewTesting` when added) for layout regressions.
- When UI snapshot testing becomes necessary, store reference images under `Tests/__Snapshots__` and keep them small.
## 6. Linting, Formatting, and Static Analysis
- Treat compiler warnings as errors; never skip them with `-allowProvisioningUpdates` unless codesigning demands it.
- Canonical formatter: `swift-format` (invoke `swift-format format --in-place --recursive praytime`).
- Align with Xcode default indentation (4 spaces, spaces only) and keep columns under 110.
- SwiftLint is optional until `.swiftlint.yml` lands; when it does, run `swiftlint --strict` before sending PRs.
- Run `xcodebuild analyze` occasionally to leverage the Clang static analyzer on Swift/Obj-C boundaries.
- Interface Builder and storyboards are out of scope; entire UI should remain SwiftUI for consistency.
## 7. Imports and Modules
1. Group imports: standard library/Foundation first, Apple frameworks next, third-party modules last.
2. Keep each group alphabetized to minimize merge conflicts.
3. Avoid `@testable import` outside dedicated test targets.
4. Prefer explicit symbol imports (`import class Combine.PassthroughSubject`) only when build times benefit.
5. Document any dependency additions (Swift Package Manager, Cocoapods) in this file plus `README` once created.
## 8. File and Type Organization
- One major type per file; preview providers or small extensions may live alongside their parent type.
- Prefer small files and small views first; extract subviews/helpers early to keep SwiftUI bodies readable and focused.
- Break large SwiftUI views into smaller views (`PrayerRow`, `TimelineHeader`, `SettingsButton`) and target bodies under 100 lines.
- Keep cross-cutting helpers inside `Extensions/` with clear naming (e.g., `Date+PrayerTimes.swift`).
- Store persistent resources in `Resources/` or `Assets.xcassets`; reference using `Image("AppIcon")` instead of file paths.
- When adding data models, create a `Models/` group so logic scales cleanly.
- Avoid introducing heavyweight UI containers or settings screens unless the feature clearly requires them; ship the smallest usable surface.
## 9. Naming Conventions
- Types: UpperCamelCase (`PrayerEvent`, `PrayerTimelineViewModel`).
- Functions and vars: lowerCamelCase (`nextPrayer`, `loadSchedule()`).
- Async functions should read like commands (`refreshSchedule() async`).
- Protocols describe capabilities (`PrayerScheduleProviding`), not implementations.
- Use suffixes intentionally (`...View`, `...Service`, `...Store`, `...Coordinator`).
- Avoid abbreviations except common ones (UTC, API, ID, UI).
## 10. Formatting Rules
1. Use trailing commas in multi-line literals to reduce diff churn.
2. Keep one blank line between stored properties and methods.
3. Place computed properties before methods inside a type for predictability.
4. Prefer `guard` for early exits; avoid nested `if` pyramids.
5. Annotate protocol conformances with `// MARK: - ProtocolName` blocks.
6. Document complicated logic with short inline comments; do not restate code.
## 11. Types, Generics, and Protocols
- Favor `struct` for value types; use `final class` for reference semantics like observable stores.
- Use generics when extracting reusable schedule calculators, but avoid over-engineering before requirements appear.
- Provide protocol-backed abstractions for time providers, permissions managers, and notification centers.
- Inject dependencies via initializers, enabling preview/test overrides.
- Consider `@Observable` (Swift 5.9+) for view models to simplify state publishing.
- Avoid global singletons beyond `UserDefaults.standard` accessed through typed wrappers.
## 12. Error Handling and Logging
- Model recoverable issues using `enum PrayerError: Error` with cases such as `.locationDenied`, `.networkUnavailable`, `.calculationFailed`.
- Throw errors rather than returning `nil`; unwrap optionals with descriptive `guard` failure messages.
- Present errors through a single surface (popover banner or toast) to keep UX consistent.
- Logging: use `os.Logger(subsystem: "com.stringsaeed.praytime", category: "schedule")` for structured logs.
- Never print secrets or tokens; while none exist today, plan for prayer API credentials if added later.
## 13. Concurrency and Scheduling Guidelines
- Limit `Task.detached` usage; prefer `Task {}` tied to SwiftUI lifecycle modifiers.
- Cancel long-running tasks using `.task(id:)` or explicit `Task` handles when dependency inputs change.
- Use `TimelineSchedule` / `Timer.publish` for minute-level refreshes rather than manual loops.
- Always hop back to the main actor before mutating UI state.
- Provide deterministic clocks in tests by injecting `Clock` conformances when future Swift versions allow.
## 14. UI and UX Guardrails
- Menu bar icon should remain monochrome SF Symbol (e.g., `sun.and.horizon.fill`) to respect system tint.
- Popover width <= 360pt; rely on `GeometryReader` sparingly to keep layout predictable.
- Default to compact UI and concise copy; menu bar surfaces should prioritize scan speed over feature density.
- Typography guidelines: `.title3` for the next prayer, `.body` for times, `.caption2` for meta info.
- Provide dark/light aware colors via asset catalog pairs; avoid hard-coded hex values in code.
- Animations must be purposeful (e.g., fade upcoming prayer highlight) and respect reduced motion settings.
- Accessibility: support Dynamic Type scaling and VoiceOver labels on every interactive control.
## 15. Date, Time, and Localization Rules
- Store all instants in UTC using `Date`; compute localizable strings with `DateFormatter` configured per locale.
- Always respect the user’s calendar/locale; do not assume Gregorian when formatting.
- Cache astronomical calculations to avoid recomputation every frame.
- Add localized strings via string catalogs once copy stabilizes; avoid raw-text user-facing strings.
## 16. State Management Guidance
- Top-level app entry uses `@StateObject` or `@Observable` view models for prayer schedule, settings, and notifications.
- Child views should receive dependencies via `@Environment` or initializer injection, not re-create services.
- Use `@AppStorage` for lightweight toggles (24-hour clock, madhab setting) with sensible defaults.
- Avoid storing heavy objects in `@State`; prefer dedicated model objects.
- For previews, inject deterministic mock stores via `.environment(PrayerScheduleStore.mock)`.
## 17. Testing Expectations
- Every pure function (e.g., `nextPrayer(after:)`) should gain unit tests as soon as implemented.
- Snapshot/UI tests should stub static times to avoid failures around DST or timezone transitions.
- Use dependency inversion rather than `#if DEBUG` when swapping real vs. mock services.
- Keep test data under `Tests/Fixtures/`; document new fixtures in their README once directory exists.
- Record flaky tests immediately in AGENTS.md and skip only as a last resort with references to GitHub issues.
## 18. Git Workflow
- Feature branches: `feature/<short-description>`; bug fixes: `fix/<ticket>`; experiments: `spike/<topic>`.
- Write descriptive commit messages (imperative mood) summarizing intent, not implementation detail.
- Never rewrite history on shared branches; rebase locally if needed before pushing.
- Do not commit secrets, provisioning profiles, or `.xcuserdata` directories.
- Run `git status` before invoking automated commands to avoid stomping user changes.
- After every task, review `AGENTS.md` and update it if app structure, tooling, workflow, permissions, or conventions changed.
- When `AGENTS.md` is updated for a task, include it in the same commit as the code/UI changes.
## 19. Operational Notes
- Codesigning errors usually stem from mismatched bundle identifiers; double-check Signing settings per configuration.
- If previews crash, clean Derived Data (`rm -rf ~/Library/Developer/Xcode/DerivedData/praytime-*`).
- Menubar apps can keep multiple windows alive; ensure `NSApplication.shared.setActivationPolicy(.accessory)` once UI evolves.
- Keep memory footprint tiny—offload heavy calculations to background tasks and cache results smartly.
- Document new background modes or permissions immediately in this file.
## 20. Security and Privacy
- Request the minimum required permissions (location, notifications) and explain why in `Info.plist` usage descriptions.
- Respect user data: store preferences locally, avoid transmitting prayer schedules unless a remote API is explicitly enabled.
- Sanitize any user input prior to persistence; though scope is small now, keep patterns future-proof.
- Review entitlements before shipping to ensure sandbox stays tight.
## 21. Cursor/Copilot Guidance
- No `.cursor/rules` or Copilot instruction files exist in this repo at present.
- If such files are added later, mirror their guidance here and ensure automations enforce them.
## 22. Future Enhancements Checklist
- [ ] Add `praytimeTests` target with schedule calculation coverage.
- [ ] Introduce `PrayerScheduleService` and dependency injection wiring.
- [ ] Build menu bar status item + popover UI with timeline view.
- [ ] Implement notification scheduling respecting quiet hours.
- [ ] Add CI workflow (GitHub Actions) running build + lint + tests on push.
- [ ] Expand this doc whenever tooling or conventions change.

## 23. Current App Structure (2026-02-23)
- `praytime/praytimeApp.swift`: app entry point, `MenuBarExtra`, and `Settings` scene wiring with shared `PrayerTimesStore`.
- `praytime/PrayerTimesStore.swift`: main app state and logic (`ObservableObject`) for prayer schedule calculation, location refresh, notification authorization/scheduling, cached coordinates, and lead-time preferences.
- `praytime/PrayerMenuView.swift`: compact menu bar popover UI showing next prayer, prayer list, status messages, refresh action, and `SettingsLink`.
- `praytime/SettingsView.swift`: tabbed settings window (General, Notifications, Location) with lead-time controls and links to macOS system settings.
- `praytime/praytime.entitlements`: currently includes APNs development entitlement; keep this file minimal and documented.
- `praytime/Assets.xcassets`: app icon + color assets; continue using asset-catalog managed colors/images only.

## 24. Required macOS Skills (Agent Workflow)
- For every task in this repository, apply the macOS-focused skills already installed before making UI/UX or structure decisions.
- Required skills for this repo: `macos-app-design` and `macos-design-guidelines`.
- Treat these skills as default constraints for menu bar behavior, settings windows, keyboard shortcuts, accessibility, and macOS-native patterns.
- If a task intentionally deviates from these skills, document the reason in the task response and update this file if the deviation becomes a project convention.
