//
//  Geometry 3D.swift
//  ZwanzigAR
//
//  Created by Ekkehard Petzold on 27.05.20.
//  Copyright © 2020 Jan Alexander. All rights reserved.
//

import ARKit

public extension matrix_float4x4 {

/// Retrieve translation from a quaternion matrix
	var position: SCNVector3 {
		get {
			return SCNVector3Make(columns.3.x, columns.3.y, columns.3.z)
		}
	}
	
	/// Retrieve euler angles from a quaternion matrix
	var eulerAngles: SCNVector3 {
		get {
			//first we get the quaternion from m00...m22
			//see http://www.euclideanspace.com/maths/geometry/rotations/conversions/matrixToQuaternion/index.htm
			let qw = sqrt(1 + self.columns.0.x + self.columns.1.y + self.columns.2.z) / 2.0
			let qx = (self.columns.2.y - self.columns.1.z) / (qw * 4.0)
			let qy = (self.columns.0.z - self.columns.2.x) / (qw * 4.0)
			let qz = (self.columns.1.x - self.columns.0.y) / (qw * 4.0)
			
			//then we deduce euler angles with some cosines
			//see https://en.wikipedia.org/wiki/Conversion_between_quaternions_and_Euler_angles
			// roll (x-axis rotation)
			let sinr = +2.0 * (qw * qx + qy * qz)
			let cosr = +1.0 - 2.0 * (qx * qx + qy * qy)
			let roll = atan2(sinr, cosr)
			
			// pitch (y-axis rotation)
			let sinp = +2.0 * (qw * qy - qz * qx)
			var pitch: Float
			if abs(sinp) >= 1 {
				pitch = copysign(Float.pi / 2, sinp)
			} else {
				pitch = asin(sinp)
			}
			
			// yaw (z-axis rotation)
			let siny = +2.0 * (qw * qz + qx * qy)
			let cosy = +1.0 - 2.0 * (qy * qy + qz * qz)
			let yaw = atan2(siny, cosy)
			
			return SCNVector3(pitch, yaw, roll)
		}
	}
}

extension SCNMatrix4 {
	init(position: SCNVector3 = SCNVector3(uniform: 0), eulerAngles: SCNVector3 = SCNVector3(uniform: 0), scale: SCNVector3 = SCNVector3(uniform: 1)) {
		let node = SCNNode()
		node.position = position
		node.eulerAngles = eulerAngles
		node.scale = scale
		self = node.transform
	}
	
	var position: SCNVector3 {
		matrix_float4x4(self).position
	}
	
	var eulerAngles: SCNVector3 {
		matrix_float4x4(self).eulerAngles
	}
}

extension SCNVector3 {

	init(uniform: Float) {
		self.init()
		self.x = uniform
		self.y = uniform
		self.z = uniform
	}
	
	init(_ vec: vector_float3) {
		self.init()
		self.x = vec.x
		self.y = vec.y
		self.z = vec.z
	}

	static let zero = SCNVector3(uniform: 0)
	
	func length() -> Float {
		return sqrtf(x * x + y * y + z * z)
	}

	mutating func setLength(_ length: Float) {
		self.normalize()
		self *= length
	}

	mutating func setMaximumLength(_ maxLength: Float) {
		if self.length() <= maxLength {
			return
		} else {
			self.normalize()
			self *= maxLength
		}
	}

	mutating func normalize() {
		self = self.normalized()
	}

	func normalized() -> SCNVector3 {
		if self.length() == 0 {
			return self
		}

		return self / self.length()
	}

	static func positionFromTransform(_ transform: matrix_float4x4) -> SCNVector3 {
		return SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
	}
	
	static func positionFromTransform(_ transform: SCNMatrix4) -> SCNVector3 {
		return positionFromTransform(matrix_float4x4(transform))
	}

	func friendlyString(_ digits: UInt = 2) -> String {
		return "(\(String(format: "%.\(digits)f", x)), \(String(format: "%.\(digits)f", y)), \(String(format: "%.\(digits)f", z)))"
	}

	static func *(lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
		return SCNVector3(x: lhs.x*rhs.x, y: lhs.y*rhs.y, z: lhs.z*rhs.z)
	}

	func dot(_ vec: SCNVector3) -> Float {
		return (self.x * vec.x) + (self.y * vec.y) + (self.z * vec.z)
	}

