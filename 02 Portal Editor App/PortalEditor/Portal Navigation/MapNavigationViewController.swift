import UIKit
import MapKit
import CoreLocation

class MapNavigationViewController: UIViewController, MKMapViewDelegate {
	private let destination: CFPortal

	private let mapView = MKMapView()
	private let annotationID = "annotationID"

	init(destination: CFPortal) {
		self.destination = destination
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		view.backgroundColor = .system(.systemBackground)

		navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
		navigationController?.navigationBar.shadowImage = UIImage()
		navigationController?.navigationBar.isTranslucent = true

		mapView.delegate = self
		mapView.showsUserLocation = true
		mapView.register(CustomMKMarkerSubclass.self, forAnnotationViewWithReuseIdentifier: annotationID)
		mapView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(mapView)

		guard let location = destination.location else { return }

		let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
		let annotation = MapAnnotation(title: destination.title, coordinate: coordinate)
		mapView.addAnnotation(annotation)

		let span = MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
		let region = MKCoordinateRegion(center: coordinate, span: span)
		mapView.setRegion(region, animated: true)

		navigationItem.leftBarButtonItem = UIBarButtonItem.systemCloseButton(target: self, action: #selector(didTapClose))

		NSLayoutConstraint.activate([
			mapView.topAnchor.constraint(equalTo: view.topAnchor),
			mapView.leftAnchor.constraint(equalTo: view.leftAnchor),
			mapView.rightAnchor.constraint(equalTo: view.rightAnchor),
			mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
		])
	}

	@objc
	private func didTapClose() {
		dismiss(animated: true, completion: nil)
	}

	// MARK: - MKMapViewDelegate

	func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
		// Only replace MapAnnotations with the new marker. Not the user's location marker.
		guard let annotation = annotation as? MapAnnotation else { return nil }

		let markerView = CustomMKMarkerSubclass(annotation: annotation, reuseIdentifier: annotationID)
		return markerView
	}
}
