//
//  PhotoViewController.swift
//  Virtual Turist
//
//  Created by Valerio D'ALESSIO on 25/1/23.
//

import MapKit
import UIKit


class PhotoViewController: UIViewController {
	
	var dataControllerVM: DataControllerViewModel?
	var flickerVM: FlickerViewModel = FlickerViewModel(flickerService: FlickerService())
	
	var selectedPinObject: Pin?
	var pictures: [UIImage] = []
	let noImageLabel = UILabel()
	
	@IBOutlet weak var collectionView: UICollectionView!
	@IBOutlet weak var photoMap: MKMapView!
	@IBOutlet weak var toolbarButton: UIToolbar!
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		setupPhotoMap(pin: selectedPinObject)
		setupNoImagesLabel(with: noImageLabel, numberOfImage: pictures.count)
		do {
			if let pin = selectedPinObject {
				try fetchPictures(selectedPinObject: pin)
			} else {
				showAlert(message: .invalidPin, viewController: self) { _ in
					self.navigationController?.popViewController(animated: true)
				}
			}
		} catch {
			showAlert(message: .errorFetchingPhotos, viewController: self) { _ in
				self.navigationController?.popViewController(animated: true)
			}
		}
	}
	
	private func setupPhotoMap(pin: Pin?){
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
	
	private func fetchPictures(selectedPinObject: Pin) throws {
		/// get a reference to the DataControllerViewModel
		try dataControllerVM?.fetchPictures(selectedPinObject: selectedPinObject)
		let coreDataPhotoArray = dataControllerVM?.photos
		var binaryData: [Data] = []
		if let photoArray = coreDataPhotoArray {
			for img in photoArray {
				if let imgData = img.photoData {
					binaryData.append(imgData)
				}
			}
			/// pass the coredata binary data to the setupCollectionViewWithLocalPictures
			setupCollectionViewWithLocalPictures(binaryData: binaryData)
			
		} else {
			showAlert(message: .errorFetchingPhotos, viewController: self) { _ in
				self.navigationController?.popViewController(animated: true)
			}
		}
	}
	
	
	@IBAction func newCollectionBtn(_ sender: Any) {
		/// get new collection from flickers
		getPhotosFromFlicker {
			/// once the download is completed execute the completion to
			/// start saving the photos into core data
			DispatchQueue.global().async {
				for imgData in self.flickerVM.uiImageBinaryData {
					self.passPhotosToDataController(photoData: imgData)
				}
			}
		}
	}
	
}

//MARK: - CollectionView Data Source
extension PhotoViewController: UICollectionViewDataSource {
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return pictures.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as! PhotoCollectionViewCell
		/// diplay No Images if the pictures array is empty
		setupNoImagesLabel(with: noImageLabel, numberOfImage: pictures.count)
		/// setup a cell or use a placeholder
		cell.setupCell(with: pictures, indexPath: indexPath)
		return cell
	}
}

//MARK: - Setup No Image label
extension PhotoViewController {
	
	private func setupNoImagesLabel(with label: UILabel, numberOfImage: Int){
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

//MARK: - Flicker APIs
extension PhotoViewController {
	private func getPhotosFromFlicker(completion: @escaping () -> Void) {
		Task {
			if let searchTerm = selectedPinObject?.fullAddress {
				do {
					try await flickerVM.combineFetchedData(text: searchTerm)
					/// if the download is completed I can start adding pictures to the
					/// collectionView and remove the No Image label if it is not hidden already
					self.setupCollectionViewWithLocalPictures(binaryData: flickerVM.uiImageBinaryData)
					/// call the completion handler
					completion()
				} catch {
					print(error.localizedDescription)
					showAlert(message: .flickerAPIError, viewController: self) { _ in
						self.navigationController?.popViewController(animated: true)
					}
				}
			}
		}
	}
	
	/// convert binary data into UIImage and add them to the CollectionView
	private func setupCollectionViewWithLocalPictures(binaryData: [Data]) {
		DispatchQueue.main.async {
			var index = 0
			for imgData in binaryData {
				let img = UIImage(data: imgData)
				let indexPath = IndexPath(row: index, section: 0)
				if let image = img {
					self.pictures.append(image)
					self.collectionView.insertItems(at: [indexPath])
					index += 1
				}
			}
		}
	}
}

//MARK: - CoreData Helpers
extension PhotoViewController {
	
	/// Send the binary data to the dataController to perform the insert operation
	private func passPhotosToDataController(photoData: Data){
		if let dataControllerVM = dataControllerVM {
			dataControllerVM.dataControllerService.performCoreDataOperation(persistentContainer: dataControllerVM.container,
																			dataType: .photo,
																			operation: .add,
																			coordinates: nil,
																			address: nil,
																			imageData: photoData)
		} else {
			showAlert(message: .dataControllerError, viewController: self) { _ in
				self.navigationController?.popViewController(animated: true)
			}
		}
	}
}
