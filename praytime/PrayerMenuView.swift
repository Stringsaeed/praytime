import SwiftUI

struct PrayerMenuView: View {
    @EnvironmentObject private var store: PrayerTimesStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerSection
            Divider()
            prayerList
            VStack(alignment: .leading, spacing: 4) {
                Text(store.locationStatusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !store.notificationsAuthorized {
                    Text("Enable notifications in System Settings for reminders.")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
            Divider()
            HStack {
                Button("Refresh Location", action: store.refreshLocation)
                Spacer()
                SettingsLink {
                    Label("Settings", systemImage: "gearshape")
                }
            }
        }
        .padding(16)
        .frame(width: 320)
    }

    private var headerSection: some View {
        Group {
            if let next = store.nextPrayer {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next Prayer")
                        .font(.caption)
                        .textCase(.uppercase)
                        .foregroundStyle(.secondary)
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(next.displayName)
                                .font(.title3.bold())
                            Text("in \(relativeTime(until: next.time))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(store.formattedTime(for: next.time))
                            .font(.title3.weight(.semibold))
                    }
                }
            } else {
                Text("Waiting for schedule…")
                    .font(.headline)
            }
        }
    }

    private var prayerList: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(store.prayerEntries) { entry in
                HStack {
                    Text(entry.displayName)
                    Spacer()
                    Text(store.formattedTime(for: entry.time))
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(rowBackground(for: entry))
                .cornerRadius(8)
            }
            if store.prayerEntries.isEmpty {
                Text("Fetching today's prayer times…")
                    .font(.subheadline)
            }
        }
    }

    private func rowBackground(for entry: PrayerEntry) -> Color {
        guard let next = store.nextPrayer else { return Color.clear }
        return next == entry ? Color.accentColor.opacity(0.15) : Color.clear
    }

    private func relativeTime(until date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

}

#Preview {
    PrayerMenuView()
        .environmentObject(PrayerTimesStore())
}
