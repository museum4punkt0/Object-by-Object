//
//  ContentfulUpdateViewController.swift
//  PortalEditor
//
//  Created by Ekkehard Petzold on 18.03.20.
//  Copyright © 2020 Ekkehard Petzold. All rights reserved.
//

import UIKit

class ContentfulUpdateViewController: UIViewController {

	let cs = CGSize(width: 300, height: 100)
	let lHeight = CGFloat(80)
	let bHeight = CGFloat(10)
	
	var sizes = [Int]()
	var pointer = 0
	var downloadTotal: Int { self.sizes.reduce(0, +) }
	var downloadCurrent: Int { self.sizes[0..<min(self.pointer, self.sizes.count)].reduce(0, +) }
	
	let label = UILabel()
	var labelText: String { "Updating Assets\n\n\((Float(downloadCurrent)/1_024/1_024).friendlyString(1))/\((Float(downloadTotal)/1_024/1_024).friendlyString(1)) MB (\(sizes.count-pointer) files left)" }
	let progressBar = UIView()
	let resourcesActivityIndicator = UIActivityIndicatorView()
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		view.backgroundColor = .asset(.dark)
		
		let container = UIView()
		container.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(container)
		
		label.frame = CGRect(x: 0, y: 0, width: cs.width, height: lHeight)
		label.font = .systemFont(ofSize: 15)
		label.textColor = .asset(.champagne)
		label.textAlignment = .center
		label.numberOfLines = 0
		label.text = "Fetching resources …"
		container.addSubview(label)
		
		let progressBarContainer = UIView(frame: CGRect(x: 0, y: lHeight, width: cs.width, height: bHeight))
		progressBarContainer.addCornerRadius()
		progressBarContainer.backgroundColor = .system(.systemGray6)
		progressBarContainer.alpha = 0
		container.addSubview(progressBarContainer)
		
		progressBar.frame = CGRect(x: 0, y: 0, width: 0, height: progressBarContainer.frame.size.height)
		progressBar.backgroundColor = .asset(.active)
		progressBarContainer.addSubview(progressBar)
		
		container.addSubview(resourcesActivityIndicator)
		resourcesActivityIndicator.center = CGPoint(x: 0.5 * cs.width, y: 0.9 * cs.height)
		resourcesActivityIndicator.startAnimating()
		resourcesActivityIndicator.style = .large
		
		NSLayoutConstraint.activate(
			container.layoutConstraints(with: view, to: [.centerX, .centerY, .width(cs.width), .height(cs.height)])
		)
	}

	func startedFetchingAssetFiles(sizes: [Int]) -> Void {
		DispatchQueue.main.async {
			self.resourcesActivityIndicator.stopAnimating()

			guard sizes.count > 0 else {
				self.dismiss(animated: true)
				return
			}

			UIView.animate(withDuration: 0.2, animations: {
				self.progressBar.superview?.alpha = 1
			}) { (_) in
				self.sizes = sizes
				self.label.text = self.labelText
			}
		}
	}
	
	func finishedFetchingAssetFile() -> Void {
		DispatchQueue.main.async {
			self.pointer += 1
			self.label.text = self.labelText
			
			UIView.animate(withDuration: 0.2, animations: {
				self.progressBar.frame.size.width = CGFloat(self.downloadCurrent)/CGFloat(max(self.downloadTotal, 1)) * self.cs.width
			}) { (_) in
				if self.pointer >= self.sizes.count {
					self.dismiss(animated: true)
				}
			}
		}
	}
}
