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
}

func showAlert(message: UIError, viewController: UIViewController, completion: alertAction) {
	let alert = UIAlertController(title: "Virtual Turist Error", message: message.rawValue, preferredStyle: .alert)
	alert.addAction(UIAlertAction(title: "OK", style: .default, handler: completion))
	viewController.present(alert, animated: true)
}
