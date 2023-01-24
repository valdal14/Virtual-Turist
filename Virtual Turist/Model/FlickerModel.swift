//
//  FlickerModel.swift
//  Virtual Turist
//
//  Created by Valerio D'ALESSIO on 23/1/23.
//

import Foundation

struct FlickerModel: Codable {
	let photos: Photos
}

struct Photos: Codable {
	let picture: [Picture]
	
	enum CodingKeys: String, CodingKey {
		case picture = "photo"
	}
}

struct Picture: Codable, Identifiable {
	let id: String
	let owner: String
	let ispublic: Int
}

struct PictureSize: Codable {
	let sizes: Sizes
}

struct Sizes: Codable {
	let size: [PictureURL]
}

struct PictureURL: Codable, Hashable {
	let label: String
	let source: String
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(label)
		hasher.combine(source)
	}
}
