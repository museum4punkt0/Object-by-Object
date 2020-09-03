//
//  Collections.swift
//  ZwanzigAR
//
//  Created by Ekkehard Petzold on 27.05.20.
//  Copyright © 2020 Jan Alexander. All rights reserved.
//

import ARKit

extension Collection {
	// USAGE:
	// array[safe: i] -> returns nil if out of bounds
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension RangeReplaceableCollection {
	mutating func keepLast(_ elementsToKeep: Int) {
		if count > elementsToKeep {
			self.removeFirst(count - elementsToKeep)
		}
	}
}

extension Array where Iterator.Element == CGFloat {
	var average: CGFloat? {
		guard !isEmpty else {
			return nil
		}

		var ret = self.reduce(CGFloat(0)) { (cur, next) -> CGFloat in
			var cur = cur
			cur += next
			return cur
		}
		let fcount = CGFloat(count)
		ret /= fcount
		return ret
	}
}

extension Array where Iterator.Element == SCNVector3 {
	var average: SCNVector3? {
		guard !isEmpty else {
			return nil
		}

		var ret = self.reduce(SCNVector3Zero) { (cur, next) -> SCNVector3 in
			var cur = cur
			cur.x += next.x
			cur.y += next.y
			cur.z += next.z
			return cur
		}
		let fcount = Float(count)
		ret.x /= fcount
		ret.y /= fcount
		ret.z /= fcount

		return ret
	}
}
