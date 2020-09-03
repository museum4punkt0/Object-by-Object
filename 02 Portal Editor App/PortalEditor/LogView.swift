import UIKit
import ARKit

class LogView: UIView {
	public var mapTitle: String = "No map" {
		didSet {
			updateLabelText()
		}
	}
	public var mapStatus: ARFrame.WorldMappingStatus = .notAvailable {
		didSet {
			updateLabelText()
		}
	}
	public var mapSize: Int = 0 {
		didSet {
			updateLabelText()
		}
	}

	private let logLabel: UILabel = UILabel()
	private var mapStatusAsString: String {
		switch mapStatus {
		case .extending:
			return "extending"
		case .limited:
			return "limited"
		case .mapped:
			return "mapped"
		case .notAvailable:
			return "notAvailable"
		default:
			return "other"
		}
	}


	override init(frame: CGRect) {
		super.init(frame: frame)
		setup()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		print("Logview deallocated")
	}

	private func setup() {
		backgroundColor = UIColor(white: 0.0, alpha: 0.45)

		logLabel.textColor = .white
		logLabel.font = UIFont.monospacedSystemFont(ofSize: 12.0, weight: .bold)
		logLabel.numberOfLines = 0
		logLabel.lineBreakMode = .byWordWrapping
		logLabel.translatesAutoresizingMaskIntoConstraints = false
		addSubview(logLabel)

		updateLabelText()

		NSLayoutConstraint.activate([
			logLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
			logLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 16.0)
		])
	}

	private func updateLabelText() {
		logLabel.text = /*"Map: \(mapTitle), */"Status: \(mapStatusAsString), \((Double(mapSize)/(1_024*1_024)).friendlyString())MB"
	}
}
