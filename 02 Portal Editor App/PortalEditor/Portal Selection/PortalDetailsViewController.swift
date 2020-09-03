import UIKit
import MapKit
import ARKit

class PortalDetailsViewController: UIViewController, MKMapViewDelegate, UITableViewDataSource, UITableViewDelegate {
	private let portal: CFPortal
	private var localWorldMaps: [LocalWorldMap] { portal.localWorldMaps }
	private var fetchedWorldMaps: [CFWorldMap] { portal.worldMaps?.filter({ $0.mapFile != nil }) ?? [] }

	private let scrollView = UIScrollView()
	private let mapView = MKMapView()
	private let adHocSessionButton = UIButton(type: .custom)
	private let commentsHeadline = UILabel()
	private var textView: UITextView?
	private let worldMapsHeadline = UILabel()
	private let worldMapsTableView = UITableView()

	private lazy var tableViewHeightConstraint = NSLayoutConstraint(item: worldMapsTableView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 0.0)

	private var contentHeight: CGFloat {
		let totalVerticalPadding: CGFloat = 80
		var height = mapView.bounds.height + adHocSessionButton.bounds.height + worldMapsHeadline.bounds.height + tableViewHeight + totalVerticalPadding
		if let textView = textView {
			height += textView.bounds.height
			height += commentsHeadline.bounds.height
		}
		return height
	}
	private var tableViewHeight: CGFloat {
		return worldMapsTableView.contentSize.height
	}

	init(portal: CFPortal) {
		self.portal = portal
		super.init(nibName: nil, bundle: nil)
		portal.findLocalMatchesOfFetchedWorldMaps()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		view.backgroundColor = .system(.systemBackground)

		navigationItem.title = portal.title

		let createNewBtn = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapCreateNew))
		navigationItem.rightBarButtonItem = createNewBtn

		scrollView.add(to: view, activate: [
			scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
			scrollView.leftAnchor.constraint(equalTo: view.leftAnchor),
			scrollView.rightAnchor.constraint(equalTo: view.rightAnchor),
			scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
		])

		let contentView = UIView()
		contentView.add(to: scrollView, activate: [
			contentView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
			contentView.leftAnchor.constraint(equalTo: scrollView.leftAnchor),
			contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
			contentView.rightAnchor.constraint(equalTo: scrollView.rightAnchor),
		])

		// Map View
		mapView.isScrollEnabled = false
		mapView.isRotateEnabled = false
		mapView.isZoomEnabled = false
		mapView.delegate = self

		if let location = portal.location {
			let annotation = PortalAnnotation(portal: portal, color: portal.storyColor)
			mapView.addAnnotation(annotation)

			let span = MKCoordinateSpan(latitudeDelta: 0.0025, longitudeDelta: 0.0025)
			let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
			let region = MKCoordinateRegion(center: coordinate, span: span)
			mapView.setRegion(region, animated: true)
		}

		mapView.add(to: contentView, activate: [
			mapView.topAnchor.constraint(equalTo: contentView.topAnchor),
			mapView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
			mapView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
			mapView.heightAnchor.constraint(equalToConstant: 160)
		])

		// Start ad-hoc-session button
        adHocSessionButton.setTitle("Start Ad-Hoc-Session", for: .normal)
		adHocSessionButton.setTitleColor(.systemBlue, for: .normal)
        adHocSessionButton.addTarget(self, action: #selector(startAdHocSession), for: .touchUpInside)
        adHocSessionButton.add(to: contentView, activate: [
            adHocSessionButton.topAnchor.constraint(equalTo: mapView.bottomAnchor, constant: 24.0),
            adHocSessionButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
        ])

		// TextView with comments
		if let comments = portal.comments {
			textView = UITextView()
			guard let textView = textView else { return }

			// Comments Headline
			commentsHeadline.font = .systemFont(ofSize: 18, weight: .bold)
			commentsHeadline.text = "Bemerkungen"
			commentsHeadline.textColor = .white
			commentsHeadline.add(to: contentView, activate: [
				commentsHeadline.topAnchor.constraint(equalTo: adHocSessionButton.bottomAnchor, constant: 16),
				commentsHeadline.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16)
			])

			textView.isScrollEnabled = false
			textView.isEditable = false
			textView.text = comments
			textView.font = UIFont.systemFont(ofSize: 14, weight: .regular)
			textView.textColor = .white
			textView.backgroundColor = UIColor.init(hex: "#252525")
			textView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
			textView.add(to: contentView, activate: [
				textView.topAnchor.constraint(equalTo: commentsHeadline.bottomAnchor, constant: 8),
				textView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
				textView.widthAnchor.constraint(equalTo: mapView.widthAnchor)
			])
		}

		// WorldMaps Headline
		worldMapsHeadline.font = .systemFont(ofSize: 18, weight: .bold)
		worldMapsHeadline.text = "WorldMaps"
		worldMapsHeadline.textColor = .white

		if let textView = textView {
			worldMapsHeadline.add(to: contentView, activate: [
				worldMapsHeadline.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 24),
				worldMapsHeadline.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16)
			])
		} else {
			worldMapsHeadline.add(to: contentView, activate: [
				worldMapsHeadline.topAnchor.constraint(equalTo: adHocSessionButton.bottomAnchor, constant: 24),
				worldMapsHeadline.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16)
			])
		}

		// WorldMaps Table View
		worldMapsTableView.isScrollEnabled = false
		worldMapsTableView.dataSource = self
		worldMapsTableView.delegate = self
		worldMapsTableView.register(WorldMapsTableViewCell.self, forCellReuseIdentifier: NSStringFromClass(WorldMapsTableViewCell.self))

		worldMapsTableView.add(to: contentView, activate: [
			worldMapsTableView.topAnchor.constraint(equalTo: worldMapsHeadline.bottomAnchor, constant: 8),
			worldMapsTableView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
			worldMapsTableView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
			tableViewHeightConstraint,
			worldMapsTableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
		])
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		portal.loadLocalWorldMaps()
		worldMapsTableView.reloadData()
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		view.setNeedsLayout()
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		scrollView.contentSize = CGSize(width: view.bounds.width, height: contentHeight)
		tableViewHeightConstraint.constant = worldMapsTableView.contentSize.height
		view.setNeedsUpdateConstraints()
	}

	@objc
	private func didTapCreateNew() {
		createLocalMap()
	}
	
	@objc
    private func startAdHocSession() {
        guard
			let navController: UINavigationController = navigationController
		else {
			print("Error: No microStory found")
			return
		}
		let portalSessionVC = PortalSessionViewController(at: portal, preselectedWorldMap: nil, options: [.isReadOnly, .isAdHocSession])

        navController.pushViewController(portalSessionVC, animated: true)
    }
	
	public func createLocalMap(with worldMapToCopy: ARWorldMap? = nil) {
		let alert = UIAlertController(title: "WorldMap Title", message: "", preferredStyle: .alert)

		alert.addTextField(configurationHandler: { textfield in
			textfield.placeholder = "Name"
			textfield.keyboardType = .default
		})

		let saveAction: UIAlertAction = UIAlertAction(title: "Save", style: .default) { [weak self] (_) -> Void in
			guard let self = self else { return }

			let worldMap = LocalWorldMap(title: alert.textFields?.first?.text ?? "", isInitialWorldMapPresent: worldMapToCopy != nil, portalID: self.portal.id)
			if let map = worldMapToCopy { worldMap.save(map: map) }
			StoredData.shared.add(localWorldMap: worldMap)
			self.portal.loadLocalWorldMaps()

			self.worldMapsTableView.reloadData()
			
			let worldMapVC = WorldMapDetailsViewController(with: worldMap, at: self.portal, createCopyAction: self.createLocalMap(with:))
			self.navigationController?.pushViewController(worldMapVC, animated: true)
		}

		let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
		alert.addAction(saveAction)
		alert.addAction(cancelAction)

		present(alert, animated: true)
	}
}

