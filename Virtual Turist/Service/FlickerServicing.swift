//
//  FlickerServicing.swift
//  Virtual Turist
//
//  Created by Valerio D'ALESSIO on 23/1/23.
//

import Foundation

protocol FlickerServicing {
	func createFlickerSearchURL(endpointURL: String, method: String, apiKey: String, text: String, maxPictures: Int) throws -> URL?
	func createFlickerGetSizeURL(endpointURL: String, method: String, apiKey: String, photoId: String) throws -> URL?
	func fetchPicture(searchTerm: String, url: URL) async throws -> [Picture]
}

enum FlickerError: Error {
	case badURL, decodingError, badRequest, invalidAPIKey, serviceUnavailable, invalidMethod, URLNotFound, photoNotFound, permissionDenied
}

class FlickerService: FlickerServicing {
	
	func createFlickerGetSizeURL(endpointURL: String, method: String, apiKey: String, photoId: String) throws -> URL? {
		let stringURL = "\(endpointURL)?method=\(method)&api_key=\(apiKey)&photo_id=\(photoId)&format=json&nojsoncallback=1"
		return URL(string: stringURL) ?? nil
	}
	
	func createFlickerSearchURL(endpointURL: String, method: String, apiKey: String, text: String, maxPictures: Int) throws -> URL? {
		let searchTerm = text.replacingOccurrences(of: " ", with: "%20")
		let stringURL = "\(endpointURL)?method=\(method)&api_key=\(apiKey)&text=\(searchTerm)&per_page=\(maxPictures)&format=json&nojsoncallback=1"
		return URL(string: stringURL) ?? nil
	}
	
	func fetchPicture(searchTerm: String, url: URL) async throws -> [Picture] {
		
		let (data, response) = try await URLSession.shared.data(for: URLRequest(url: url))
		let res = response as! HTTPURLResponse
		
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
	
	func fetchPictureSizes(url: URL) async throws -> [PictureURL] {
		let (data, response) = try await URLSession.shared.data(for: URLRequest(url: url))
		let res = response as! HTTPURLResponse
		
		switch res.statusCode {
		case 200:
			let decodedData = try? JSONDecoder().decode(PictureSize.self, from: data)
			if let decodedData = decodedData {
				let pictureURL = decodedData.sizes.size.filter { !$0.source.isEmpty }
				print(pictureURL)
				return pictureURL
			} else {
				throw FlickerError.decodingError
			}
		case 1:
			throw FlickerError.photoNotFound
		case 2:
			throw FlickerError.permissionDenied
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
