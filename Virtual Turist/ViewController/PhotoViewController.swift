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
	var selectedImageName: String = ""
	var pictures: [UIImage] = []
	let noImageLabel = UILabel()
	
	@IBOutlet weak var collectionView: UICollectionView!
	@IBOutlet weak var photoMap: MKMapView!
	@IBOutlet weak var toolbarButton: UIToolbar!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		/// configure a swipe gesture to delete on collection view
		let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
		swipeGesture.direction = .left
		collectionView.addGestureRecognizer(swipeGesture)
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

//MARK: - CollectionView Delegation
extension PhotoViewController: UICollectionViewDelegate {
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		// TODO - Open the picture
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
			/// create a unique image name
			selectedImageName = UUID().uuidString
			/// add photo from core data via dataController
			if let pin = selectedPinObject {
				dataControllerVM.savePicture(imageData: photoData, imageName: selectedImageName, pin: pin)
			} else {
				showAlert(message: .invalidPin, viewController: self) { _ in
					self.navigationController?.popViewController(animated: true)
				}
			}
		} else {
			showAlert(message: .dataControllerError, viewController: self) { _ in
				self.navigationController?.popViewController(animated: true)
			}
		}
	}
	
	/// delete selected photo from memory and core data
	private func passPhotoToDeleteToDataController(indexPath: IndexPath) {
		if let dataControllerVM = dataControllerVM {
			/// get the image name I want to delete from core data
			let imageName = dataControllerVM.photos[indexPath.row].name
			if let imageName = imageName {
				/// delete photo from core data via dataController
				dataControllerVM.deletePicture(imageName: imageName)
			} else {
				showAlert(message: .cannotDeleteImage, viewController: self, completion: nil)
			}
		} else {
			showAlert(message: .cannotDeleteImage, viewController: self, completion: nil)
		}
	}
	
	@objc func handleSwipe(gesture: UISwipeGestureRecognizer) {
		if gesture.direction == .left {
			// set the name of the selected picture
			/// handle left swipe
			let location = gesture.location(in: self.collectionView)
			/// get the location
			let indexPath = self.collectionView.indexPathForItem(at: location)
			if let indexPath = indexPath {
				passPhotoToDeleteToDataController(indexPath: indexPath)
				/// remove the picture from the pictures array
				pictures.remove(at: indexPath.row)
				/// remove from the collection view
				collectionView.deleteItems(at: [indexPath])
			} else {
				showAlert(message: .cannotDeleteImage, viewController: self, completion: nil)
			}
		}
	}
}
