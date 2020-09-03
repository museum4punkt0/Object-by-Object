import UIKit
import CoreLocation

final class LocationManager: NSObject, CLLocationManagerDelegate {
	private let locationManager = CLLocationManager()
	public var location: CLLocation?
	public var heading: CLHeading?

	static let shared = LocationManager()

	private override init() {
		super.init()
		locationManager.delegate = self
		locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
		locationManager.requestAlwaysAuthorization()
		locationManager.startUpdatingLocation()
		locationManager.startUpdatingHeading()

		UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
	}

	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		if let location = locations.last {
			self.location = location
			NotificationCenter.default.post(name: .locationUpdated, object: location)
		}
	}

	func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
		heading = newHeading
		NotificationCenter.default.post(name: .headingUpdated, object: newHeading)
	}

	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		print("⚠️ Error while updating location " + error.localizedDescription)
	}

	@objc
	private func orientationChanged(_ notification: NSNotification) {
		let device = notification.object as? UIDevice
		let orientation = device?.orientation

		switch orientation {
		case .landscapeLeft:
			locationManager.headingOrientation = .landscapeLeft
		case .landscapeRight:
			locationManager.headingOrientation = .landscapeRight
		case .portrait:
			locationManager.headingOrientation = .portrait
		case .portraitUpsideDown:
			locationManager.headingOrientation = .portraitUpsideDown
		case .faceUp:
			locationManager.headingOrientation = .faceUp
		case .faceDown:
			locationManager.headingOrientation = .faceDown
		case .unknown, .none:
			locationManager.headingOrientation = .unknown
		@unknown default:
			print("Unknown case")
		}
	}
}
