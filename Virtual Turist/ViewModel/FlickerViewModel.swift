//
//  FlickerViewModel.swift
//  Virtual Turist
//
//  Created by Valerio D'ALESSIO on 23/1/23.
//

import Foundation

@MainActor
class FlickerViewModel: ObservableObject {
	typealias FVM = FlickerViewModel
	private let flickerService: FlickerService
	private static let apiKey = "c110cf234c60e55ff8733bc3a1afd72f"
	private static let maxSize = 9
	@Published private(set) var pictures: [Picture] = []
	@Published private(set) var apiError: Bool = false
	
	enum Endpoint: String {
		case getPicturesByText = "https://api.flickr.com/services/rest/"
	}
	
	enum ApiMethod: String {
		case search = "flickr.photos.search"
	}
	
	init(flickerService: FlickerService){
		self.flickerService = flickerService
	}
	
	func getPictures(text: String) async throws {
		do {
			let url = try flickerService.createFlickerSearchURL(endpointURL: Endpoint.getPicturesByText.rawValue,
													  method: ApiMethod.search.rawValue,
													  apiKey: FVM.apiKey,
													  text: text,
													  maxPictures: FVM.maxSize)
			
			guard let url = url else { throw FlickerError.badURL }
			
			do {
				self.pictures = try await flickerService.fetchPicture(searchTerm: text, url: url)
			} catch {
				apiError = true
				print(error.localizedDescription)
				throw FlickerError.badRequest
			}
			
		} catch let error as FlickerError {
			print(error.localizedDescription)
			throw FlickerError.badURL
		}
	}
}
