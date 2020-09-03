import Foundation

extension UserDefaults {
	enum AppKey: String {
		case resourcesLastUpdate
		case resourcesJSON
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
