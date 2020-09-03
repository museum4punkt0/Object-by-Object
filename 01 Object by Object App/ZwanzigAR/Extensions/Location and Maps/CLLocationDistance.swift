import UIKit
import CoreLocation

extension CLLocationDistance {
	public func distanceString() -> String {
		let distance = Double(self)
		switch distance {
		case 0..<50:
			return distance.friendlyString(0) + " m"
		case 50..<1000:
//			return ((distance / 10).rounded() * 10).friendlyString(0) + " m"
			return (distance / 10).friendlyString(0) + "0 m"
		default:
			return (distance / 1000).friendlyString(1).replacingOccurrences(of: ".", with: ",") + " km"
		}

	}
}
