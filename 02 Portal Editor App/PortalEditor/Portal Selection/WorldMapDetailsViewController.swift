import UIKit
import ARKit

class WorldMapDetailsViewController: UIViewController {
	private let fetchedMap: CFWorldMap?
	private let localMap: LocalWorldMap?
	private let origin: CFWorldMap.Origin
	private let portal: CFPortal

	private let startButton = UIButton(type: .custom)
	private let copyButton = UIButton(type: .custom)

	var createLocalCopyAction: (ARWorldMap) -> Void
    private var alignmentSetting: ARWorldTrackingConfiguration.PlaneDetection = [.horizontal, .vertical]
	private var options = [PortalSessionViewController.Options]()
	
	var isInitialWorldMapPresent: Bool {
		switch origin {
		case .fetched: return fetchedMap?.mapFile != nil
		case .local: return localMap?.arWorldMap != nil
		}
	}

	init(with fetchedMap: CFWorldMap, at portal: CFPortal, createCopyAction: @escaping (ARWorldMap) -> Void) {
		self.fetchedMap = fetchedMap
		self.localMap = nil
		self.origin = .fetched
		self.portal = portal
		self.createLocalCopyAction = createCopyAction
        self.alignmentSetting = []
		super.init(nibName: nil, bundle: nil)
	}

