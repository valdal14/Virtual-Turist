//
//  FlickerViewModel.swift
//  Virtual Turist
//
//  Created by Valerio D'ALESSIO on 23/1/23.
//

import Foundation
import SwiftUI
import UIKit

class FlickerViewModel {
	typealias FVM = FlickerViewModel
	private let defaultImageSize = "Square"
	private let flickerService: FlickerService
	private static let apiKey = "c110cf234c60e55ff8733bc3a1afd72f"
	private static let maxSize = 21
	private var pictureData: [Picture] = []
	var pictureURL: [PictureURL] = []
	
	enum Endpoint: String {
		case getPicturesByText = "https://api.flickr.com/services/rest/"
	}
	
	enum ApiMethod: String {
		case search = "flickr.photos.search"
		case getSize = "flickr.photos.getSizes"
	}
	
	init(flickerService: FlickerService){
		self.flickerService = flickerService
	}
	
	//MARK: - Helper method to inject data to the flickerService
	
	/// Get photos information
	func getPicturesFromFlickerService(text: String) async throws {
		do {
			let url = try flickerService.createFlickerSearchURL(endpointURL: Endpoint.getPicturesByText.rawValue,
													  method: ApiMethod.search.rawValue,
													  apiKey: FVM.apiKey,
													  text: text,
													  maxPictures: FVM.maxSize)
			
			guard let url = url else { throw FlickerError.badURL }
			
			do {
				self.pictureData = try await flickerService.fetchPicture(searchTerm: text, url: url)
				/// fetch image url source
				do {
					
					for picture in pictureData {
						try await self.getPhotoSizeURL(photoId: picture.id)
					}
					
				} catch {
					throw FlickerError.badRequest
				}
			} catch {
				throw FlickerError.badRequest
			}
			
		} catch {
			throw FlickerError.badURL
		}
	}
	
	/// Get photo URLs
	private func getPhotoSizeURL(photoId: String) async throws {
		do {
			let url = try flickerService.createFlickerGetSizeURL(endpointURL: Endpoint.getPicturesByText.rawValue,
																 method: ApiMethod.getSize.rawValue,
																 apiKey: FVM.apiKey,
																 photoId: photoId)
			
			guard let url = url else { throw FlickerError.badURL }
			
			do {
				let picture = try await flickerService.fetchPictureSizes(url: url)
				let extractDefaultSize = picture.filter({ $0.label == defaultImageSize })
				if let imgUrl = extractDefaultSize.first {
					pictureURL.append(imgUrl)
				}
			} catch {
				throw FlickerError.badRequest
			}
		} catch {
			throw FlickerError.badURL
		}
	}
	
	/// empties all in-momory info
	func removeInMemoryPictureInformation() {
		pictureData = []
		pictureURL = []
	}
}
