import UIKit
import MapKit

class PharusPinSection: UIView {
	struct Constants {
		static let topPadding: CGFloat = 32
		static let bottomPadding: CGFloat = 32
		static let verticalPadding: CGFloat = 16
	}

	private let portal: Portal

	private lazy var coordinate: CLLocationCoordinate2D = portal.location?.coordinate ?? CLLocationCoordinate2D()

	init(_ portal: Portal) {
		self.portal = portal
		super.init(frame: .zero)
		setup()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setup() {
		let circleView = UICircleView()
		circleView.backgroundColor = .dark80Branded
		circleView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(circleView)

		let mapView = PharusMapView(mode: .navigation)
		circleView.add(mapView, activate: [
			mapView.topAnchor.constraint(equalTo: circleView.topAnchor),
			mapView.bottomAnchor.constraint(equalTo: circleView.bottomAnchor),
			mapView.leftAnchor.constraint(equalTo: circleView.leftAnchor),
			mapView.rightAnchor.constraint(equalTo: circleView.rightAnchor)
		])
		mapView.addOverlay(PortalMapOverlay(portal: portal))
		mapView.addAnnotation(PortalAnnotation(portal: portal))

		let mapActionView = ActionView(action: { [weak self] in
			self?.openPharusNavigator()
		})
		circleView.add(mapActionView, activate: [
			mapActionView.topAnchor.constraint(equalTo: circleView.topAnchor),
			mapActionView.bottomAnchor.constraint(equalTo: circleView.bottomAnchor),
			mapActionView.leftAnchor.constraint(equalTo: circleView.leftAnchor),
			mapActionView.rightAnchor.constraint(equalTo: circleView.rightAnchor)
		])

		let mapCamera = MKMapCamera(lookingAtCenter: coordinate, fromDistance: 1000, pitch: PharusMapView.Constants.pitch, heading: 0)
		mapView.setCamera(mapCamera, animated: false)

		let button = DiamondButton(.pharusPin, action: { [weak self] in
			self?.openPharusNavigator()
		})
		button.translatesAutoresizingMaskIntoConstraints = false
		addSubview(button)

		let buttonLabel = UILabel.label(for: .subtitleSmall, text: "Noch mal besuchen")
		buttonLabel.translatesAutoresizingMaskIntoConstraints = false
		addSubview(buttonLabel)

		NSLayoutConstraint.activate([
			circleView.centerXAnchor.constraint(equalTo: centerXAnchor),
			circleView.topAnchor.constraint(equalTo: topAnchor, constant: Constants.topPadding),
			circleView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.67),
			circleView.heightAnchor.constraint(equalTo: circleView.widthAnchor),

			button.centerXAnchor.constraint(equalTo: centerXAnchor),
			button.topAnchor.constraint(equalTo: circleView.bottomAnchor, constant: Constants.verticalPadding),

			buttonLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
			buttonLabel.topAnchor.constraint(equalTo: button.bottomAnchor, constant: Constants.verticalPadding),
			buttonLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.bottomPadding)
		])
	}

	private func openPharusNavigator() {
		let navigatorVC = NavigatorViewController(navigationTool: .pharusPin, targetPortal: portal)
		navigatorVC.transitioningDelegate = navigatorVC.presentationManager
		navigatorVC.modalPresentationStyle = .custom

		UIViewController.topMost?.present(navigatorVC, animated: true, completion: nil)
	}
}
