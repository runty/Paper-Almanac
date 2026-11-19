import CoreLocation
import SwiftUI
import WidgetKit

/// Only the app acquires locations. The widget reads a rounded, device-local snapshot.
@MainActor final class MoonLocation: NSObject, ObservableObject, @preconcurrency CLLocationManagerDelegate {
    static let shared = MoonLocation()
    private static let key = "moon.useCurrentLocation"
    @Published private(set) var enabled = DailyTheme.defaults.bool(forKey: key)
    @Published var message: String?
    @Published private(set) var site = SkySite.saved
    private var manager: CLLocationManager?
    private var askingPermission = false
    private var pending = false
    private var lastFix: Date?

    func setEnabled(_ value: Bool) {
        enabled = value
        DailyTheme.defaults.set(value, forKey: Self.key)
        if value {
            refresh(requestPermission: true)
        } else {
            manager?.delegate = nil
            manager?.stopUpdatingLocation()
            manager = nil
            pending = false
            askingPermission = false
            lastFix = nil
            save(nil)
        }
    }

    func refresh(requestPermission: Bool = false) {
        guard enabled else { return }
        if manager == nil {
            let location = CLLocationManager()
            location.desiredAccuracy = kCLLocationAccuracyThreeKilometers
            manager = location
            location.delegate = self
        }
        guard let manager else { return }
        switch manager.authorizationStatus {
        case .notDetermined:
            if requestPermission {
                askingPermission = true
                manager.requestWhenInUseAuthorization()
            } else if !askingPermission {
                setEnabled(false)
            }
        case .denied, .restricted:
            setEnabled(false)
            message = "Location access is off. Moon is using the northern mid-latitude sky. You can allow access in your device’s Location Services settings."
        case .authorizedAlways, .authorizedWhenInUse:
            askingPermission = false
            guard !pending, lastFix.map({ Date.now.timeIntervalSince($0) > 900 }) ?? true else { return }
            pending = true
            manager.requestLocation()
        @unknown default: break
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard manager === self.manager else { return }
        if manager.authorizationStatus != .notDetermined { refresh() }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard enabled, manager === self.manager else { return }
        pending = false
        guard let fix = locations.last, fix.horizontalAccuracy >= 0,
              abs(fix.timestamp.timeIntervalSinceNow) < 900,
              CLLocationCoordinate2DIsValid(fix.coordinate) else {
            unavailable()
            return
        }
        lastFix = fix.timestamp
        save(SkySite(latitude: fix.coordinate.latitude.rounded(), longitude: fix.coordinate.longitude.rounded()))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard enabled, manager === self.manager else { return }
        pending = false
        if (error as? CLError)?.code == .denied {
            setEnabled(false)
            message = "Location access is off. Moon is using the northern mid-latitude sky."
        } else { unavailable() }
    }

    private func unavailable() {
        message = site == nil ? "Your location is unavailable. Moon is using the northern mid-latitude sky."
                              : "Your location is unavailable. Moon is using your last saved area."
    }

    private func save(_ value: SkySite?) {
        guard value != site else { return }
        DailyTheme.defaults.set(value.map { [$0.latitude, $0.longitude] }, forKey: SkySite.key)
        site = value
        WidgetCenter.shared.reloadTimelines(ofKind: "TungShingDailyWidget")
    }
}
