//
//  Geometry 2D.swift
//  ZwanzigAR
//
//  Created by Ekkehard Petzold on 27.05.20.
//  Copyright © 2020 Jan Alexander. All rights reserved.
//

import ARKit

// MARK: -

extension CGPoint {
	init(_ size: CGSize) {
		self.init()
		self.x = size.width
		self.y = size.height
	}

	init(_ vector: SCNVector3) {
		self.init()
		self.x = CGFloat(vector.x)
		self.y = CGFloat(vector.y)
	}

	func distanceTo(_ point: CGPoint) -> CGFloat {
		return (self - point).length()
	}

	func length() -> CGFloat {
		return sqrt(self.x * self.x + self.y * self.y)
	}

	func midpoint(_ point: CGPoint) -> CGPoint {
		return (self + point) / 2
	}

	func friendlyString(_ digits: UInt = 2) -> String {
		return "(\(String(format: "%.\(digits)f", x)), \(String(format: "%.\(digits)f", y)))"
	}
    
    static func onCircle(origin: CGPoint, radius: CGFloat, angle: CGFloat) -> CGPoint {
        let adjustedAngle = angle + 0.5 * .pi // rotate counter-clockwise by half.PI, so that zero degree angle represents (x: 0, y: 1)
        let x = origin.x + radius * cos(adjustedAngle)
        let y = origin.y + radius * sin(adjustedAngle)
        return CGPoint(x: x, y: y)
    }
}

func + (left: CGPoint, right: CGPoint) -> CGPoint {
	return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
	return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func += (left: inout CGPoint, right: CGPoint) {
	left = left + right
}

func -= (left: inout CGPoint, right: CGPoint) {
	left = left - right
}

func / (left: CGPoint, right: CGFloat) -> CGPoint {
	return CGPoint(x: left.x / right, y: left.y / right)
}

func * (left: CGPoint, right: CGFloat) -> CGPoint {
	return CGPoint(x: left.x * right, y: left.y * right)
}

func /= (left: inout CGPoint, right: CGFloat) {
	left = left / right
}

func *= (left: inout CGPoint, right: CGFloat) {
	left = left * right
}


// MARK: -

extension CGSize {
	var mid: CGPoint {
		return CGRect(origin: .zero, size: self).mid
	}
	
	init(_ point: CGPoint) {
		self.init()
		self.width = point.x
		self.height = point.y
	}

	func friendlyString(_ digits: UInt = 2) -> String {
		return "(\(String(format: "%.\(digits)f", width)), \(String(format: "%.\(digits)f", height)))"
	}
	
    func aspectFit(_ aspectRatio: CGSize) -> CGSize {
        let mW = width / aspectRatio.width
        let mH = height / aspectRatio.height

		var boundingSize = self
        if (mH < mW) {
            boundingSize.width = height / aspectRatio.height * aspectRatio.width
        }
        else if (mW < mH) {
            boundingSize.height = width / aspectRatio.width * aspectRatio.height
        }
        
        return boundingSize
    }
    
    func aspectFill(_ aspectRatio: CGSize) -> CGSize {
        let mW = width / aspectRatio.width
        let mH = height / aspectRatio.height

        var minimumSize = self
		if (mH > mW) {
            minimumSize.width = height / aspectRatio.height * aspectRatio.width
        }
        else if (mW > mH) {
            minimumSize.height = width / aspectRatio.width * aspectRatio.height
        }
        
        return minimumSize
    }
}

func + (left: CGSize, right: CGSize) -> CGSize {
	return CGSize(width: left.width + right.width, height: left.height + right.height)
}

func - (left: CGSize, right: CGSize) -> CGSize {
	return CGSize(width: left.width - right.width, height: left.height - right.height)
}

func += (left: inout CGSize, right: CGSize) {
	left = left + right
}

func -= (left: inout CGSize, right: CGSize) {
	left = left - right
}

func / (left: CGSize, right: CGFloat) -> CGSize {
	return CGSize(width: left.width / right, height: left.height / right)
}

func * (left: CGSize, right: CGFloat) -> CGSize {
	return CGSize(width: left.width * right, height: left.height * right)
}

func /= (left: inout CGSize, right: CGFloat) {
	left = left / right
}

func *= (left: inout CGSize, right: CGFloat) {
	left = left * right
}



// MARK: -

extension CGRect {
	var mid: CGPoint {
		return CGPoint(x: midX, y: midY)
	}
}


