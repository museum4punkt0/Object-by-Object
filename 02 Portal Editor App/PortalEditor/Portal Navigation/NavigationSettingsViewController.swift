import UIKit
import CoreLocation
import ARKit

class NavigationSettingsViewController: UIViewController  {
	private let portal: CFPortal
	private let preselectedWorldMap: WorldMap?

	private let enterDistanceLabel = UILabel()
    private let exitDistanceLabel = UILabel()
    
    private var enterScanningDistance = AppSettings.enterSessionDistanceInMeters
	private var exitScanningDistance = AppSettings.exitSessionDistanceInMeters
	private var distanceSettings: DistanceSettings = AppSettings.distanceSettings
	private var coolOffSettings: CoolOffSettings = AppSettings.coolOffSettings
	
	private var options = [PortalSessionViewController.Options]()

	init(portal: CFPortal, preselectedWorldMap: WorldMap? = nil) {
		self.portal = portal
		self.preselectedWorldMap = preselectedWorldMap
		super.init(nibName: nil, bundle: nil)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		view.backgroundColor = .systemBlue

		navigationItem.title = "Settings"

		enterDistanceLabel.text = "EnterDistance: \(enterScanningDistance)m"
		enterDistanceLabel.font = .systemFont(ofSize: 18.0, weight: .regular)
		enterDistanceLabel.textAlignment = .left
		enterDistanceLabel.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(enterDistanceLabel)

		let enterDistanceSlider = UISlider()
		enterDistanceSlider.minimumValue = 0
		enterDistanceSlider.maximumValue = 30
		enterDistanceSlider.isContinuous = true
		enterDistanceSlider.tintColor = .systemBlue
		enterDistanceSlider.value = Float(enterScanningDistance)
		enterDistanceSlider.addTarget(self, action: #selector(enterDistanceSliderDidChange), for: .valueChanged)
		enterDistanceSlider.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(enterDistanceSlider)

		exitDistanceLabel.text = "ExitDistance: \(exitScanningDistance)m"
		exitDistanceLabel.font = .systemFont(ofSize: 18.0, weight: .regular)
		exitDistanceLabel.textAlignment = .left
		exitDistanceLabel.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(exitDistanceLabel)

		let exitDistanceSlider = UISlider()
		exitDistanceSlider.minimumValue = 0
		exitDistanceSlider.maximumValue = 30
		exitDistanceSlider.isContinuous = true
		exitDistanceSlider.tintColor = .systemBlue
		exitDistanceSlider.value = Float(enterScanningDistance)
		exitDistanceSlider.addTarget(self, action: #selector(exitDistanceSliderDidChange), for: .valueChanged)
		exitDistanceSlider.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(exitDistanceSlider)

		let distanceOptionsTitle = UILabel()
		distanceOptionsTitle.text = "Distance Options:"
		distanceOptionsTitle.font = .systemFont(ofSize: 18.0, weight: .regular)
		distanceOptionsTitle.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(distanceOptionsTitle)

		let distanceOptions = ["Off", "Exact", "Rough", "%"]
		let distanceControl = UISegmentedControl(items: distanceOptions)
		distanceControl.addTarget(self, action: #selector(changeDistanceSettings), for: .valueChanged)
		distanceControl.selectedSegmentIndex = distanceSettings.rawValue
		distanceControl.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(distanceControl)

		let coolOffTitle = UILabel()
		coolOffTitle.text = "Cool-Off Timer"
		coolOffTitle.font = .systemFont(ofSize: 18.0, weight: .regular)
		coolOffTitle.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(coolOffTitle)

		let coolOffOptions = ["Off", "Time", "Distance"]
		let coolOffControl = UISegmentedControl(items: coolOffOptions)
		coolOffControl.addTarget(self, action: #selector(changeCoolOffSettings), for: .valueChanged)
		coolOffControl.selectedSegmentIndex = coolOffSettings.rawValue
		coolOffControl.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(coolOffControl)

		let debuggingHelperTitle = UILabel()
		debuggingHelperTitle.text = "Show Debugging View"
		debuggingHelperTitle.font = .systemFont(ofSize: 18.0, weight: .regular)
		debuggingHelperTitle.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(debuggingHelperTitle)

		let debuggingHelperControl = UISegmentedControl(items:  ["Off", "On"])
		debuggingHelperControl.addTarget(self, action: #selector(setDebuggingHelperSetting), for: .valueChanged)
		debuggingHelperControl.selectedSegmentIndex = 0
		debuggingHelperControl.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(debuggingHelperControl)


		let startBtn = UIButton(type: .custom)
		startBtn.setTitle("Start", for: .normal)
		startBtn.addTarget(self, action: #selector(didTapStart), for: .touchUpInside)
		startBtn.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(startBtn)

		NSLayoutConstraint.activate([
			enterDistanceLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            enterDistanceLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24.0),

			enterDistanceSlider.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			enterDistanceSlider.widthAnchor.constraint(equalToConstant: 200.0),
			enterDistanceSlider.topAnchor.constraint(equalTo: enterDistanceLabel.bottomAnchor, constant: 8.0),

			exitDistanceLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			exitDistanceLabel.topAnchor.constraint(equalTo: enterDistanceSlider.bottomAnchor, constant: 24.0),

			exitDistanceSlider.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			exitDistanceSlider.widthAnchor.constraint(equalToConstant: 200.0),
			exitDistanceSlider.topAnchor.constraint(equalTo: exitDistanceLabel.bottomAnchor, constant: 8.0),

			distanceOptionsTitle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			distanceOptionsTitle.topAnchor.constraint(equalTo: exitDistanceSlider.bottomAnchor, constant: 24.0),

			distanceControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			distanceControl.topAnchor.constraint(equalTo: distanceOptionsTitle.bottomAnchor, constant: 8.0),

			coolOffTitle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
 			coolOffTitle.topAnchor.constraint(equalTo: distanceControl.bottomAnchor, constant: 24.0),

			coolOffControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			coolOffControl.topAnchor.constraint(equalTo: coolOffTitle.bottomAnchor, constant: 8.0),

			debuggingHelperTitle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			debuggingHelperTitle.topAnchor.constraint(equalTo: coolOffControl.bottomAnchor, constant: 24.0),

			debuggingHelperControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			debuggingHelperControl.topAnchor.constraint(equalTo: debuggingHelperTitle.bottomAnchor, constant: 8.0),

			startBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			startBtn.topAnchor.constraint(equalTo: debuggingHelperControl.bottomAnchor, constant: 24.0)
		])
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		navigationController?.setNavigationBarHidden(false, animated: true)
	}
	
	@objc
	private func didTapStart() {
		AppSettings.enterSessionDistanceInMeters = enterScanningDistance
		AppSettings.exitSessionDistanceInMeters = exitScanningDistance
		AppSettings.distanceSettings = distanceSettings
		AppSettings.coolOffSettings = coolOffSettings

		let compassNavigationVC = CompassNavigationViewController(portal: portal, preselectedWorldMap: preselectedWorldMap)
		
		navigationController?.pushViewController(compassNavigationVC, animated: true)
	}

	@objc
	private func enterDistanceSliderDidChange(sender: UISlider) {
		let value: Float = round(sender.value)
		enterDistanceLabel.text = "EnterDistance: \(value)m"
		enterScanningDistance = Double(value)
	}

	@objc
	private func exitDistanceSliderDidChange(sender: UISlider) {
		let value: Float = round(sender.value)
		exitDistanceLabel.text = "ExitDistance: \(value)m"
		exitScanningDistance = Double(value)
	}

	@objc
	private func changeDistanceSettings(sender: UISegmentedControl) {
		switch sender.selectedSegmentIndex {
		case 0:
			distanceSettings = .off
		case 1:
			distanceSettings = .exact
		case 2:
			distanceSettings = .rough
		case 3:
			distanceSettings = .percentage
		default:
			print("WARNING: unrecognized control selected")
		}
	}

	@objc
	private func changeCoolOffSettings(sender: UISegmentedControl) {
		switch sender.selectedSegmentIndex {
		case 0:
			coolOffSettings = .off
		case 1:
			coolOffSettings = .time
		case 2:
			coolOffSettings = .distance
		default:
			print("Warning: unrecognized cool off settings")
		}
	}

	@objc
	private func setDebuggingHelperSetting(sender: UISegmentedControl) {
		for i in 0..<options.count {
			if options[i] == .showDebuggingHelper {
				options.remove(at: i)
			}
		}
		
		if sender.selectedSegmentIndex == 1 {
			options.append(.showDebuggingHelper)
		}
	}
}

