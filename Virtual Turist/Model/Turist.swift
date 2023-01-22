//
//  Turist.swift
//  Virtual Turist
//
//  Created by Valerio D'ALESSIO on 22/1/23.
//

import CoreLocation
import Foundation

struct Turist: Identifiable {
	let id = UUID()
	let coordinate: CLLocationCoordinate2D
}
