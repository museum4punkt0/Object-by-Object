import UIKit

extension UIView {
	func addCornerRadius(_ radius: CGFloat? = nil) {
		layer.masksToBounds = true
		layer.cornerRadius = radius ?? min(frame.size.width, frame.size.height) / 2
	}
	
	func addBorder(color: UIColor, width: CGFloat = 1) {
		layer.borderColor = color.cgColor
		layer.borderWidth = width
	}

	func removeBorder() {
		layer.borderColor = nil
		layer.borderWidth = 0
	}
	
	func addShadow(color: UIColor = .black, offsetHeight: CGFloat = 5, offsetWidth: CGFloat = 0, radius: CGFloat = 4, opacity: Float = 0.25) {
		layer.shadowColor = color.cgColor
		layer.shadowOffset = CGSize(width: offsetWidth, height: offsetHeight)
		layer.shadowOpacity = opacity
		layer.shadowRadius = radius
	}
	
	var containingViewController: UIViewController? {
		if let viewController = next as? UIViewController {
			return viewController
		}
		if let view = next as? UIView {
			return view.containingViewController
		}
		return nil
	}
	
	func setAnchorPoint(_ anchorPoint: CGPoint) {
		var newPoint = CGPoint(x: bounds.size.width * anchorPoint.x, y: bounds.size.height * anchorPoint.y)
		var oldPoint = CGPoint(x: bounds.size.width * layer.anchorPoint.x, y: bounds.size.height * layer.anchorPoint.y)
		
		newPoint = newPoint.applying(transform)
		oldPoint = oldPoint.applying(transform)
		
		var position = layer.position
		position.x -= oldPoint.x
		position.x += newPoint.x
		
		position.y -= oldPoint.y
		position.y += newPoint.y
		
		layer.position = position
		layer.anchorPoint = anchorPoint
	}

	// MARK: Layout
	
	enum Alignment {
		case allSides
		case allSidesSafeArea
		case leftSafeArea(_ const: CGFloat = 0, to: NSLayoutConstraint.Attribute? = nil)
		case rightSafeArea(_ const: CGFloat = 0, to: NSLayoutConstraint.Attribute? = nil)
		case topSafeArea(_ const: CGFloat = 0, to: NSLayoutConstraint.Attribute? = nil)
		case bottomSafeArea(_ const: CGFloat = 0, to: NSLayoutConstraint.Attribute? = nil)
		case left(_ const: CGFloat = 0, to: NSLayoutConstraint.Attribute? = nil)
		case right(_ const: CGFloat = 0, to: NSLayoutConstraint.Attribute? = nil)
		case top(_ const: CGFloat = 0, to: NSLayoutConstraint.Attribute? = nil)
		case bottom(_ const: CGFloat = 0, to: NSLayoutConstraint.Attribute? = nil)
		case width(CGFloat? = nil)
		case height(CGFloat? = nil)
		case center, centerX, centerY

		func constraints(for selfView: UIView, with view: UIView) -> [NSLayoutConstraint] {
			switch self {
			case .allSides:
				return [leftConstraint(for: selfView, with: view, constant: 0),
						rightConstraint(for: selfView, with: view, constant: 0),
						topConstraint(for: selfView, with: view, constant: 0),
						bottomConstraint(for: selfView, with: view, constant: 0)]
			case .allSidesSafeArea:
				return [leftConstraint(for: selfView, with: view.safeAreaLayoutGuide, constant: 0),
						rightConstraint(for: selfView, with: view.safeAreaLayoutGuide, constant: 0),
						topConstraint(for: selfView, with: view.safeAreaLayoutGuide, constant: 0),
						bottomConstraint(for: selfView, with: view.safeAreaLayoutGuide, constant: 0)]
			case .leftSafeArea(let constant, let attribute):
				return [leftConstraint(for: selfView, with: view, constant: view.safeAreaInsets.left + constant, to: attribute)]
			case .rightSafeArea(let constant, let attribute):
				return [rightConstraint(for: selfView, with: view, constant: view.safeAreaInsets.right - constant, to: attribute)]
			case .topSafeArea(let constant, let attribute):
				return [topConstraint(for: selfView, with: view, constant: view.safeAreaInsets.top + constant, to: attribute)]
			case .bottomSafeArea(let constant, let attribute):
				return [bottomConstraint(for: selfView, with: view, constant: view.safeAreaInsets.bottom - constant, to: attribute)]
			case .left(let constant, let attribute):
				return [leftConstraint(for: selfView, with: view, constant: constant, to: attribute)]
			case .right(let constant, let attribute):
				return [rightConstraint(for: selfView, with: view, constant: constant, to: attribute)]
			case .top(let constant, let attribute):
				return [topConstraint(for: selfView, with: view, constant: constant, to: attribute)]
			case .bottom(let constant, let attribute):
				return [bottomConstraint(for: selfView, with: view, constant: constant, to: attribute)]
			case .width(let constant):
				return [widthConstraint(for: selfView, with: view, constant: constant)]
			case .height(let constant):
				return [heightConstraint(for: selfView, with: view, constant: constant)]
			case .center:
				return [centerConstraint(for: selfView, with: view, attribute: .centerX), centerConstraint(for: selfView, with: view, attribute: .centerY)]
			case .centerX:
				return [centerConstraint(for: selfView, with: view, attribute: .centerX)]
			case .centerY:
				return [centerConstraint(for: selfView, with: view, attribute: .centerY)]
			}
		}

