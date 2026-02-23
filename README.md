# Praytime

`Praytime` is a native macOS menu bar app for viewing upcoming daily prayer times and receiving reminders.

It is built with SwiftUI and designed to stay lightweight: open the menu bar extra, glance at the next prayer, and optionally get a notification before it starts.

## Features

- Menu bar app with a compact prayer timeline
- Highlights the next upcoming prayer
- Uses local macOS location (with permission) for accurate prayer calculations
- Local notifications for upcoming prayer reminders
- Adjustable notification lead time
- Privacy-friendly behavior: location is cached locally and reused until you manually refresh it

## Current Status

This project is in active development. The current app includes:

- Menu bar popover UI
- Settings window (General / Notifications / Location)
- Prayer time calculation via [`adhan-swift`](https://github.com/batoulapps/adhan-swift)
- Basic notification scheduling for the next prayer

Planned next steps include more robust scheduling, tests, and localization.

## Screenshots

Screenshots will be added as the UI stabilizes.

## Tech Stack

- Swift 5
- SwiftUI (macOS)
- CoreLocation
- UserNotifications
- Xcode project (no workspace-level app code generation)

## Getting Started

### Requirements

- macOS 15+
- Xcode 16.2+
- Apple Developer account (for signing when running on your machine)

### Run in Xcode

1. Open `praytime.xcodeproj` in Xcode.
2. Select the `praytime` scheme.
3. Set your own signing team in **Signing & Capabilities**.
4. Use your own bundle identifier if needed.
5. Run on **My Mac**.

### Build from Terminal

```sh
xcodebuild build \
  -project praytime.xcodeproj \
  -scheme praytime \
  -configuration Debug \
  -destination 'platform=macOS,arch=arm64'
```

## Privacy Notes

- Location is used locally to calculate prayer times.
- Location is stored locally on the Mac for reuse on future launches.
- No prayer schedule or location data is sent to a backend service in the current version.

## Development Notes

- The repository intentionally excludes local Xcode user data and local agent instruction files.
- Signing settings in the project are sanitized for public sharing. Configure your own team and bundle identifier locally.

## Roadmap

- Add XCTest coverage for schedule calculations
- Improve notification behavior (multiple reminders, quiet hours)
- Add settings for calculation method and madhab
- Add localization and string catalogs
- Polish menu bar icon/title behavior

## License

License not specified yet.