	init(with localMap: LocalWorldMap, at portal: CFPortal, createCopyAction: @escaping (ARWorldMap) -> Void) {
		self.localMap = localMap
		self.fetchedMap = nil
		self.origin = .local
		self.portal = portal
		self.createLocalCopyAction = createCopyAction
        self.alignmentSetting = [.horizontal, .vertical]
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		view.backgroundColor = .system(.systemBackground)

		switch origin {
		case .fetched:
			navigationItem.title = fetchedMap?.title
		case .local:
			navigationItem.title = localMap?.displayTitle
			navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareButtonPressed))
		}

		let showDebuggingTitle = UILabel()
		showDebuggingTitle.text = "Show Debugging Options"
		showDebuggingTitle.font = .systemFont(ofSize: 18.0, weight: .regular)
		showDebuggingTitle.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(showDebuggingTitle)

		let showDebuggingControl = UISegmentedControl(items: ["Off", "On"])
		showDebuggingControl.addTarget(self, action: #selector(setDebuggingHelperSetting), for: .valueChanged)
		showDebuggingControl.selectedSegmentIndex = 0
		showDebuggingControl.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(showDebuggingControl)
        
        let setAlignmentTitle = UILabel()
        setAlignmentTitle.text = "Set Aligment"
        setAlignmentTitle.font = .systemFont(ofSize: 18.0, weight: .regular)
        setAlignmentTitle.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(setAlignmentTitle)

        let setAlignmentControl = UISegmentedControl(items: ["Hori", "Verti", "Both", "None"])
        setAlignmentControl.addTarget(self, action: #selector(changeAlignmentSetting), for: .valueChanged)
        setAlignmentControl.selectedSegmentIndex = origin == .local ? 2 : 3
        setAlignmentControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(setAlignmentControl)

		let playButton = UIButton(type: .custom)
		playButton.setTitle("Play Session", for: .normal)
		playButton.setTitleColor(.systemBlue, for: .normal)
		playButton.addTarget(self, action: #selector(playSession), for: .touchUpInside)
		playButton.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(playButton)

		startButton.setTitleColor(.systemBlue, for: .normal)
		startButton.addTarget(self, action: #selector(startSession), for: .touchUpInside)
		startButton.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(startButton)

		copyButton.setTitle("Create Local Copy", for: .normal)
		copyButton.setTitleColor(.systemBlue, for: .normal)
		copyButton.addTarget(self, action: #selector(createLocalCopy), for: .touchUpInside)
		copyButton.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(copyButton)
        
        let subViews = [showDebuggingTitle, showDebuggingControl, playButton, startButton, setAlignmentTitle, setAlignmentControl, copyButton]

        NSLayoutConstraint.activate(
            subViews.flatMap{ $0.layoutConstraints(with: self.view, to: [.centerX]) } +
            [showDebuggingTitle.topAnchor.constraint(equalTo: view.topAnchor, constant: 100.0),
            showDebuggingControl.topAnchor.constraint(equalTo: showDebuggingTitle.bottomAnchor, constant: 24.0),
            setAlignmentTitle.topAnchor.constraint(equalTo: showDebuggingControl.bottomAnchor, constant: 24.0),
            setAlignmentControl.topAnchor.constraint(equalTo: setAlignmentTitle.bottomAnchor, constant: 24.0),
            playButton.topAnchor.constraint(equalTo: setAlignmentControl.bottomAnchor, constant: 24.0),
			startButton.topAnchor.constraint(equalTo: playButton.bottomAnchor, constant: 24.0),
            copyButton.topAnchor.constraint(equalTo: startButton.bottomAnchor, constant: 24.0),
        ])
        
		
		if let imageURL = portal.hintImage?.localURL {
			DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(10)) {
				HintView(imageURL: imageURL, addTo: self.view).set(visible: true)
			}
		}
	}

	override func viewWillAppear(_ animated: Bool) {
		if origin == .local {
			startButton.setTitle(isInitialWorldMapPresent ? "Edit Session" : "Create New Session", for: .normal)
		} else {
			startButton.isHidden = true
		}
		copyButton.isHidden = !isInitialWorldMapPresent
		
		navigationItem.rightBarButtonItem?.isEnabled = isInitialWorldMapPresent
	}
	
	@objc
	private func setDebuggingHelperSetting(_ sender: UISegmentedControl) {
		for i in 0..<options.count {
			if options[i] == .showDebuggingHelper {
				options.remove(at: i)
			}
		}
		
		if sender.selectedSegmentIndex == 1 {
			options.append(.showDebuggingHelper)
		}
	}
    
    @objc
    private func changeAlignmentSetting(_ sender: UISegmentedControl) {
        let index = sender.selectedSegmentIndex
        if index == 0 {
            alignmentSetting = .horizontal
        } else if index == 1 {
            alignmentSetting = .vertical
        } else if index == 2 {
            alignmentSetting = [.horizontal, .vertical]
        } else if index == 3 {
            alignmentSetting = []
        }
    }

	@objc
	private func createLocalCopy() {
		let startTime = Date()

		if let url = fetchedMap?.mapFile?.localURL {
			print("\(#function) – fetchedMap local URL: \(url.absoluteString)")
			if let data = try? Data(contentsOf: url) {
				print("\(#function) – fetchedMap local data size: \(data.count))")
			}
		}

		guard
			let url = fetchedMap?.mapFile?.localURL ?? localMap?.url,
			let data = try? Data(contentsOf: url),
			let worldMap = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? ARWorldMap
			else { return }

		print("\(#function) – url: \(url.absoluteString)")
		print("\(#function) – unarchiving took \(Date().timeIntervalSince(startTime).friendlyString())")
		navigationController?.popViewController(animated: true)
		createLocalCopyAction(worldMap)
	}
	
	@objc
	private func playSession() {
		guard
			let navController: UINavigationController = navigationController
		else { return }

		let portalSessionVC: PortalSessionViewController
		switch origin {
		case .fetched:
			guard let map = fetchedMap else { return }
			portalSessionVC = PortalSessionViewController(at: portal, preselectedWorldMap: map, options: options + [.isReadOnly, .showCoaching])
		case .local:
			guard let map = localMap else { return }
			portalSessionVC = PortalSessionViewController(at: portal, preselectedWorldMap: map, options: options + [.isReadOnly, .showCoaching])
		}
		
		navController.pushViewController(portalSessionVC, animated: true)

	}
	
	@objc
	private func startSession() {
		guard
			let navController: UINavigationController = navigationController
		else { return }

		let portalSessionVC: PortalSessionViewController
		switch origin {
		case .fetched:
			guard let map = fetchedMap else { return }
			portalSessionVC = PortalSessionViewController(at: portal, preselectedWorldMap: map, options: options + [.isReadOnly, .showStatistics, .planeDetection(alignmentSetting), .showCoaching])
		case .local:
			guard let map = localMap else { return }
			portalSessionVC = PortalSessionViewController(at: portal, preselectedWorldMap: map, options: options + [.showStatistics, .planeDetection(alignmentSetting), .showCoaching])
		}
		
		navController.pushViewController(portalSessionVC, animated: true)
	}
    
    @objc
    private func startCompassNavigation() {
		navigationController?.pushViewController(NavigationSettingsViewController(portal: portal, preselectedWorldMap: origin == .local ? localMap : fetchedMap), animated: true)
    }

	@objc
	private func shareButtonPressed(_ sender: UIBarButtonItem) {
		var mapURL: URL

		switch origin {
		case .fetched:
			print("Error – fetched world maps are not intended to be shared")
			return
		case .local:
			guard let map = localMap else { return }
			mapURL = map.url
		}

		let sharingDialog = UIActivityViewController.init(activityItems: [mapURL], applicationActivities: nil)
		sharingDialog.modalPresentationStyle = .popover
		sharingDialog.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
		sharingDialog.popoverPresentationController?.permittedArrowDirections = .up
		present(sharingDialog, animated: true)
	}
}
