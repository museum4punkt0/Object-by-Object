import Foundation
import CoreData
import ContentfulPersistence
import ARKit

public enum MediaType {
    case audio
    case image
    case scn
    case usdz
    case video
    case worldMap
}

class Asset: NSManagedObject, AssetPersistable {

//     @nonobjc public class func fetchRequest() -> NSFetchRequest<Asset> {
//        return NSFetchRequest<Asset>(entityName: "Asset")
//    }

	@NSManaged public var id: String
    @NSManaged public var localeCode: String?
    @NSManaged public var title: String?
	@NSManaged public var assetDescription: String?
    @NSManaged public var urlString: String?
	@NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?

    @NSManaged public var size: NSNumber?
    @NSManaged public var width: NSNumber?
    @NSManaged public var height: NSNumber?
    @NSManaged public var fileType: String?
	@NSManaged public var fileName: String?
    @NSManaged public var internetMediaType: String?
	
	@NSManaged public var clueObjectMediaInverse: NSSet
    @NSManaged public var hintImageInverse: NSSet
    @NSManaged public var logoInverse: NSSet
    @NSManaged public var mapFileInverse: NSSet
    @NSManaged public var objectMediaInverse: NSSet
	@NSManaged public var storyTeaserImageInverse: NSSet
}

extension Asset {
	private var fileExtension: String {
		guard let urlString = urlString else { return "" }
		return URL(string: urlString)?.pathExtension ?? ""
	}

	public var localURL: URL {
		return FileManager.default.documentSubfolderURL(.fetchedAssets).appendingPathComponent("\(id).\(fileExtension)")
	}

	public var localSize: Int? { (try? Data(contentsOf: localURL))?.count }
	public var serverSize: Int? { size?.intValue }

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
}

extension Asset {
	public func isOfType(_ mediaType: [MediaType]) -> Bool {
        for type in mediaType {
            switch type {
                case .audio:
                    if fileType?.components(separatedBy: "/").first == "audio" { return true }
                case .image:
                    if fileType?.components(separatedBy: "/").first == "image" { return true }
                case .scn:
                    if localURL.pathExtension.lowercased() == "scn" { return true }
                case .usdz:
                    if localURL.pathExtension.lowercased() == "usdz" { return true }
                case .video:
					if ["mp4", "mov", "m4v"].contains(localURL.pathExtension.lowercased()) { return true }
                case .worldMap:
                    if localURL.pathExtension.lowercased() == "map" { return true }
            }
        }
        return false
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
	
	public func loadImage() -> UIImage? {
		guard
			isOfType([.image])
		else {
			print("Asset: Wrong media type, expected image")
			return nil
		}
		guard
			let data = try? Data(contentsOf: localURL),
			let image = UIImage(data: data)
		else {
			print("Asset: Error creating Image")
			return nil
		}
		return image
	}
}