		private func leftConstraint(for selfView: UIView, with item: Any, constant: CGFloat, to attribute: NSLayoutConstraint.Attribute? = nil) -> NSLayoutConstraint {
			return NSLayoutConstraint(item: selfView, attribute: .left, relatedBy: .equal, toItem: item, attribute: attribute ?? .left, multiplier: 1.0, constant: constant)
		}

		private func rightConstraint(for selfView: UIView, with item: Any, constant: CGFloat, to attribute: NSLayoutConstraint.Attribute? = nil) -> NSLayoutConstraint {
			NSLayoutConstraint(item: selfView, attribute: .right, relatedBy: .equal, toItem: item, attribute: attribute ?? .right, multiplier: 1.0, constant: constant)
		}

		private func topConstraint(for selfView: UIView, with item: Any, constant: CGFloat, to attribute: NSLayoutConstraint.Attribute? = nil) -> NSLayoutConstraint {
			NSLayoutConstraint(item: selfView, attribute: .top, relatedBy: .equal, toItem: item, attribute: attribute ?? .top, multiplier: 1.0, constant: constant)
		}

		private func bottomConstraint(for selfView: UIView, with item: Any, constant: CGFloat, to attribute: NSLayoutConstraint.Attribute? = nil) -> NSLayoutConstraint {
			NSLayoutConstraint(item: selfView, attribute: .bottom, relatedBy: .equal, toItem: item, attribute: attribute ?? .bottom, multiplier: 1.0, constant: constant)
		}

		private func widthConstraint(for selfView: UIView, with item: Any, constant: CGFloat?) -> NSLayoutConstraint {
			NSLayoutConstraint(item: selfView, attribute: .width, relatedBy: .equal, toItem: (constant == nil ? item : nil), attribute: .width, multiplier: 1.0, constant: constant ?? (item as? UIView)?.frame.size.width ?? 0)
		}

		private func heightConstraint(for selfView: UIView, with item: Any, constant: CGFloat?) -> NSLayoutConstraint {
			NSLayoutConstraint(item: selfView, attribute: .height, relatedBy: .equal, toItem: (constant == nil ? item : nil), attribute: .height, multiplier: 1.0, constant: constant ?? (item as? UIView)?.frame.size.height ?? 0)
		}
		
		private func centerConstraint(for selfView: UIView, with item: Any, attribute: NSLayoutConstraint.Attribute) -> NSLayoutConstraint {
			NSLayoutConstraint(item: selfView, attribute: attribute, relatedBy: .equal, toItem: item, attribute: attribute, multiplier: 1.0, constant: 0)
		}
	}

	func layoutConstraints(with view: UIView, to alignments: [UIView.Alignment]) -> [NSLayoutConstraint] {
		var constraints = [NSLayoutConstraint]()

		for alignment in alignments {
			constraints.append(contentsOf: alignment.constraints(for: self, with: view))
		}

		return constraints
	}
	
	func layoutConstraints(equal view: UIView) -> [NSLayoutConstraint] {
		return layoutConstraints(with: view, to: [.allSides])
	}
	
	func identicalConstraints(with view: UIView) -> [NSLayoutConstraint] {
		[
			topAnchor.constraint(equalTo: view.topAnchor),
			bottomAnchor.constraint(equalTo: view.bottomAnchor),
			leftAnchor.constraint(equalTo: view.leftAnchor),
			rightAnchor.constraint(equalTo: view.rightAnchor)
		]
	}
	
	func add(_ subview: UIView, activate constraints: [NSLayoutConstraint]?	 = nil) {
		subview.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subview)
		NSLayoutConstraint.activate(constraints ?? subview.identicalConstraints(with: self))
	}

	func add(_ subview: UIView, constraints: [NSLayoutConstraint]? = nil, accumulator: inout [NSLayoutConstraint]) {
		subview.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subview)
		accumulator += constraints ?? subview.identicalConstraints(with: self)
	}
}

class UIPassThroughView: UIView {

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Get the hit view we would normally get with a standard UIView
        let hitView = super.hitTest(point, with: event)

        // If the hit view was ourself (meaning no subview was touched),
        // return nil instead. Otherwise, return hitView, which must be a subview.
        return hitView == self ? nil : hitView
    }
}

