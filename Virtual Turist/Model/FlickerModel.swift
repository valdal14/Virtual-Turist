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
