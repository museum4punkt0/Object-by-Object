//
//  PortalSelectionTableViewController.swift
//  PortalEditor
//
//  Created by Ekkehard Petzold on 26.05.20.
//  Copyright © 2020 Ekkehard Petzold. All rights reserved.
//

import UIKit
import CoreLocation

class PortalSelectionTableViewController: UITableViewController, PortalsDisplay {

	private let locationManager: CLLocationManager = CLLocationManager()
	public var currentLocation: CLLocation? {
		didSet {
			tableView.reloadData()
		}
	}

	private var stories: [CFStory] {
		return Array(ContentfulManager.shared.stories.sorted(by: { $0.key < $1.key }).map({ $0.1 }))
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
		
		navigationItem.title = "Portale"
		
		locationManager.requestWhenInUseAuthorization()
		if CLLocationManager.locationServicesEnabled() {
			locationManager.delegate = self
			locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
			locationManager.startUpdatingLocation()
		}

		tableView.register(PortalTableViewCell.self, forCellReuseIdentifier: PortalTableViewCell.reuseID)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
		return stories.count
    }

	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return stories[safe: section]?.title
	}
	
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return stories[safe: section]?.portals?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PortalTableViewCell.reuseID, for: indexPath)

		guard
			let portal = stories[safe: indexPath.section]?.portals?[safe: indexPath.row],
			let location = portal.location
		else {
				return PortalTableViewCell()
		}

		cell.textLabel?.text = portal.title

		if let currentLocation = currentLocation {
			let distance = currentLocation.distance(from: CLLocation(latitude: location.latitude, longitude: location.longitude))
			if distance < 1000 {
				cell.detailTextLabel?.text = "\(String(format: "%.0f", distance)) m"
			}
			else {
				cell.detailTextLabel?.text = "\(String(format: "%.1f", (distance/1000))) km"
			}
		}

		return cell
    }
 
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard let portal = stories[safe: indexPath.section]?.portals?[safe: indexPath.row] else { return }
		navigationController?.pushViewController(PortalDetailsViewController(portal: portal), animated: true)
	}

	// MARK: PortalsDisplay

	public func finishedFetchingPortals() {
		tableView.reloadData()
	}

}

// MARK: - CLLocationManagerDelegate

extension PortalSelectionTableViewController: CLLocationManagerDelegate {
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		if let location = manager.location {
			currentLocation = location
		}
	}
}

// MARK: - Table View Cell

class PortalTableViewCell: UITableViewCell {
	public static let reuseID = String(describing: PortalTableViewCell.self)
	
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: .subtitle, reuseIdentifier: PortalTableViewCell.reuseID)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
