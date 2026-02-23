//
//  praytimeApp.swift
//  praytime
//
//  Created by Muhammed Saeed on 22/02/2026.
//

import SwiftUI

@main
struct PraytimeApp: App {
    @StateObject private var store = PrayerTimesStore()

    var body: some Scene {
        MenuBarExtra("Praytime", systemImage: "sun.and.horizon.fill") {
            PrayerMenuView()
                .environmentObject(store)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(store)
        }
    }
}
