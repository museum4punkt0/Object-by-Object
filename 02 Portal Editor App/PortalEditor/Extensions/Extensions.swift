import UIKit
import Contentful
import CoreLocation

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension Notification.Name {
	static let locationUpdated = Notification.Name("CLLocation Update")
	static let headingUpdated = Notification.Name("CLHeading Update")
}

extension DispatchQueue {
	public static let updateQueue = DispatchQueue(label: "de.programmator.PortalEditor.serialSceneKitQueue")
}

extension Location {
    var clLocation: CLLocation {
        return CLLocation(latitude: self.latitude, longitude: self.longitude)
    }
}

extension CLLocation {
    func bearing(to location: CLLocation) -> Double {

        let lat1 = self.coordinate.latitude.degreesToRadians
        let lon1 = self.coordinate.longitude.degreesToRadians

        let lat2 = location.coordinate.latitude.degreesToRadians
        let lon2 = location.coordinate.longitude.degreesToRadians

        let dLon = lon2 - lon1

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)

        return radiansBearing.radiansToDegrees
    }
}

extension CGFloat {
  var degreesToRadians: CGFloat { return self * .pi / 180 }
  var radiansToDegrees: CGFloat { return self * 180 / .pi }
}

extension Double {
  var degreesToRadians: Double { return Double(CGFloat(self).degreesToRadians) }
  var radiansToDegrees: Double { return Double(CGFloat(self).radiansToDegrees) }
}

extension Float {
	var degreesToRadians: Float { return self * .pi / 180 }
	var radiansToDegrees: Float { return self * 180 / .pi }
}
