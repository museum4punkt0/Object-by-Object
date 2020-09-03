import UIKit
import CoreLocation

class CoolOffTimerViewController: UIViewController, CLLocationManagerDelegate {
	private var coolOffSettings: CoolOffSettings = AppSettings.coolOffSettings
	private var coolOffTime: Int // Timeframe that navigation stays locked
	private var presentationTime: Int // Timeframe that navigation is shown
	private var coolOffDistance: Int // Distance to travel to unlock nav again
	private var status: CoolOffStatus = .unlockPossible {
		didSet {
			NotificationCenter.default.post(name: Notification.Name("CoolOffStatusUpdated"), object: status, userInfo: nil)
			setupView()
		}
	}
	private var seconds: Int = 0
	private var isRunning: Bool = false
	private var timer = Timer()
	private var distanceTravelled: Int = 0 {
		didSet {
			if distanceTravelled >= coolOffDistance { updateStatus() }
		}
	}

	private let locationManager = CLLocationManager()
	private var startLocation: CLLocation?
	private var currentLocation: CLLocation? {
		didSet {
			guard let startLocation = startLocation, let currentDistance = currentLocation?.distance(from: startLocation)  else { return }
			distanceTravelled = Int(currentDistance)
			distanceLabel.text = "\(distanceTravelled)/\(coolOffDistance) m"
		}
	}

	private let unlockBtn = UIButton()
	private let timeLabel = UILabel()
	private let titleLabel = UILabel()
	private let distanceLabel = UILabel()

	init(coolOffDistance: Int, coolOffTime: Int, presentationTime: Int) {
		self.coolOffTime = coolOffTime
		self.presentationTime = presentationTime
		self.coolOffDistance = coolOffDistance
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		locationManager.delegate = self
		locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
		locationManager.startUpdatingLocation()

		unlockBtn.setTitle("Unlock", for: .normal)
		unlockBtn.addTarget(self, action: #selector(unlockPressed), for: .touchUpInside)
		unlockBtn.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(unlockBtn)
		unlockBtn.isHidden = true

		NSLayoutConstraint.activate([
			unlockBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			unlockBtn.centerYAnchor.constraint(equalTo: view.centerYAnchor)
		])

		titleLabel.font = .systemFont(ofSize: 18.0, weight: .regular)
		titleLabel.textAlignment = .center
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(titleLabel)
		titleLabel.isHidden = true

		timeLabel.font = .systemFont(ofSize: 18.0, weight: .regular)
		timeLabel.textAlignment = .center
		timeLabel.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(timeLabel)
		timeLabel.isHidden = true

		distanceLabel.font = .systemFont(ofSize: 18.0, weight: .regular)
		distanceLabel.textAlignment = .center
		distanceLabel.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(distanceLabel)
		distanceLabel.isHidden = true

		NSLayoutConstraint.activate([
			titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 32.0),
			timeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			timeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8.0),
			distanceLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			distanceLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8.0)
		])

		setupView()
	}

	private func setupView() {
		switch status {
		case .locked:
			switch coolOffSettings {
			case .distance:
				timeLabel.isHidden = true
				distanceLabel.isHidden = false

				distanceTravelled = 0

				titleLabel.text = "Distance to travel until unlock"
				distanceLabel.text = "\(distanceTravelled)/\(coolOffDistance) m"
			case .time:
				timeLabel.isHidden = false
				distanceLabel.isHidden = true

				seconds = coolOffTime
				startTimer()

				titleLabel.text = "Time until unlock"
				timeLabel.text = "\(seconds) sec"
			case .off:
				break
			}
		case .unlockPossible:
			unlockBtn.isHidden = false
			titleLabel.isHidden = true
			timeLabel.isHidden = true
			distanceLabel.isHidden = true
		case .unlocked:
			unlockBtn.isHidden = true
			titleLabel.isHidden = false
			timeLabel.isHidden = false
			distanceLabel.isHidden = true

			seconds = presentationTime
			startTimer()

			titleLabel.text = "Time until lock"
			timeLabel.text = "\(seconds) sec"
		}
	}

	@objc
	private func unlockPressed() {
		status = .unlocked
	}

	private func startTimer() {
		timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(runTimer), userInfo: nil, repeats: true)
		isRunning = true
	}

	@objc
	private func runTimer() {
		if seconds > 0 {
			seconds -= 1
			timeLabel.text = "\(seconds) sec"
		} else {
			timer.invalidate()
			isRunning = false
			updateStatus()
		}
	}

	private func updateStatus() {
		switch status {
		case .locked:
			status = .unlockPossible
			startLocation = nil
		case .unlockPossible:
			status = .unlocked
		case .unlocked:
			status = .locked
			startLocation = currentLocation
		}
	}
}

// MARK: CoreLocation Management
extension CoolOffTimerViewController {
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		guard let latestLocation = locations.last else { return }
		currentLocation = latestLocation
	}

	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
	  print("⚠️ Error while updating location " + error.localizedDescription)
	}
}
