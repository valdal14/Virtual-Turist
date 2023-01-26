//
//  PhotoViewController.swift
//  Virtual Turist
//
//  Created by Valerio D'ALESSIO on 25/1/23.
//

import MapKit
import UIKit


class PhotoViewController: UIViewController {

	var selectedPinAnnotation: MKAnnotation?
	
	@IBOutlet weak var photoMap: MKMapView!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		setupPhotoMap(pin: selectedPinAnnotation)
    }
	
	func setupPhotoMap(pin: MKAnnotation?){
		if let pin = pin {
			let selectedPinCoordinates = CLLocationCoordinate2D(latitude: pin.coordinate.latitude, longitude: pin.coordinate.longitude)
			let photoMapRegion = MKCoordinateRegion(center: selectedPinCoordinates, span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
			/// set the map region
			photoMap.setRegion(photoMapRegion, animated: true)
			photoMap.addAnnotation(pin)
			DispatchQueue.main.async {
				self.photoMap.reloadInputViews()
			}
		} else {
			showAlert(message: .photoMapNotInitialized, viewController: self, completion: nil)
		}
	}
}
