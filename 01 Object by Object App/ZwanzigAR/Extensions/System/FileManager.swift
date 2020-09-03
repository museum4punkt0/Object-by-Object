//
//  FileManager.swift
//  ZwanzigAR
//
//  Created by Ekkehard Petzold on 27.05.20.
//  Copyright © 2020 Jan Alexander. All rights reserved.
//

import Foundation

extension FileManager {
	
	enum DocumentSubfolder: String, CaseIterable {
		case fetchedAssets
		case locallyGenerated
	}
	
	func documentSubfolderURL(_ subfolder: DocumentSubfolder) -> URL {
		let subfolderURL = urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(subfolder.rawValue)
		
		if !fileExists(atPath: subfolderURL.path) {
			try? createDirectory(at: subfolderURL, withIntermediateDirectories: true)
		}
		
		return subfolderURL
	}
	
	func modificationDate(url: URL) -> Date? {
		return try? attributesOfItem(atPath: url.path)[.modificationDate] as? Date
	}
}
