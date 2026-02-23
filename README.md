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

## Releases

GitHub Actions is configured to create a GitHub Release automatically when you push a version tag:

```sh
git tag v1.0.0
git push origin v1.0.0
```

The workflow builds a Release archive on macOS, packages the app as `.zip` and `.dmg`, and uploads those files to the GitHub Release for that tag.

Notes:

- The CI release workflow now delegates the build/sign/notarize/package steps to Fastlane.
- The Fastlane lane uses your Xcode project settings for signing identity/team and bundle identifier (no CI override for bundle id).
- You must add the required GitHub Actions secrets before creating a release tag.

### Fastlane (local or CI)

Install dependencies and run the same release lane locally:

```sh
bundle install
bundle exec fastlane mac github_release
```

You can pass `RELEASE_VERSION=1.0.0` locally if you are not running from a Git tag context.

### Required GitHub Secrets (for signed + notarized releases)

Add these repository secrets in **GitHub → Settings → Secrets and variables → Actions**:

- `APPLE_TEAM_ID`: your Apple Developer Team ID
- `APPLE_ID`: Apple ID email used for notarization
- `APPLE_APP_SPECIFIC_PASSWORD`: app-specific password for that Apple ID
- `DEVELOPER_ID_P12_BASE64`: base64-encoded `.p12` for your **Developer ID Application** certificate
- `DEVELOPER_ID_P12_PASSWORD`: password used when exporting the `.p12`
- `KEYCHAIN_PASSWORD`: any strong temporary password used by CI for the ephemeral keychain

To create `DEVELOPER_ID_P12_BASE64` locally (example):

```sh
base64 -i DeveloperIDApplication.p12 | pbcopy
```

Paste the copied value into the GitHub secret.

## License

License not specified yet.