// MARK: - UITableViewDelegate & UITableViewDataSource

extension PortalDetailsViewController {
	func numberOfSections(in tableView: UITableView) -> Int {
		return 2
	}

	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		switch section {
		case 0:
			return "Heruntergeladen"
		case 1:
			return "Lokal"
		default:
			return ""
		}
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return section == 0 ? fetchedWorldMaps.count : localWorldMaps.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell: WorldMapsTableViewCell = worldMapsTableView.dequeueReusableCell(withIdentifier: NSStringFromClass(WorldMapsTableViewCell.self), for: indexPath) as? WorldMapsTableViewCell
			else { return WorldMapsTableViewCell() }

		if
			let worldMaps: [WorldMap] = indexPath.section == 0 ? fetchedWorldMaps : localWorldMaps,
			let worldMap = worldMaps[safe: indexPath.row]
		{
			cell.textLabel?.text = worldMap.displayTitle
			
			var detailText = "\((Double(worldMap.fileSize ?? 0)/1_024/1_024).friendlyString(1)) MB"
			if let title = (worldMap as? CFWorldMap)?.title { detailText += " »\(title)«" }
			cell.detailTextLabel?.text = detailText
		}
		
		
		return cell
	}

	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 70
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard let navController: UINavigationController = navigationController else { return }

		switch indexPath.section {
		case 0:
			let map: CFWorldMap = fetchedWorldMaps[indexPath.row]
			let worldMapVC = WorldMapDetailsViewController(with: map, at: portal, createCopyAction: createLocalMap(with:))
			navController.pushViewController(worldMapVC, animated: true)
		case 1:
			let map: LocalWorldMap = localWorldMaps[indexPath.row]
			let worldMapVC = WorldMapDetailsViewController(with: map, at: portal, createCopyAction: createLocalMap(with:))
			navController.pushViewController(worldMapVC, animated: true)
		default:
			break
		}
	}
	
	func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		// Section »Fetched WorldMaps« has no Delete functionality
		return indexPath.section != 0
	}
	
	func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
		if editingStyle == .delete {
			let alert = UIAlertController(title: "Confirm Deletion", message: "Are you sure you want to delete local WorldMap?", preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { (_) in
				self.portal.removeLocalWorldMap(at: indexPath.row)
				tableView.reloadData()
			})
			alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
			presentPopover(alert, from: view, animated: true)
		}
	}

	// MARK: MKMapViewDelegate

	func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
		if let pharusAnnotation = annotation as? PortalAnnotation {
			return PortalPin(annotation: pharusAnnotation)
		}
		return nil
	}
}

// MARK: - Table View Cell

class WorldMapsTableViewCell: UITableViewCell {
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
