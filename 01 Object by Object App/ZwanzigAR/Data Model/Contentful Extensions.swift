//
//  Contentful Extensions.swift
//  ZwanzigAR
//
//  Created by Ekkehard Petzold on 04.06.20.
//  Copyright © 2020 Jan Alexander. All rights reserved.
//

import Contentful
import CoreLocation

extension Location {
	public var clLocation: CLLocation {
		CLLocation(latitude: latitude, longitude: longitude)
	}
}
