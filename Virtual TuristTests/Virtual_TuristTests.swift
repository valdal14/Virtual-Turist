//
//  Virtual_TuristTests.swift
//  Virtual TuristTests
//
//  Created by Valerio D'ALESSIO on 22/1/23.
//

import CoreData
import XCTest
@testable import Virtual_Turist

final class Virtual_TuristTests: XCTestCase {
	
	func test_NSFetchRequestPinTypeDoesNotThrow() throws {
		let request = Pin.fetchRequest() as NSFetchRequest<Pin>
		let dataControllerService = DataControllerService()
		let dataControllerVM = DataControllerViewModel(dataControllerService: dataControllerService, containerName: "VirtualTuristModel")
		let sut = DataControllerService()
		
		XCTAssertNoThrow(try sut.getDataFromCoreDataStore(persistentContainer: dataControllerVM.container, request: request))
	}
	
	func test_NSFetchRequestPhotoTypeDoesNotThrow() throws {
		let request = Photo.fetchRequest() as NSFetchRequest<Photo>
		let dataControllerService = DataControllerService()
		let dataControllerVM = DataControllerViewModel(dataControllerService: dataControllerService, containerName: "VirtualTuristModel")
		let sut = DataControllerService()
		
		XCTAssertNoThrow(try sut.getDataFromCoreDataStore(persistentContainer: dataControllerVM.container, request: request))
	}
	
	func test_FlickerServiceURLDoesNotThrow() throws {
		let sut = FlickerService()
		
		XCTAssertNoThrow(try sut.createFlickerSearchURL(endpointURL: "https://api.flickr.com/services/rest/?method=",
												  method: "flickr.photos.search",
										 apiKey: "123456",
										 text: "dog",
										 maxPictures: 5))
	}
	
	func test_FlickerServiceProducedValidURLString() throws {
		let sut = FlickerService()
		let url = try? sut.createFlickerSearchURL(endpointURL: "https://api.flickr.com/services/rest/?method=",
									   method: "flickr.photos.search",
									   apiKey: "123456",
									   text: "dog",
									   maxPictures: 5)
		
		let urlString = url?.absoluteString
		let excpectedUrlString = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=123456&text=dog&per_page=5&format=json&nojsoncallback=1"
		XCTAssertEqual(urlString, excpectedUrlString)
	}
	
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
