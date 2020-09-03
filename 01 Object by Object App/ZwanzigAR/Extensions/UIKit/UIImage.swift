import UIKit

extension UIImage {
    func getPixelColor(at point: CGPoint) -> UIColor? {
        guard
            let cgImage = cgImage,
            let pixelData = cgImage.dataProvider?.data
        else { return nil }

        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)

        let bytesPerPixel = cgImage.bitsPerPixel / 8

        let pixelInfo: Int = ((cgImage.bytesPerRow * Int(point.y)) + (Int(point.x) * bytesPerPixel))

        let b = CGFloat(data[pixelInfo]) / CGFloat(255.0)
        let g = CGFloat(data[pixelInfo+1]) / CGFloat(255.0)
        let r = CGFloat(data[pixelInfo+2]) / CGFloat(255.0)
        let a = CGFloat(data[pixelInfo+3]) / CGFloat(255.0)

        return UIColor(red: r, green: g, blue: b, alpha: a)
    }

	func inverted() -> UIImage? {
		guard let ciImage = CIImage(image: self) else {
			return nil
		}
		return UIImage(ciImage: ciImage.applyingFilter("CIColorInvert", parameters: [:]))
	}

	static func composeButtonImage(from thumbImage: UIImage, alpha: CGFloat = 1.0) -> UIImage {
		let maskImage = #imageLiteral(resourceName: "buttonring")
		var thumbnailImage = thumbImage
		if let invertedImage = thumbImage.inverted() {
			thumbnailImage = invertedImage
		}

		// Compose a button image based on a white background and the inverted thumbnail image.
		UIGraphicsBeginImageContextWithOptions(maskImage.size, false, 0.0)
		let maskDrawRect = CGRect(origin: CGPoint.zero,
								  size: maskImage.size)
		let thumbDrawRect = CGRect(origin: CGPoint((maskImage.size - thumbImage.size) / 2),
								   size: thumbImage.size)
		maskImage.draw(in: maskDrawRect, blendMode: .normal, alpha: alpha)
		thumbnailImage.draw(in: thumbDrawRect, blendMode: .normal, alpha: alpha)
		let composedImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return composedImage!
	}

	func sepiaFilter(intensity: Double = 0.5) -> UIImage?
	{
		guard let ciImage = CIImage(image: self) else {
			print("ERROR: Could not derive CIImage from UIImage")
			return nil
		}
		
		let sepiaFilter = CIFilter(name:"CISepiaTone")
		sepiaFilter?.setValue(ciImage, forKey: kCIInputImageKey)
		sepiaFilter?.setValue(intensity, forKey: kCIInputIntensityKey)
		if let ciOutput = sepiaFilter?.outputImage {
			return UIImage(ciImage: ciOutput)
		}
		print("ERROR: Could not derive CIImage from sepia filter – filter exists: \(sepiaFilter != nil)")
		return nil
	}
	
//	func resized(_ newSize: CGSize) -> UIImage {
//
//		let hasAlpha = true
//		let scale: CGFloat = 0.0 // Use scale factor of main screen
//
//		UIGraphicsBeginImageContextWithOptions(newSize, hasAlpha, scale)
//		self.draw(in: CGRect(origin: CGPoint.zero, size: newSize))
//
//		let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
//		return scaledImage!
//	}
}

