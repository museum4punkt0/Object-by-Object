//
//  Primitives.swift
//  ZwanzigAR
//
//  Created by Ekkehard Petzold on 27.05.20.
//  Copyright © 2020 Jan Alexander. All rights reserved.
//

import UIKit

// MARK: -

extension Float {
	var degreesToRadians: Float { return self * .pi / 180 }
	var radiansToDegrees: Float { return self * 180 / .pi }

	func friendlyString(_ digits: UInt = 2) -> String {
		return CGFloat(self).friendlyString(digits)
	}
}

// MARK: -

extension Double {
	var degreesToRadians: Double { return Double(CGFloat(self).degreesToRadians) }
	var radiansToDegrees: Double { return Double(CGFloat(self).radiansToDegrees) }

	func friendlyString(_ digits: UInt = 2) -> String {
		return CGFloat(self).friendlyString(digits)
	}
}

// MARK: -

extension CGFloat {
	var degreesToRadians: CGFloat { return self * .pi / 180 }
	var radiansToDegrees: CGFloat { return self * 180 / .pi }

	func friendlyString(_ digits: UInt = 2) -> String {
		return "\(String(format: "%.\(digits)f", self))"
	}
}

// MARK: -

extension Date {
	public enum TimeStampStyle: String, CaseIterable {
		case display = "yy.MM.dd HH:mm:ss"
		case filename = "yyMMddHHmmss"
	}
	
	public func string(style: TimeStampStyle) -> String {
		let formatter = DateFormatter()
		formatter.dateFormat = style.rawValue
		return formatter.string(from: self)
	}
	
	public static func date(from string: String) -> Date? {
		for style in TimeStampStyle.allCases {
			let dateFormatter = DateFormatter()
//			dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
			dateFormatter.dateFormat = style.rawValue
			if let date = dateFormatter.date(from: string) { return date }
		}
		return nil
	}
}

