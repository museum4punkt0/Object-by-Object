import CoreLocation
import MapKit

extension CLLocation {
	func midPoint(to location: CLLocation) -> CLLocationCoordinate2D {
		return self.coordinate.midPoint(to: location.coordinate)
	}

	func weightedMidPoint(fractionOfWay: Double, to location: CLLocation) -> CLLocationCoordinate2D {
		return self.coordinate.weightedMidPoint(fractionOfWay: fractionOfWay, to: location.coordinate)
	}
}

extension CLLocationCoordinate2D {
    func bearing(to coordinate: CLLocationCoordinate2D) -> Double {

        let lat1 = self.latitude.degreesToRadians
        let lon1 = self.longitude.degreesToRadians

        let lat2 = coordinate.latitude.degreesToRadians
        let lon2 = coordinate.longitude.degreesToRadians

        let dLon = lon2 - lon1

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)

        return radiansBearing.radiansToDegrees
    }

	func midPoint(to coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
		let lat1 = latitude
		let lon1 = longitude
		let lat2 = coordinate.latitude
		let lon2 = coordinate.longitude

		return CLLocationCoordinate2D(latitude: (lat1+lat2)/2, longitude: (lon1+lon2)/2)
	}

	func weightedMidPoint(fractionOfWay: Double, to coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
		let lat1 = latitude
		let lon1 = longitude
		let lat2 = coordinate.latitude
		let lon2 = coordinate.longitude

		let weight = min(max(0, fractionOfWay), 1)

		return CLLocationCoordinate2D(latitude: (1-weight)*lat1 + weight*lat2, longitude: (1-weight)*lon1 + weight*lon2)
	}

	func coordinateRegion(spanningTo coordinate: CLLocationCoordinate2D) -> MKCoordinateRegion {
		return MKCoordinateRegion(center: self.midPoint(to: coordinate), span: MKCoordinateSpan(latitudeDelta: abs(self.latitude - coordinate.latitude), longitudeDelta: abs(self.longitude - coordinate.longitude)))
	}
}
