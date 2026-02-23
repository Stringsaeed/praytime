import AppKit
import SwiftUI

struct SettingsView: View {
    private enum Tab: String, Hashable {
        case general
        case notifications
        case location
    }
    
    @EnvironmentObject private var store: PrayerTimesStore
    @State private var selectedTab: Tab = .general
    
    var body: some View {
        TabView(selection: $selectedTab) {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
                .tag(Tab.general)
            
            notificationsTab
                .tabItem {
                    Label("Notifications", systemImage: "bell.badge")
                }
                .tag(Tab.notifications)
            
            locationTab
                .tabItem {
                    Label("Location", systemImage: "location")
                }
                .tag(Tab.location)
        }
        .frame(minWidth: 520, minHeight: 420)
    }
    
    private var generalTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                settingsHeader(
                    title: "Praytime",
                    subtitle: "Prayer times and reminders for your menu bar",
                    systemImage: "sun.and.horizon.fill"
                )
                
                GroupBox("Prayer Schedule") {
                    VStack(alignment: .leading, spacing: 12) {
                        LabeledContent("Next prayer") {
                            if let nextPrayer = store.nextPrayer {
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(nextPrayer.displayName)
                                        .fontWeight(.semibold)
                                    Text(store.formattedTime(for: nextPrayer.time))
                                        .foregroundStyle(.secondary)
                                }
                            } else {
                                Text("Waiting for location")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Divider()
                        
                        LabeledContent("Location status") {
                            Text(store.locationStatusMessage)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                GroupBox("Quick Actions") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Use these controls to refresh permissions and schedule data.")
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 10) {
                            Button("Refresh Location") {
                                store.refreshLocation()
                            }
                            Button("Notification Settings") {
                                openNotificationSettings()
                            }
                            .buttonStyle(.link)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(20)
        }
    }
    
    private var notificationsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                settingsHeader(
                    title: "Notifications",
                    subtitle: "Choose when Praytime reminds you before the next prayer.",
                    systemImage: "bell.badge.fill"
                )
                
                GroupBox("Reminder Timing") {
                    VStack(alignment: .leading, spacing: 12) {
                        LabeledContent("Lead time") {
                            Text("\(store.leadTimeMinutes) min")
                                .fontWeight(.semibold)
                                .monospacedDigit()
                        }
                        
                        Stepper(value: leadTimeBinding, in: 5...120, step: 5) {
                            Text("Notify \(store.leadTimeMinutes) minutes early")
                        }
                        
                        Slider(value: leadTimeSliderBinding, in: 5...120, step: 5)
                            .accessibilityLabel("Notification lead time slider")
                        
                        Text("Applies to the next scheduled prayer notification.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                GroupBox("Permission Status") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            PermissionBadge(
                                title: store.notificationsAuthorized ? "Enabled" : "Disabled",
                                systemImage: store.notificationsAuthorized ? "checkmark.circle.fill" : "exclamationmark.triangle.fill",
                                tint: store.notificationsAuthorized ? .green : .orange
                            )
                            
                            Text(store.notificationsAuthorized
                                 ? "Praytime can schedule alerts before the next prayer."
                                 : "Enable notifications in System Settings to receive reminders.")
                            .foregroundStyle(.secondary)
                        }
                        
                        if !store.notificationsAuthorized {
                            Button("Open Notification Settings") {
                                openNotificationSettings()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(20)
        }
    }
    
    private var locationTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                settingsHeader(
                    title: "Location",
                    subtitle: "Praytime saves your location locally and reuses it for prayer time calculations.",
                    systemImage: "location.fill"
                )
                
                GroupBox("Current Status") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(store.locationStatusMessage)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 10) {
                            Button("Refresh Location") {
                                store.refreshLocation()
                            }
                            
                            Button("Open Privacy Settings") {
                                openLocationSettings()
                            }
                            .buttonStyle(.link)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                GroupBox("Privacy") {
                    Text("Your location is stored and used locally on this Mac to compute prayer times. Use Refresh Location if you move or travel.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(20)
        }
    }
    
    private var leadTimeBinding: Binding<Int> {
        Binding(
            get: { store.leadTimeMinutes },
            set: { store.updateLeadTime(minutes: $0) }
        )
    }
    
    private var leadTimeSliderBinding: Binding<Double> {
        Binding(
            get: { Double(store.leadTimeMinutes) },
            set: { store.updateLeadTime(minutes: Int($0.rounded())) }
        )
    }
    
    private func settingsHeader(title: String, subtitle: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .semibold))
                .frame(width: 34, height: 34)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.title3.weight(.semibold))
                Text(subtitle)
                    .foregroundStyle(.secondary)
            }
            
            Spacer(minLength: 0)
        }
    }
    
    private func openNotificationSettings() {
        let notificationsPath = "x-apple.systempreferences:com.apple.Notifications-Settings.extension"
        let bundleId = Bundle.main.bundleIdentifier
        guard let url = URL(string: "\(notificationsPath)?id=\(bundleId ?? "")") else { return }
    
        NSWorkspace.shared.open(url)
    }
    
    private func openLocationSettings() {
        let locationSettingsURLString = "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices"
        let bundleId = Bundle.main.bundleIdentifier
        guard let url = URL(string: "\(locationSettingsURLString)&id=\(bundleId ?? "")") else { return }

        NSWorkspace.shared.open(url)
    }
}

private struct PermissionBadge: View {
    let title: String
    let systemImage: String
    let tint: Color
    
    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.12), in: Capsule())
            .accessibilityElement(children: .combine)
    }
}

#Preview {
    SettingsView()
        .environmentObject(PrayerTimesStore())
}
