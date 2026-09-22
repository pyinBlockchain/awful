import CoreLocation

/// Thin CoreLocation wrapper. The app works fully without permission, so we never ask at
/// launch — only when the user taps something that needs location (map "my location",
/// or "nearest" sorting).
@MainActor
final class LocationService: NSObject, ObservableObject {
    @Published private(set) var authorization: CLAuthorizationStatus
    @Published private(set) var location: CLLocation?

    private let manager: CLLocationManager

    override init() {
        let manager = CLLocationManager()
        self.manager = manager
        authorization = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        // Store distances only need to be roughly right; fewer updates save battery.
        manager.distanceFilter = 200
        startIfAuthorized()
    }

    var isAuthorized: Bool {
        authorization == .authorizedWhenInUse || authorization == .authorizedAlways
    }

    var canRequestPermission: Bool { authorization == .notDetermined }

    var isDenied: Bool { authorization == .denied || authorization == .restricted }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    private func startIfAuthorized() {
        if isAuthorized {
            manager.startUpdatingLocation()
        } else {
            manager.stopUpdatingLocation()
            location = nil
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorization = status
            self.startIfAuthorized()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        Task { @MainActor in self.location = latest }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DataWarningLog.warn("Location update failed: \(error.localizedDescription)")
    }
}
