//
//  FlickerServicing.swift
//  Virtual Turist
//
//  Created by Valerio D'ALESSIO on 23/1/23.
//

import Foundation

protocol FlickerServicing {
	func createFlickerURL(endpointURL: String, method: String, apiKey: String, text: String, maxPictures: Int) throws -> URL?
	func fetchPicture(searchTerm: String, url: URL) async throws -> [Picture]
}

enum FlickerError: Error {
	case badURL, decodingError, badRequest, invalidAPIKey, serviceUnavailable, invalidMethod, URLNotFound
}

class FlickerService: FlickerServicing {
	func createFlickerURL(endpointURL: String, method: String, apiKey: String, text: String, maxPictures: Int) throws -> URL? {
		let searchTerm = text.replacingOccurrences(of: " ", with: "%20")
		let stringURL = "\(endpointURL)?method=\(method)&pi_key=\(apiKey)&text=\(searchTerm)&per_page=\(maxPictures)&format=json&nojsoncallback=1"
		return URL(string: stringURL) ?? nil
	}
	
	func fetchPicture(searchTerm: String, url: URL) async throws -> [Picture] {
		
		let (data, response) = try await URLSession.shared.data(for: URLRequest(url: url))
		
		let res = response as! HTTPURLResponse
		print(res.statusCode)
		switch res.statusCode {
		case 200:
			let decodedData = try? JSONDecoder().decode(FlickerModel.self, from: data)
			if let decodedData = decodedData {
				/// filtering only public pictures
				let pictures = decodedData.photos.picture.filter { $0.ispublic == 1}
				print(pictures)
				return pictures
			} else {
				throw FlickerError.decodingError
			}
		case 100:
			throw FlickerError.invalidAPIKey
		case 105:
			throw FlickerError.serviceUnavailable
		case 112:
			throw FlickerError.invalidMethod
		case 116:
			throw FlickerError.URLNotFound
		default:
			throw FlickerError.badRequest
		}
		
	}
}