	func cross(_ vec: SCNVector3) -> SCNVector3 {
		return SCNVector3(self.y * vec.z - self.z * vec.y, self.z * vec.x - self.x * vec.z, self.x * vec.y - self.y * vec.x)
	}
	
    static func onCircle(origin: SCNVector3, radius: Float, angle: Float) -> SCNVector3 {
        let adjustedAngle = angle + 0.5 * .pi // rotate counter-clockwise by half.PI, so that zero degree angle represents (x: 0, z: 1)
        let x = origin.x + radius * cos(adjustedAngle)
        let z = origin.z + radius * sin(adjustedAngle)
        return SCNVector3(x: x, y: origin.y,  z: z)
    }
	
	static func rayIntersectionWithHorizontalPlane(rayOrigin: SCNVector3, direction: SCNVector3, planeY: Float) -> SCNVector3? {
		let direction = direction.normalized()

		// Special case handling: Check if the ray is horizontal as well.
		if direction.y == 0 {
			if rayOrigin.y == planeY {
				// The ray is horizontal and on the plane, thus all points on the ray intersect with the plane.
				// Therefore we simply return the ray origin.
				return rayOrigin
			} else {
				// The ray is parallel to the plane and never intersects.
				return nil
			}
		}

		// The distance from the ray's origin to the intersection point on the plane is:
		//   (pointOnPlane - rayOrigin) dot planeNormal
		//  --------------------------------------------
		//          direction dot planeNormal

		// Since we know that horizontal planes have normal (0, 1, 0), we can simplify this to:
		let dist = (planeY - rayOrigin.y) / direction.y

		// Do not return intersections behind the ray's origin.
		if dist < 0 {
			return nil
		}

		// Return the intersection point.
		return rayOrigin + (direction * dist)
	}

}

extension float4x4 {
	init(_ matrix: SCNMatrix4) {
		self.init([
			float4(matrix.m11, matrix.m12, matrix.m13, matrix.m14),
			float4(matrix.m21, matrix.m22, matrix.m23, matrix.m24),
			float4(matrix.m31, matrix.m32, matrix.m33, matrix.m34),
			float4(matrix.m41, matrix.m42, matrix.m43, matrix.m44)
			])
	}
}

extension float4 {
	init(_ vector: SCNVector4) {
		self.init(vector.x, vector.y, vector.z, vector.w)
	}

	init(_ vector: SCNVector3) {
		self.init(vector.x, vector.y, vector.z, 1)
	}
}

extension SCNVector4 {
	init(_ vector: float4) {
		self.init(x: vector.x, y: vector.y, z: vector.z, w: vector.w)
	}
	
	init(_ vector: SCNVector3) {
		self.init(x: vector.x, y: vector.y, z: vector.z, w: 1)
	}
}

extension SCNVector3 {
	init(_ vector: float4) {
		self.init(x: vector.x / vector.w, y: vector.y / vector.w, z: vector.z / vector.w)
	}
}

func * (left: SCNMatrix4, right: SCNVector3) -> SCNVector3 {
	let matrix = float4x4(left)
	let vector = float4(right)
	let result = matrix * vector
	
	return SCNVector3(result)
}

public let SCNVector3One: SCNVector3 = SCNVector3(1.0, 1.0, 1.0)

func SCNVector3Uniform(_ value: Float) -> SCNVector3 {
	return SCNVector3Make(value, value, value)
}

func SCNVector3Uniform(_ value: CGFloat) -> SCNVector3 {
	return SCNVector3Make(Float(value), Float(value), Float(value))
}

func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
	return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}

func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
	return SCNVector3Make(left.x - right.x, left.y - right.y, left.z - right.z)
}

func += (left: inout SCNVector3, right: SCNVector3) {
	left = left + right
}

func -= (left: inout SCNVector3, right: SCNVector3) {
	left = left - right
}

func / (left: SCNVector3, right: Float) -> SCNVector3 {
	return SCNVector3Make(left.x / right, left.y / right, left.z / right)
}

func * (left: SCNVector3, right: Float) -> SCNVector3 {
	return SCNVector3Make(left.x * right, left.y * right, left.z * right)
}

func /= (left: inout SCNVector3, right: Float) {
	left = left / right
}

func *= (left: inout SCNVector3, right: Float) {
	left = left * right
}

