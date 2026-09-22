import CoreLocation

extension Store {
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    /// Straight-line distance in meters; `nil` for online stores or without a user location.
    func distance(from location: CLLocation?) -> CLLocationDistance? {
        guard let location = location, let lat = latitude, let lon = longitude else { return nil }
        return CLLocation(latitude: lat, longitude: lon).distance(from: location)
    }
}
