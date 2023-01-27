//
//  PhotoViewController.swift
//  Virtual Turist
//
//  Created by Valerio D'ALESSIO on 25/1/23.
//

import MapKit
import UIKit


class PhotoViewController: UIViewController {

	var dataController: DataControllerViewModel?
	var flickerVM: FlickerViewModel = FlickerViewModel(flickerService: FlickerService())
	
	var selectedPinObject: Pin?
	var photos: [Photo] = []
	let noImageLabel =  UILabel()
	
	@IBOutlet weak var collectionView: UICollectionView!
	@IBOutlet weak var photoMap: MKMapView!
	@IBOutlet weak var toolbarButton: UIToolbar!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		setupPhotoMap(pin: selectedPinObject)
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		Task {
			if let searchTerm = selectedPinObject?.fullAddress {
				do {
					try await flickerVM.combineFetchedData(text: searchTerm)
				} catch {
					print(error.localizedDescription)
				}
			}
		}
	}
	
	func setupPhotoMap(pin: Pin?){
		if let pin = pin {
			let selectedPinCoordinates = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
			let photoMapRegion = MKCoordinateRegion(center: selectedPinCoordinates, span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
			/// set the map region
			photoMap.setRegion(photoMapRegion, animated: true)
			/// create a new annotation
			let newPinAnnotation = MKPointAnnotation()
			newPinAnnotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
			newPinAnnotation.title = pin.fullAddress
			photoMap.addAnnotation(newPinAnnotation)
			DispatchQueue.main.async {
				self.photoMap.reloadInputViews()
			}
		} else {
			/// show error message and pops back to MapViewController
			showAlert(message: .photoMapNotInitialized, viewController: self) { _ in
				self.navigationController?.popViewController(animated: true)
			}
		}
	}
	
	
	@IBAction func newCollectionBtn(_ sender: Any) {
		// check the label No Images ToDO
	}
	
}

//MARK: - CollectionView Data Source
extension PhotoViewController: UICollectionViewDataSource {
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return 10
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as! PhotoCollectionViewCell
		/// diplay No Images if the photos array is empty
		setupNoImagesLabel(with: noImageLabel, numberOfImage: photos.count)
		/// setup a cell or use a placeholder
		cell.setupCell(with: photos, indexPath: indexPath)
		return cell
	}
}

//MARK: - Setup No Image label
extension PhotoViewController {
	
	func setupNoImagesLabel(with label: UILabel, numberOfImage: Int){
		if numberOfImage == 0 {
			label.text = "No Images"
			label.font = UIFont.systemFont(ofSize: 24)
			label.textColor = .black
			/// add the new label
			view.addSubview(label)
			label.frame = CGRect(x: 0, y: 0, width: 200, height: 50)
			/// constraints and placement
			label.center = view.center
			label.translatesAutoresizingMaskIntoConstraints = false
			label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
			label.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
			label.isHidden = false
		} else {
			label.isHidden = true
		}
	}
}
