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
	private let defaultImageSize = "Medium"
	private let flickerService: FlickerService
	private static let apiKey = "c110cf234c60e55ff8733bc3a1afd72f"
	private static let maxSize = 15
	private var pictures: [Picture] = []
	private var pictureURL: [PictureURL] = []
	var uiImageBinaryData: [Data] = []
	
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
	private func getPicturesFromFlickerService(text: String) async throws {
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
				print(error.localizedDescription)
				throw FlickerError.badRequest
			}
			
		} catch let error as FlickerError {
			print(error.localizedDescription)
			throw FlickerError.badURL
		}
	}
	
	/// Get photo URLs
	private func getPhotoSizeURL(photoId: String) async throws  {
		do {
			let url = try flickerService.createFlickerGetSizeURL(endpointURL: Endpoint.getPicturesByText.rawValue,
																 method: ApiMethod.getSize.rawValue,
																 apiKey: FVM.apiKey,
																 photoId: photoId)
			
			guard let url = url else { throw FlickerError.badURL }
			
			do {
				let pictures = try await flickerService.fetchPictureSizes(url: url)
				for pic in pictures {
					if pic.label == defaultImageSize {
						if let picUrl = URL(string: pic.source) {
							try await fetchUIImageFromURL(from: picUrl)
						}
					}
				}
			} catch {
				print(error.localizedDescription)
				throw FlickerError.badRequest
			}
		} catch {
			print(error.localizedDescription)
			throw FlickerError.badURL
		}
	}
	
	private func fetchUIImageFromURL(from url: URL) async throws {
		do {
			let (data, response) = try await URLSession.shared.data(for: URLRequest(url: url))
			let res = response as! HTTPURLResponse
			
			switch res.statusCode {
			case 200:
				uiImageBinaryData.append(data)
			default:
				throw FlickerError.invalidImage
			}
			
		} catch {
			print(error.localizedDescription)
			throw FlickerError.badRequest
		}
	}
	
	func combineFetchedData(text: String) async throws {
		do {
			try await getPicturesFromFlickerService(text: text)
			for picture in self.pictures {
				try await getPhotoSizeURL(photoId: picture.id)
			}
		} catch {
			print(error.localizedDescription)
			throw FlickerError.badRequest
		}
	}
}
