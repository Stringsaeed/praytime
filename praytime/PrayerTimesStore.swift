import Adhan
import Combine
import CoreLocation
import Foundation
import UserNotifications

struct PrayerEntry: Identifiable, Equatable {
    let prayer: Prayer
    let time: Date

    var id: Prayer { prayer }

    var displayName: String {
        switch prayer {
        case .fajr:
            return "Fajr"
        case .sunrise:
            return "Sunrise"
        case .dhuhr:
            return "Dhuhr"
        case .asr:
            return "Asr"
        case .maghrib:
            return "Maghrib"
        case .isha:
            return "Isha"
        }
    }
}

@MainActor
final class PrayerTimesStore: NSObject, ObservableObject {
    @Published var prayerEntries: [PrayerEntry] = []
    @Published var nextPrayer: PrayerEntry?
    @Published var locationStatusMessage: String = "Requesting location…"
    @Published var notificationsAuthorized: Bool = false
    @Published private(set) var leadTimeMinutes: Int

    private lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 500
        return manager
    }()

    private let notificationCenter = UNUserNotificationCenter.current()
    private var refreshTimer: Timer?
    private var lastKnownLocation: CLLocation?
    private var lastComputationDate: Date?

    private static let leadTimeDefaultsKey = "notificationLeadTimeMinutes"
    private static let cachedLatitudeDefaultsKey = "cachedLatitude"
    private static let cachedLongitudeDefaultsKey = "cachedLongitude"
    private static let displayedPrayers: [Prayer] = [.fajr, .dhuhr, .asr, .maghrib, .isha]

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        formatter.locale = Locale.autoupdatingCurrent
        return formatter
    }()

    override init() {
        let storedValue = UserDefaults.standard.integer(forKey: Self.leadTimeDefaultsKey)
        leadTimeMinutes = storedValue == 0 ? 20 : storedValue
        super.init()
        restoreCachedLocationIfAvailable()
        configureLocationServices()
        requestNotificationAuthorization()
        startTicker()
    }

    deinit {
        refreshTimer?.invalidate()
    }

    func refreshLocation() {
        handleAuthorizationStatus(locationManager.authorizationStatus)
        locationManager.requestLocation()
    }

    func formattedTime(for date: Date) -> String {
        timeFormatter.string(from: date)
    }

    func updateLeadTime(minutes: Int) {
        let clamped = max(5, min(120, minutes))
        guard clamped != leadTimeMinutes else { return }
        leadTimeMinutes = clamped
        UserDefaults.standard.set(clamped, forKey: Self.leadTimeDefaultsKey)
        scheduleNextNotification()
    }

    private func configureLocationServices() {
        if let lastKnownLocation {
            locationStatusMessage = "Using saved location for prayer times."
            calculateSchedule(for: lastKnownLocation, referenceDate: Date())
        }

        guard CLLocationManager.locationServicesEnabled() else {
            if lastKnownLocation == nil {
                locationStatusMessage = "Enable Location Services in System Settings."
            }
            return
        }
        let status = locationManager.authorizationStatus
        if status == .notDetermined {
            locationStatusMessage = "Requesting location…"
            locationManager.requestWhenInUseAuthorization()
        } else {
            handleAuthorizationStatus(status)
        }
    }

    private func requestNotificationAuthorization() {
        notificationCenter.requestAuthorization(options: [.alert, .sound]) { [weak self] granted, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let error {
                    NSLog("Notification authorization error: %@", error.localizedDescription)
                }
                self.notificationsAuthorized = granted
                if granted {
                    self.scheduleNextNotification()
                }
            }
        }
    }

    private func startTicker() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.handleTick()
            }
        }
    }

    private func handleTick() {
        guard let location = lastKnownLocation else { return }
        let now = Date()
        if let lastComputationDate, !Calendar.current.isDate(lastComputationDate, inSameDayAs: now) {
            calculateSchedule(for: location, referenceDate: now)
        } else {
            updateUpcomingPrayer()
        }
    }

    private func calculateSchedule(for location: CLLocation, referenceDate: Date) {
        let coordinates = Coordinates(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        var parameters = CalculationMethod.muslimWorldLeague.params
        parameters.madhab = .shafi
        let calendar = Calendar(identifier: .gregorian)
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: referenceDate)

        guard let prayerTimes = PrayerTimes(coordinates: coordinates, date: dateComponents, calculationParameters: parameters) else {
            locationStatusMessage = "Unable to compute prayer schedule."
            return
        }

        lastComputationDate = referenceDate
        prayerEntries = Self.displayedPrayers.map { prayer in
            PrayerEntry(prayer: prayer, time: prayerTimes.time(for: prayer))
        }
        locationStatusMessage = "Updated at \(formattedTime(for: referenceDate))"
        updateUpcomingPrayer()
    }

    private func updateUpcomingPrayer() {
        let now = Date()
        if let entry = prayerEntries.first(where: { $0.time > now }) {
            nextPrayer = entry
        } else {
            nextPrayer = nil
        }
        scheduleNextNotification()
    }

    private func scheduleNextNotification() {
        guard notificationsAuthorized, let nextPrayer else {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: ["nextPrayer"])
            return
        }

        let triggerDate = nextPrayer.time.addingTimeInterval(TimeInterval(-leadTimeMinutes * 60))
        guard triggerDate > Date() else { return }

        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["nextPrayer"])

        let content = UNMutableNotificationContent()
        content.title = "Upcoming Prayer"
        content.body = "\(nextPrayer.displayName) begins at \(formattedTime(for: nextPrayer.time))."
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: "nextPrayer", content: content, trigger: trigger)
        notificationCenter.add(request)
    }

    private func restoreCachedLocationIfAvailable() {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: Self.cachedLatitudeDefaultsKey) != nil,
              defaults.object(forKey: Self.cachedLongitudeDefaultsKey) != nil else {
            return
        }

        let latitude = defaults.double(forKey: Self.cachedLatitudeDefaultsKey)
        let longitude = defaults.double(forKey: Self.cachedLongitudeDefaultsKey)
        lastKnownLocation = CLLocation(latitude: latitude, longitude: longitude)
    }

    private func cacheLocation(_ location: CLLocation) {
        let defaults = UserDefaults.standard
        defaults.set(location.coordinate.latitude, forKey: Self.cachedLatitudeDefaultsKey)
        defaults.set(location.coordinate.longitude, forKey: Self.cachedLongitudeDefaultsKey)
    }
}

extension PrayerTimesStore: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        handleAuthorizationStatus(manager.authorizationStatus)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationStatusMessage = "Location error: \(error.localizedDescription)"
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        manager.stopUpdatingLocation()
        lastKnownLocation = location
        cacheLocation(location)
        calculateSchedule(for: location, referenceDate: Date())
    }

    private func handleAuthorizationStatus(_ status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            if lastKnownLocation == nil {
                locationStatusMessage = "Requesting location…"
                locationManager.requestLocation()
            } else {
                locationStatusMessage = "Using saved location for prayer times."
            }
        case .denied:
            locationStatusMessage = "Location access denied. Enable it in System Settings."
        case .restricted:
            locationStatusMessage = "Location access restricted."
        case .notDetermined:
            locationStatusMessage = "Requesting location…"
        @unknown default:
            locationStatusMessage = "Unknown location status."
        }
    }
}
