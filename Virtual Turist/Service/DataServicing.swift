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
	func performCoreDataOperation(persistentContainer: NSPersistentContainer, dataType: DataType, operation: OperationType, coordinates: (Double,Double)?, imageData: Data?)
	func getDataFromCoreDataStore<T>(persistentContainer: NSPersistentContainer, request: NSFetchRequest<T>) throws -> [T]
}

//MARK: - Enums
enum DataControllerError: String, Error {
	case savingError = "Error while trying to save data"
	case invalidaType = "The given type is not recognized"
	case fetchingError = "Error while trying to fetch data"
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
	func performCoreDataOperation(persistentContainer: NSPersistentContainer, dataType: DataType, operation: OperationType, coordinates: (Double, Double)?, imageData: Data?) {
		let viewContext = persistentContainer.viewContext
		
		switch operation {
		case .add:
			switch dataType {
			case .pin:
				let pin = Pin(context: viewContext)
				pin.id = UUID().uuidString
				if let lat = coordinates?.0, let long = coordinates?.1 {
					pin.latitude = lat
					pin.longitude = long
				}
			case .photo:
				let photo = Photo(context: viewContext)
				photo.photoData = imageData
			}
		case .delete:
			break
		}
		
		try? saveData(context: viewContext)
	}
	
	func getDataFromCoreDataStore<T>(persistentContainer: NSPersistentContainer, request: NSFetchRequest<T>) throws -> [T] where T : NSFetchRequestResult  {
		
		let viewContext = persistentContainer.viewContext
		
		if type(of: T.self) == Pin.Type.self {
			let pinRequest = Pin.fetchRequest() as NSFetchRequest<Pin>
			let sortByDate = NSSortDescriptor(key: "creationDate", ascending: true)
			pinRequest.sortDescriptors = [sortByDate]
			
			let pins = try fetchRequestObjectData(request: pinRequest, context: viewContext)
			return pins as! [T]
			
		} else if type(of: T.self) == Photo.Type.self {
			let photoRequest = Photo.fetchRequest() as NSFetchRequest<Photo>
			let photos = try fetchRequestObjectData(request: photoRequest, context: viewContext)
			return photos as! [T]
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
