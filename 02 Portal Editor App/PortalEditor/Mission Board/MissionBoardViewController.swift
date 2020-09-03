import UIKit
import MapKit

class MissionBoardViewController: UIViewController, PortalsDisplay, MKMapViewDelegate {
	private let mapView = MKMapView()
	private var selectedAnnotation: MKAnnotation?

	override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.title = "Portale"

		mapView.overrideUserInterfaceStyle = .light

		mapView.delegate = self

		mapView.showsUserLocation = true
		mapView.showsBuildings = false
		mapView.isRotateEnabled = false
		mapView.isPitchEnabled = true
		mapView.isUserInteractionEnabled = true

		let berlinCenterCoordinate = CLLocationCoordinate2D(latitude: 52.513190, longitude: 13.406770)

		// add camera
		let mapCamera = MKMapCamera(lookingAtCenter: berlinCenterCoordinate, fromDistance: 80_000, pitch: 0, heading: 0)
		mapView.camera = mapCamera

		mapView.add(to: view, activate: mapView.layoutConstraints(equal: view))
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		mapView.deselectAnnotation(selectedAnnotation, animated: true)
	}

	// MARK: PortalsDisplay
	public func finishedFetchingPortals() {
		clearMapAnnotations()

		let stories = ContentfulManager.shared.stories
		for(_, story) in stories {
			drawPolylineOverlay(for: story)
			addPortalAnnotations(for: story)
		}

		zoomToPortals()
	}

	// MARK: Helpers
	private func clearMapAnnotations() {
		mapView.removeOverlays(mapView.overlays)
		mapView.removeAnnotations(mapView.annotations)
	}

	private func drawPolylineOverlay(for story: CFStory) {
		// Add polyline connecting all portals
		guard let portals = story.portals else { return }
		var orderedCoordinates = [CLLocationCoordinate2D]()

		for portal in portals {
			guard let coordinate = portal.location?.clLocation.coordinate else { continue }
			orderedCoordinates.append(coordinate)
		}

		for pathType: PharusPathLine.LineType in [.outline, .center] {
			let overlay = PharusPathLine(color: story.color, coordinates: orderedCoordinates, count: orderedCoordinates.count)
			overlay.type = pathType
			mapView.addOverlay(overlay)
		}
	}

	private func addPortalAnnotations(for story: CFStory) {
		guard let portals = story.portals else { return }
		let storyColor = story.color

		for portal in portals {
			let annotation = PortalAnnotation(portal: portal, color: storyColor)
			mapView.addAnnotation(annotation)
		}
	}

	// MARK: Interaction Handlers

	private func zoomToPortals() {
		guard let region = allPortalsRegion else { return }

		let (latitudeDelta, longitudeDelta) = region.spanInMeters
//		let distance = max(latitudeDelta * 1.8, longitudeDelta * 3.2)
		let distance = max(latitudeDelta * 3.6, longitudeDelta * 6.4)

		let mapCamera = MKMapCamera(lookingAtCenter: region.center, fromDistance: distance, pitch: 0, heading: 0)
		mapView.setCamera(mapCamera, animated: true)
	}

	private var allPortalsRegion: MKCoordinateRegion? {
		let coordinates = ContentfulManager.shared.allPortals.compactMap({ $0.location }).map({ $0.clLocation.coordinate })

		guard
			let minLatitude = coordinates.map({ $0.latitude }).min(),
			let maxLatitude = coordinates.map({ $0.latitude }).max(),
			let minLongitude = coordinates.map({ $0.longitude }).min(),
			let maxLongitude = coordinates.map({ $0.longitude }).max()
		else { return nil }

		return CLLocationCoordinate2D(latitude: minLatitude, longitude: minLongitude).coordinateRegion(spanningTo: CLLocationCoordinate2D(latitude: maxLatitude, longitude: maxLongitude))
	}

	// MARK: MKMapViewDelegate

	func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
		if let pharusAnnotation = annotation as? PortalAnnotation {
			return PortalPin(annotation: pharusAnnotation)
		}

		return nil
	}

	func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
		if let polyline = overlay as? PharusPathLine {
			return polyline.renderer
		}
		return MKOverlayRenderer()
	}

	func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
		if let pharusPin = view as? PortalPin {
			selectedAnnotation = pharusPin.annotation

			let portal = pharusPin.pharusAnnotation.portal
			let portalDetailVC = PortalDetailsViewController(portal: portal)
			navigationController?.pushViewController(portalDetailVC, animated: true)
		}
	}
}
