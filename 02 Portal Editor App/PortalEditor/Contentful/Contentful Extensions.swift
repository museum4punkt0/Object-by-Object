import Foundation
import Contentful
import ARKit


// CFObjectText
protocol NarrativeAtom: Resource {}

// CFObjectText
protocol NarrativeContent: Resource {}

// CFWorldMap
// LocalWorldMap
protocol WorldMap {
	var displayTitle: String { get }
	var fileSize: Int? { get }
	var arWorldMap: ARWorldMap? { get }
}

public enum MediaType {
    case audio
    case image
    case scn
    case usdz
    case video
    case worldMap
}


extension Asset {
	private var fileExtension: String {
		return url?.pathExtension ?? ""
	}

	public var localURL: URL {
		return FileManager.default.documentSubfolderURL(.fetchedAssets).appendingPathComponent("\(id).\(fileExtension)")
	}
	
	public var localSize: Int? { (try? Data(contentsOf: localURL))?.count }
	public var serverSize: Int? { file?.details?.size }
	
	public var needsLocalUpdate: Bool {
		guard
			let assetModificationDate = updatedAt,
			let localModificationDate = FileManager.default.modificationDate(url: localURL)
		else {
			return serverSize != nil
		}
		return assetModificationDate > localModificationDate
	}
	
	public func updateLocalData(with data: Data) {
		do {
			try data.write(to: localURL)
		} catch {
			print("Asset: Error storing data")
		}
	}
	
	public func loadWorldMap() -> ARWorldMap? {
		do {
			if localURL.pathExtension != "map" {
				print("Asset: .\(localURL.pathExtension) wrong filetype, expected worldMap file")
			}
			let rawData = try Data(contentsOf: localURL)

			do {
				let data = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(rawData) as? ARWorldMap
				print("Asset: unarchived worldMapData exists: \(data != nil)")
				return data
			} catch {
				print("Asset: Error unarchiving worldMap from rawData")
				return nil
			}

		} catch {
			print("Asset: Error getting data from contents of localURL")
			return nil
		}
	}

	public func isOfType(_ mediaType: [MediaType]) -> Bool {
        for type in mediaType {
            switch type {
                case .audio:
                    if file?.contentType.components(separatedBy: "/").first == "audio" { return true }
                case .image:
                    if file?.contentType.components(separatedBy: "/").first == "image" { return true }
                case .scn:
                    if localURL.pathExtension == "scn" { return true }
                case .usdz:
                    if localURL.pathExtension == "usdz" { return true }
                case .video:
					if ["mp4", "m4v", "mov"].contains(localURL.pathExtension.lowercased()) { return true }
                case .worldMap:
                    if localURL.pathExtension == "map" { return true }
            }
        }
        return false
    }
}

