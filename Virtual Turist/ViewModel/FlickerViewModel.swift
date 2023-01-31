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
	var pictureData: [Picture] = []
	var pictureURL: [PictureURL] = []
	var flickerPhoto: [Photo] = []
	var index: Int = 0
	
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
																maxPictures: (1000 / FVM.maxSize))
			
			guard let url = url else { throw FlickerError.badURL }
			
			do {
				self.pictureData = try await flickerService.fetchPicture(searchTerm: text, url: url)
				for _ in pictureData {
					await (UIApplication.shared.delegate as! AppDelegate).dataControllerVM.photos.append(Photo(context: (UIApplication.shared.delegate as! AppDelegate).dataControllerVM.container.viewContext))
				}
			} catch {
				throw FlickerError.badRequest
			}
			
		} catch {
			throw FlickerError.badURL
		}
	}
	
	/// Get photo URLs
	func getPhotoSizeURL(photoId: String, pin: Pin, dataController: DataControllerViewModel) async throws {
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
					//pictureURL.append(imgUrl)
					if let url = URL(string: imgUrl.source) {
						let imageData = try! Data(contentsOf: url)
						let newPhoto = Photo(context: dataController.container.viewContext)
						newPhoto.pin = pin
						newPhoto.name = UUID().uuidString
						newPhoto.photoData = imageData
						
						let dc = dataController
						try dc.dataControllerService.performCoreDataOperation(persistentContainer: dataController.container,
																		  dataType: .photo,
																		  operation: .add,
																		  coordinates: (pin.latitude, pin.longitude),
																		  address: pin.fullAddress,
																		  imageData: imageData,
																		  imageName: UUID().uuidString,
																		  pin: pin,
																		  center: (pin.latDelta, pin.longDelta))
						/// once saved let's store it inside the photo array in the dataController
						//dataController.photos.append(newPhoto)
						dataController.photos[index] = newPhoto
						index += 1
						
					}
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
		index = 0
	}
}
