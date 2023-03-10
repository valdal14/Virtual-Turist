//
//  DataControllerViewModel.swift
//  Virtual Turist
//
//  Created by Valerio D'ALESSIO on 21/1/23.
//

import CoreData
import Foundation

class DataControllerViewModel {
	let dataControllerService: DataControllerService
	let container: NSPersistentContainer
	var pins: [Pin] = []
	var photos: [Photo] = []
	
	init(dataControllerService: DataControllerService, containerName: String) {
		self.dataControllerService = dataControllerService
		self.container = NSPersistentContainer(name: containerName)
		self.container.loadPersistentStores { persistentStore, error in
			if let error = error as NSError? {
				// Replace this implementation with code to handle the error appropriately.
				// fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

				/*
				 Typical reasons for an error here include:
				 * The parent directory does not exist, cannot be created, or disallows writing.
				 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
				 * The device is out of space.
				 * The store could not be migrated to the current model version.
				 Check the error message to determine what the actual problem was.
				 */
				fatalError("Unresolved error \(error), \(error.userInfo)")
			}
		}
		
		self.container.viewContext.automaticallyMergesChangesFromParent = true
	}
	
	//MARK: - Data Helper methods
	func savePin(coordinates: (Double, Double), address: String, pin: Pin?, span: (Double, Double)) throws {
		try dataControllerService.performCoreDataOperation(persistentContainer: container,
													   dataType: .pin,
													   operation: .add,
													   coordinates: coordinates,
													   address: address,
													   imageData: nil,
													   imageName: nil,
													   pin: nil,
													   center: span)
		
		/// fetch the data once a pin has been saved
		/// this will populate the pins array and
		/// allow to fetch the new selected pin via
		/// fetchSelectedPin(coordinates:)
		try fetchMapPins(pin: nil)
	}
	
	func fetchMapPins(pin: Pin?) throws {
		let request = Pin.fetchRequest() as NSFetchRequest<Pin>
		pins = try dataControllerService.getDataFromCoreDataStore(persistentContainer: container, request: request, pin: pin)
	}
	
	
	func fetchSelectedPin(coordinates: (Double, Double)) -> Pin? {
		if let foundPin = pins.filter({ $0.latitude == coordinates.0 && $0.longitude == coordinates.1}).first {
			return foundPin
		} else {
			return nil
		}
	}
	
	func fetchPictures(selectedPinObject: Pin) throws {
		let request = Photo.fetchRequest() as NSFetchRequest<Photo>
		let predicate = NSPredicate(format: "pin == %@", selectedPinObject)
		request.predicate = predicate
		photos = try dataControllerService.getDataFromCoreDataStore(persistentContainer: container, request: request, pin: selectedPinObject)
	}
	
	func savePicture(imageData: Data, imageName: String, pin: Pin) throws {
		let newPhoto = Photo(context: self.container.viewContext)
		newPhoto.name = imageName
		newPhoto.photoData = imageData
		newPhoto.pin = pin
		photos.append(newPhoto)
		
		try dataControllerService.performCoreDataOperation(persistentContainer: container,
													   dataType: .photo,
													   operation: .add,
													   coordinates: nil,
													   address: nil,
													   imageData: imageData,
													   imageName: imageName,
													   pin: pin,
													   center: nil)
	}
	
	func deletePicture(imageName: String) throws {
		try dataControllerService.performCoreDataOperation(persistentContainer: container,
													   dataType: .photo,
													   operation: .delete,
													   coordinates: nil,
													   address: nil,
													   imageData: nil,
													   imageName: imageName,
													   pin: nil,
													   center: nil)
	}
}
