import UIKit

extension CAShapeLayer {

	static func diamondShape(bounds: CGRect) -> CAShapeLayer {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: bounds.midX, y: bounds.minY))
        path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.midY))
        path.addLine(to: CGPoint(x: bounds.midX, y: bounds.maxY))
        path.addLine(to: CGPoint(x: bounds.minX, y: bounds.midY))
        path.close()

        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath

		return shapeLayer
	}

	static func arrowHead(bounds: CGRect) -> CAShapeLayer {
		let path = UIBezierPath()
		path.move(to: CGPoint(x: bounds.minX, y: bounds.minY))
		path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.midY))
		path.addLine(to: CGPoint(x: bounds.minX, y: bounds.maxY))

		let shapeLayer = CAShapeLayer()
		shapeLayer.path = path.cgPath

		return shapeLayer
	}

	static func arrowTail(bounds: CGRect) -> CAShapeLayer {
		let path1 = UIBezierPath()
		path1.move(to: CGPoint(x: bounds.minX, y: bounds.minY))
		path1.addLine(to: CGPoint(x: bounds.midX, y: bounds.midY))
		path1.addLine(to: CGPoint(x: bounds.minX, y: bounds.maxY))

		let path2 = UIBezierPath()
		path2.move(to: CGPoint(x: bounds.midX, y: bounds.minY))
		path2.addLine(to: CGPoint(x: bounds.maxX, y: bounds.midY))
		path2.addLine(to: CGPoint(x: bounds.midX, y: bounds.maxY))

		path1.append(path2)

		let shapeLayer = CAShapeLayer()
		shapeLayer.path = path1.cgPath

		return shapeLayer
	}
}
