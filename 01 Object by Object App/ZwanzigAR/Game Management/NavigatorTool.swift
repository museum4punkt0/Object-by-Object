import UIKit


enum NavigationToolTypeString: String {
	case none
	case compass
	case pharusPin
	case clueObject
}

enum NavigationTool: Equatable {
	case compass
	case pharusPin
	case clueObject(ClueObject)

	var typeString: NavigationToolTypeString {
		switch self {
		case .compass: return .compass
		case .pharusPin: return .pharusPin
		case .clueObject(_): return .clueObject
		}
	}
	
	var buttonImage: UIImage? {
		switch self {
		case .pharusPin:
			return UIImage(named: "btn_pharus")
		case .compass:
			return UIImage(named: "btn_compass")
		case .clueObject(_):
			return UIImage(named: "btn_clue")
		}
	}

	var color: UIColor {
		switch self {
		case .pharusPin:
			return .pharusPinColor
		case .compass:
			return .compassColor
		case .clueObject:
			return .clueObjectColor
		}
	}
}
