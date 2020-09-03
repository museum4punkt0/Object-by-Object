import UIKit

class StoryProgressView: UIView {
	struct Constants {
		static let horizontalPadding: CGFloat = 8
		static let barHeight: CGFloat = 3
		static let indicatorSize: CGFloat = 8
	}

	private var max: Int
	private var now: Int
	private var colorOn: UIColor
	private let colorOff: UIColor = .dark60Branded

	private var indicators = [StoryProgressDiamond]()
	private var indicatorLeftAnchors = [NSLayoutConstraint]()
	private var lastIndicatorRightAnchor = NSLayoutConstraint()

	private let barBackgroundView = UIView()
	private let barForegroundView = UIView()
	private var barRightAnchor = NSLayoutConstraint()
	private var barWidth: CGFloat {
		return CGFloat(self.now) * (Constants.indicatorSize + Constants.horizontalPadding) - Constants.horizontalPadding/2 - Constants.indicatorSize/2
	}
	private var totalWidthAnchor = NSLayoutConstraint()
	private var totalWidth: CGFloat {
		let indicatorWidth = CGFloat(max)*Constants.indicatorSize
		let paddingWidth = CGFloat(max-1)*Constants.horizontalPadding
		return indicatorWidth + paddingWidth
	}

	init(max: Int, now: Int, color: UIColor) {
		self.max = max != 0 ? max :  1
		self.now = 0
		self.colorOn = color
		super.init(frame: .zero)
		setup()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setup() {
		barBackgroundView.backgroundColor = colorOff
		barBackgroundView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(barBackgroundView)

		barForegroundView.backgroundColor = colorOn
		barForegroundView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(barForegroundView)

		for _ in 0..<max {
			let indicator = StoryProgressDiamond(color: colorOn)
			indicator.translatesAutoresizingMaskIntoConstraints = false
			addSubview(indicator)
			indicators.append(indicator)
		}

		if max > 0 {
			barRightAnchor = now > 0 ? barForegroundView.rightAnchor.constraint(equalTo: indicators[now-1].centerXAnchor,
													 constant: Constants.indicatorSize/2+Constants.horizontalPadding/2)
			: barForegroundView.rightAnchor.constraint(equalTo: indicators[0].centerXAnchor)
		} else {
			barRightAnchor = barForegroundView.rightAnchor.constraint(equalTo: barForegroundView.leftAnchor)
		}

		NSLayoutConstraint.activate([
			barBackgroundView.leftAnchor.constraint(equalTo: leftAnchor, constant: Constants.indicatorSize/2),
			barBackgroundView.rightAnchor.constraint(equalTo: rightAnchor, constant: -Constants.indicatorSize/2),
			barBackgroundView.heightAnchor.constraint(equalToConstant: Constants.barHeight),
			barBackgroundView.centerYAnchor.constraint(equalTo: centerYAnchor),

			barForegroundView.leftAnchor.constraint(equalTo: barBackgroundView.leftAnchor),
			barForegroundView.heightAnchor.constraint(equalTo: barBackgroundView.heightAnchor),
			barRightAnchor,
			barForegroundView.centerYAnchor.constraint(equalTo: barBackgroundView.centerYAnchor)
		])

		for i in 0..<indicators.count {
			NSLayoutConstraint.activate([
				indicators[i].centerYAnchor.constraint(equalTo: barBackgroundView.centerYAnchor),
			])

			guard i > 0 else {
				indicatorLeftAnchors.append(indicators[i].leftAnchor.constraint(equalTo: leftAnchor))
				continue
			}

			indicatorLeftAnchors.append(indicators[i].leftAnchor.constraint(equalTo: indicators[i-1].rightAnchor,
																		   constant: Constants.horizontalPadding))
		}

		totalWidthAnchor = widthAnchor.constraint(equalToConstant: totalWidth)

		NSLayoutConstraint.activate(indicatorLeftAnchors + [totalWidthAnchor, heightAnchor.constraint(equalToConstant: Constants.indicatorSize)])

		updateProgressIndicators(to: now)
	}

	// MARK: Public

	public func set(color: UIColor) {
		colorOn = color
		barForegroundView.backgroundColor = colorOn

		for i in 0..<indicators.count {
			if i < now {
				self.indicators[i].set(color: colorOn)
			} else {
				self.indicators[i].set(color: colorOff)
			}
		}
	}

	public func updateProgressIndicators(to newNow: Int, newMax: Int? = nil) {
		if let newMax = newMax {
		 if newNow > newMax {
			return
		}} else if newNow > max {
			return
		}

		if let newMax = newMax, newMax != max, newMax > 0 {
			if newMax < max {
				let diff = abs(newMax-max)
				for _ in 0..<diff {
					NSLayoutConstraint.deactivate([indicatorLeftAnchors.removeLast()])
					indicators.removeLast().removeFromSuperview()
				}
			} else if newMax > max {
				let diff = abs(newMax-max)

				for _ in 0..<diff {
					let indicator = StoryProgressDiamond(color: colorOn)
					indicator.translatesAutoresizingMaskIntoConstraints = false
					addSubview(indicator)

					if indicatorLeftAnchors.count > 0 {
						indicatorLeftAnchors.append(indicator.leftAnchor.constraint(equalTo: indicators.last!.rightAnchor,
						constant: Constants.horizontalPadding))
					} else {
						indicatorLeftAnchors.append(indicator.leftAnchor.constraint(equalTo: leftAnchor))
					}

					NSLayoutConstraint.activate([
						indicator.centerYAnchor.constraint(equalTo: centerYAnchor),
						indicatorLeftAnchors.last!
					])

					indicators.append(indicator)
				}
			}

			max = newMax
			totalWidthAnchor.constant =  totalWidth

			NSLayoutConstraint.deactivate([lastIndicatorRightAnchor])

			lastIndicatorRightAnchor = indicators.last!.rightAnchor.constraint(equalTo: rightAnchor)

			NSLayoutConstraint.activate([lastIndicatorRightAnchor])

			setNeedsLayout()
		}

		for i in 0..<indicators.count {
			if i < newNow {
				self.indicators[i].set(color: colorOn)
			} else {
				self.indicators[i].set(color: colorOff)
			}
		}

		if newNow != now && self.max > 0 {
			UIView.animate(withDuration: 0.5, animations: {
				NSLayoutConstraint.deactivate([self.barRightAnchor])

				if newNow == self.max {
					self.barRightAnchor = self.barForegroundView.rightAnchor.constraint(equalTo: self.indicators.last!.centerXAnchor)
				} else {
					self.barRightAnchor = newNow > 0 ? self.barForegroundView.rightAnchor.constraint(equalTo: self.indicators[newNow-1].centerXAnchor,
																								 constant: Constants.indicatorSize/2+Constants.horizontalPadding/2)
					: self.barForegroundView.rightAnchor.constraint(equalTo: self.indicators[0].centerXAnchor)
				}
				NSLayoutConstraint.activate([self.barRightAnchor])
				self.setNeedsLayout()
			})
		}

		now = newNow
	}
}

class StoryProgressDiamond: UIView {
	struct Constants {
		static let origin = CGPoint.zero
		static let size = CGSize(width: 8, height: 8)
	}

	var color: CGColor

	var diamond = CAShapeLayer()

	init(color: UIColor) {
		self.color = color.cgColor
		super.init(frame: .zero)
		setup()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setup() {
		diamond = CAShapeLayer.diamondShape(bounds: CGRect(origin: Constants.origin, size: Constants.size))
		diamond.fillColor = color
		diamond.strokeColor = nil
		diamond.lineWidth = 0
		diamond.lineJoin = CAShapeLayerLineJoin.miter
		layer.addSublayer(diamond)

		NSLayoutConstraint.activate([
			widthAnchor.constraint(equalToConstant: Constants.size.width),
			heightAnchor.constraint(equalToConstant: Constants.size.height)
		])
	}

	// MARK: Public

	public func set(color: UIColor) {
		self.color = color.cgColor
		diamond.fillColor = self.color
	}
}
