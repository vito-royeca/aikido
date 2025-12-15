//
//  LocationManager.swift
//  Aikido
//
//  Created by Vito Royeca on 12/14/25.
//

import CoreLocation

class LocationManager: NSObject, ObservableObject {
    @Published var coordinate: CLLocationCoordinate2D?
    @Published var placeName: String?
    
    private let manager = CLLocationManager()
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() {
//        if CLLocationManager.authorizationStatus() != .authorizedWhenInUse {
            manager.requestAlwaysAuthorization()
//        }
    }
}

extension LocationManager: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
//            if CLLocationManager.locationServicesEnabled() {
                manager.requestLocation()
//            }
        case .denied, .restricted:
            coordinate = nil
            placeName = nil
        case .notDetermined:
            // Do nothing, waiting for user decision
            break
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        coordinate = locations.first?.coordinate
        
        Task {
            let placeName = try? await lookupPlaceName()
            await MainActor.run {
                self.placeName = placeName
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        coordinate = nil
        placeName = nil
    }
    
    private func lookupPlaceName() async throws -> String? {
        guard let lastLocation = manager.location else {
            return nil
        }
        
        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.reverseGeocodeLocation(lastLocation)
        return placemarks.first?.name
    }
}

