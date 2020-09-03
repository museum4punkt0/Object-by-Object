import UIKit
import CoreLocation
import ARKit

class CompassNavigationViewController: UIViewController, CLLocationManagerDelegate {
	private let portal: CFPortal
	private let preselectedWorldMap: WorldMap?
	private let sessionOptions: [PortalSessionViewController.Options]
	
	private let arrowImage = UIImageView(image: UIImage(named: "Arrow"))
	private let distanceLabel = UILabel()
	private let accuracyLabel = UILabel()
	private let locationManager = CLLocationManager()
	private var currentLocation: CLLocation?
	private var currentHeading: CLHeading?
	private var portalSessionIsPresented = false // TODO: This value shouldnt be necessary
	private var currentDistance: Double? = nil {
        didSet {
            guard
                let distance = currentDistance
            else {
                print("Error: distance, destination or worldMap not set")
                return
            }
			if distance < max(AppSettings.enterSessionDistanceInMeters, currentAccuracy * 1.25) && !portalSessionIsPresented {
				var options = sessionOptions + [.isReadOnly, .showCoaching]
				if portal.worldMaps?.first == nil { options += [.isAdHocSession] }
				let portalSessionVC = PortalSessionViewController(at: portal, preselectedWorldMap: preselectedWorldMap, options: options)

				if let navigationController = navigationController {
					navigationController.pushViewController(portalSessionVC, animated: true)
				}
				else {
					portalSessionVC.modalPresentationStyle = .fullScreen
					let presentingVC = presentingViewController
					dismiss(animated: true) {
						presentingVC?.present(portalSessionVC, animated: true)
					}
				}
				portalSessionIsPresented = true
            }
		}
	}
	private var currentAccuracy: CLLocationAccuracy = 0
	private var distanceSettings: DistanceSettings = AppSettings.distanceSettings
	private var originalDistance: Double?
	private var coolOffSettings: CoolOffSettings = AppSettings.coolOffSettings
	private let coolOffViewController = CoolOffTimerViewController(coolOffDistance: 5, coolOffTime: 4, presentationTime: 4)

	init(portal: CFPortal, preselectedWorldMap: WorldMap? = nil, sessionOptions: [PortalSessionViewController.Options] = []) {
		self.portal = portal
		self.preselectedWorldMap = preselectedWorldMap
		self.sessionOptions = sessionOptions
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

	override func viewDidLoad() {
		super.viewDidLoad()

		NotificationCenter.default.addObserver(self, selector: #selector(locationUpdated), name: .locationUpdated, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(headingUpdated), name: .headingUpdated, object: nil)

		view.backgroundColor = .asset(.dark)

		NotificationCenter.default.addObserver(self, selector: #selector(coolOffStatusUpdated), name: Notification.Name("CoolOffStatusUpdated"), object: nil) // move this up; cleanup

		arrowImage.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(arrowImage)

		distanceLabel.text = ""
		distanceLabel.font = .systemFont(ofSize: 24.0, weight: .semibold)
		distanceLabel.textColor = .asset(.champagne)
		distanceLabel.textAlignment = .center
		distanceLabel.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(distanceLabel)

		accuracyLabel.text = ""
		accuracyLabel.font =  .systemFont(ofSize: 16.0, weight: .medium)
		accuracyLabel.textColor = .asset(.champagne)
		accuracyLabel.textAlignment = .center
		accuracyLabel.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(accuracyLabel)

//		let openMapButton = UIButton()
//		openMapButton.setTitle("Show on Map", for: .normal)
//		openMapButton.setTitleColor(.asset(.champagne), for: .normal)
//		openMapButton.addTarget(self, action: #selector(didTapOpenMap), for: .touchUpInside)
//		openMapButton.translatesAutoresizingMaskIntoConstraints = false
//		view.addSubview(openMapButton)

		NSLayoutConstraint.activate([
			arrowImage.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			arrowImage.centerYAnchor.constraint(equalTo: view.centerYAnchor),

			distanceLabel.topAnchor.constraint(equalTo: arrowImage.bottomAnchor, constant: 64.0),
			distanceLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            accuracyLabel.topAnchor.constraint(equalTo: distanceLabel.bottomAnchor, constant: 24.0),
            accuracyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
//			openMapButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -64.0),
//			openMapButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
		])

		switch coolOffSettings {
		case .off:
			break
		case .time, .distance:
			updateVisibility(showNavigation: false)

			addChild(coolOffViewController)
			view.addSubview(coolOffViewController.view)
			coolOffViewController.didMove(toParent: self)
			coolOffViewController.view.translatesAutoresizingMaskIntoConstraints = false

			NSLayoutConstraint.activate([
				coolOffViewController.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
				coolOffViewController.view.topAnchor.constraint(equalTo: view.topAnchor, constant: 32.0),
				coolOffViewController.view.widthAnchor.constraint(equalTo: view.widthAnchor),
				coolOffViewController.view.heightAnchor.constraint(equalToConstant: 200.0)
			])
		}
	}

	private func updateVisibility(showNavigation: Bool) {
		arrowImage.isHidden = !showNavigation
		distanceLabel.isHidden = !showNavigation
	}

	@objc
	private func locationUpdated(_ sender: NSNotification) {
		guard
			let location = sender.object as? CLLocation,
			let targetCFLocation = portal.location
		else { return }

		currentAccuracy = location.horizontalAccuracy
		
		accuracyLabel.text = "Accuracy: \(location.horizontalAccuracy.friendlyString(0)) m"

		let distance: Double = location.distance(from: CLLocation(latitude: targetCFLocation.latitude, longitude: targetCFLocation.longitude))
		if originalDistance == nil { originalDistance = distance }

		updateDistanceLabel(distance: distance)

		currentLocation = location
		currentDistance = distance
	}

	@objc
	private func headingUpdated(_ sender: NSNotification) {
		guard
			let currentLocation = currentLocation,
			let heading = sender.object as? CLHeading,
			let targetCFLocation = portal.location
		else { return }


        let bearing = currentLocation.bearing(to: CLLocation(latitude: targetCFLocation.latitude, longitude: targetCFLocation.longitude))

		UIView.animate(withDuration: 0.5) {
			var angle: CGFloat = (360.0 - CGFloat(heading.trueHeading)) + CGFloat(bearing)
			if angle > 360 { angle -= 360 }
			self.arrowImage.transform = CGAffineTransform(rotationAngle: angle.degreesToRadians)
		}

		currentHeading = heading
	}

	private func updateDistanceLabel(distance: Double) {
		switch distanceSettings {
		case .off:
			distanceLabel.text = ""
		case .exact:
			distanceLabel.text = distance.friendlyString(0) + " m"
		case .rough:
			distanceLabel.text = (round(distance / 10) * 10).friendlyString(0) + " m"
		case .percentage:
			if let originalDistance = originalDistance {
				distanceLabel.text = (100 - 100 * distance/originalDistance).friendlyString(0) + " %"
			}
		}
	}

	@objc
	private func coolOffStatusUpdated(notification: Notification) {
		guard let status = notification.object as? CoolOffStatus else { return }
		switch status {
		case .locked, .unlockPossible:
			updateVisibility(showNavigation: false)
		case .unlocked:
			updateVisibility(showNavigation: true)
		}
	}

	@objc
	private func didTapOpenMap() {
		present(UINavigationController(rootViewController: MapNavigationViewController(destination: portal)), animated: true)
	}
}
