import Foundation
import CoreLocation
import ARKit

enum DistanceSettings: Int {
	case off
	case exact
	case rough
	case percentage
}

enum CoolOffSettings: Int {
	case off
	case time
	case distance
}

enum CoolOffStatus: Int {
	 case locked
	 case unlockPossible
	 case unlocked
}

class AppSettings {
	public static var enterSessionDistanceInMeters: Double = 10
	public static var exitSessionDistanceInMeters: Double = 20
	public static var distanceSettings: DistanceSettings = .exact
	public static var coolOffSettings: CoolOffSettings = .off
}

extension UserDefaults {
	enum AppKey: String {
		case assetsUpdateTimestamp
		case gameStateInventoryItems
		case gameStateArchivedItems
		case gameStateCollectionItems
		case gameStateVisitedPortals
		case gameStatePharusPinnedPortals
	}
	
	func value(forAppKey key: AppKey) -> Any? {
		return value(forKey: key.rawValue)
	}
	func setValue(_ value: Any?, forAppKey key: AppKey) {
		setValue(value, forKey: key.rawValue)
	}

	func date(forAppKey key: AppKey) -> Date? {
		return value(forKey: key.rawValue) as? Date
	}
}
