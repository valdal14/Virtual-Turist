//
//  MapViewController.swift
//  Virtual Turist
//
//  Created by Valerio D'ALESSIO on 25/1/23.
//

import MapKit
import UIKit

enum MapError: String, Error {
	case geoCodeError = "Cannot extract any valid address from the current coordinates"
}

class MapViewController: UIViewController, UIGestureRecognizerDelegate {
	
	let appDelegate = UIApplication.shared.delegate as! AppDelegate
	var flickerVM: FlickerViewModel = FlickerViewModel(flickerService: FlickerService())
	
	@IBOutlet weak var map: MKMapView!
	
	var longPressGesture = UILongPressGestureRecognizer()
	var longPressActive = false
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		/// map gesture configuration
		longPressGesture.delegate = self
		longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressHandler))
		/// assign the gesture to the map
		map.addGestureRecognizer(longPressGesture)
		/// fetch pin annotations
		do {
			try fetchMapAnnotation()
		} catch {
			DisplayError.showAlert(message: .errorFetchingPin, viewController: self, completion: nil)
		}
	}
	
	@objc func longPressHandler(_ gesture: UITapGestureRecognizer) {
		if gesture.state == .began {
			/// control the gesture behaviour
			guard longPressActive == false else { return }
			longPressActive.toggle()
			/// give the user an aptive feedback
			UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
			/// get the position on the screen in CGPoint
			let positionOnTheMap = longPressGesture.location(in: map)
			/// get the coordinates from the position
			let coordinate = map.convert(positionOnTheMap, toCoordinateFrom: map)
			/// get the CLLocation from the coordinates
			let newPin = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
			/// reverse geocode location to get the country and city
			performReverseGeoLocation(newPin: newPin, coordinate: coordinate)
		}
	}
	
	//MARK: - Helper functions
	private func performReverseGeoLocation(newPin: CLLocation, coordinate: CLLocationCoordinate2D) {
		CLGeocoder().reverseGeocodeLocation(newPin) { placemarks, error in
			if let placemark = placemarks?.first {
				if let country = placemark.country, let city = placemark.locality {
					/// add new annotation
					let annotation = MKPointAnnotation()
					annotation.coordinate = coordinate
					annotation.title = "\(city) \(country)"
					self.map.addAnnotation(annotation)
					/// start downloading picture in background
					DispatchQueue.global().async {
						Task {
							do {
								try await self.flickerVM.getPicturesFromFlickerService(text: "\(city) \(country)")
							} catch {
								DisplayError.showAlert(message: .flickerAPIError, viewController: self) { _ in
									self.map.removeAnnotation(annotation)
								}
							}
						}
					}
					/// send the pin to dataController that will interact with Core Data
					self.passPinToDataController(annotation: annotation)
				}
			}
		}
	}
	
	private func fetchMapAnnotation() throws {
		/// get a reference to the DataControllerViewModel
		let dataControllerVM = appDelegate.dataControllerVM
		try dataControllerVM.fetchMapPins(pin: nil)
		/// populate the map with stored annotation
		for pin in dataControllerVM.pins {
			let annotation = MKPointAnnotation()
			annotation.title = pin.fullAddress
			annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
			DispatchQueue.main.async {
				self.map.addAnnotation(annotation)
				/// set the center and zoom of the last visited pin
				self.map.region = MKCoordinateRegion(center: annotation.coordinate, span: MKCoordinateSpan(latitudeDelta: pin.latDelta, longitudeDelta: pin.longDelta))
			}
		}
		/// reload the map
		DispatchQueue.main.async {
			self.map.reloadInputViews()
		}
	}
	
	private func passPinToDataController(annotation: MKAnnotation){
		/// get a reference to the DataControllerViewModel
		let dataControllerVM = appDelegate.dataControllerVM
		if let annotationTitle = annotation.title, let annotationAddress = annotationTitle {
			/// save pin
			do {
				try dataControllerVM.savePin(coordinates: (annotation.coordinate.latitude, annotation.coordinate.longitude),
										 address: annotationAddress, pin: nil,
										 span: (map.region.span.latitudeDelta, map.region.span.longitudeDelta))
				/// toggle the long gesture again once we saved the new location
				self.longPressActive.toggle()
			} catch {
				DispatchQueue.main.async {
					DisplayError.showAlert(message: .cannotSaveContext, viewController: self, completion: nil)
				}
			}
			
		} else {
			DisplayError.showAlert(message: .invalidAnnotation, viewController: self, completion: nil)
		}
	}
	
}

//MARK: - Map Delegation methods
extension MapViewController: MKMapViewDelegate {
	
	/// triggered when we press an annotation, we pass the pin to the next VC
	func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
		if let _ = annotation.title {
			let photoMapVC = storyboard?.instantiateViewController(withIdentifier: "photoVC") as! PhotoViewController
			photoMapVC.dataControllerVM = appDelegate.dataControllerVM
			/// get the ping back from dataController
			photoMapVC.selectedPinObject = appDelegate.dataControllerVM.fetchSelectedPin(coordinates: (annotation.coordinate.latitude, annotation.coordinate.longitude))
			photoMapVC.flickerVM = flickerVM
			show(photoMapVC, sender: self)
		} else {
			DisplayError.showAlert(message: .invalidAnnotation, viewController: self, completion: nil)
		}
	}
}

