//
//  DataServicing.swift
//  Virtual Turist
//
//  Created by Valerio D'ALESSIO on 21/1/23.
//

import CoreData
import Foundation

//MARK: - Protocol
protocol DataServicing {
	func performCoreDataOperation(persistentContainer: NSPersistentContainer,
								  dataType: DataType,
								  operation: OperationType,
								  coordinates: (Double,Double)?,
								  address: String?,
								  imageData: Data?,
								  imageName: String?,
								  pin: Pin?,
								  center: (Double, Double)?)
	
	func getDataFromCoreDataStore<T>(persistentContainer: NSPersistentContainer, request: NSFetchRequest<T>, pin: Pin?) throws -> [T]
}

//MARK: - Enums
enum DataControllerError: String, Error {
	case savingError = "Error while trying to save data"
	case invalidaType = "The given type is not recognized"
	case fetchingError = "Error while trying to fetch data"
	case invalidPin = "Invalid Pin was provided to this API"
}

enum DataType {
	case pin
	case photo
}

enum OperationType {
	case add
	case delete
}

//MARK: - DataControllerService
class DataControllerService: DataServicing {
	
	//MARK: - DataServicing Delegatation
	func performCoreDataOperation(persistentContainer: NSPersistentContainer,
								  dataType: DataType,
								  operation: OperationType,
								  coordinates: (Double, Double)?,
								  address: String?,
								  imageData: Data?,
								  imageName: String?,
								  pin: Pin?,
								  center: (Double, Double)?) {
		
		let viewContext = persistentContainer.viewContext
		
		switch operation {
		case .add:
			switch dataType {
			case .pin:
				let pin = Pin(context: viewContext)
				if let span = center {
					pin.latDelta = span.0
					pin.longDelta = span.1
				}
				pin.creationDate = Date()
				pin.fullAddress = address
				if let lat = coordinates?.0, let long = coordinates?.1 {
					pin.latitude = lat
					pin.longitude = long
				}
			case .photo:
				guard let selectedPin = pin else { return }
				let selectedPhoto = selectedPin.photos?.allObjects as? [Photo]
				if let photoToStore = selectedPhoto?.first {
					selectedPin.addToPhotos(photoToStore)
				}
			}
		case .delete:
			if let imageName = imageName {
				let request = Photo.fetchRequest() as NSFetchRequest<Photo>
				request.predicate = NSPredicate(format: "name = %@", "\(imageName)")
				let result = try? viewContext.fetch(request)
				if let photos = result {
					let photoToDelete = photos[0] as NSManagedObject
					viewContext.delete(photoToDelete)
				}
			}
		}
		
		try? saveData(context: viewContext)
	}
	
	func getDataFromCoreDataStore<T>(persistentContainer: NSPersistentContainer, request: NSFetchRequest<T>, pin: Pin?) throws -> [T] where T : NSFetchRequestResult  {
		
		let viewContext = persistentContainer.viewContext
		
		if type(of: T.self) == Pin.Type.self {
			let pinRequest = Pin.fetchRequest() as NSFetchRequest<Pin>
			let sortByDate = NSSortDescriptor(key: "creationDate", ascending: true)
			pinRequest.sortDescriptors = [sortByDate]
			
			let pins = try fetchRequestObjectData(request: pinRequest, context: viewContext)
			return pins as! [T]
			
		} else if type(of: T.self) == Photo.Type.self {
			if let pin = pin {
				let photoRequest = Photo.fetchRequest() as NSFetchRequest<Photo>
				let predicate = NSPredicate(format: "pin == %@", pin)
				photoRequest.predicate = predicate
				let photos = try fetchRequestObjectData(request: photoRequest, context: viewContext)
				return photos as! [T]
			}  else {
				print(DataControllerError.invalidPin)
				throw DataControllerError.invalidPin
			}
		} else {
			print(DataControllerError.invalidaType)
			throw DataControllerError.invalidaType
		}
	}
	
	//MARK: - Helper methods
	private func fetchRequestObjectData<T>(request: NSFetchRequest<T>, context: NSManagedObjectContext) throws -> [T] where T : NSFetchRequestResult  {
		do {
			let object = try context.fetch(request)
			return object
		} catch {
			print(DataControllerError.fetchingError)
			throw DataControllerError.fetchingError
		}
	}
	
	private func saveData(context: NSManagedObjectContext) throws {
		do {
			try context.save()
		} catch {
			print(DataControllerError.savingError)
			throw DataControllerError.savingError
		}
	}
}
