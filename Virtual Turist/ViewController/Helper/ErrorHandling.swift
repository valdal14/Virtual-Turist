//
//  ErrorHandling.swift
//  Virtual Turist
//
//  Created by Valerio D'ALESSIO on 26/1/23.
//

import Foundation
import UIKit

typealias alertAction = ((UIAlertAction) -> Void)?

enum UIError: String, Error {
	case invalidAnnotation = "Cannot get the annotation information from the MAP"
	case photoMapNotInitialized = "The Map cannot be instanciated with the given coordinates"
	case flickerAPIError = "Cannot get images from the server"
	case invalidPin = "Cannot create a Map PIN"
	case errorFetchingPin = "Error while trying to fetch Map Pins from store"
	case errorFetchingPhotos = "Error while trying to fetch Photos from store"
	case dataControllerError = "Data controller is not responding, please try again"
}

func showAlert(message: UIError, viewController: UIViewController, completion: alertAction) {
	let alert = UIAlertController(title: "Virtual Turist Error", message: message.rawValue, preferredStyle: .alert)
	alert.addAction(UIAlertAction(title: "OK", style: .default, handler: completion))
	viewController.present(alert, animated: true)
}
