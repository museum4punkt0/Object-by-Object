import AVFoundation
import UIKit

class Video {
	static func frame(from url: URL, at seconds: Double) -> UIImage? {
		let avAsset = AVURLAsset(url: url, options: nil)
		let imageGenerator = AVAssetImageGenerator(asset: avAsset)
		imageGenerator.appliesPreferredTrackTransform = true
		var thumbnail: UIImage?
		do {
			thumbnail = try UIImage(cgImage: imageGenerator.copyCGImage(at: CMTime(seconds: seconds, preferredTimescale: 1), actualTime: nil))
			return thumbnail
		} catch let e as NSError {
			print("Error: \(e.localizedDescription)")
		}
		return nil
	}
}
