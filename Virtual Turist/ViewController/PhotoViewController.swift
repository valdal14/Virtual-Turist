//
//  PhotoViewController.swift
//  Virtual Turist
//
//  Created by Valerio D'ALESSIO on 25/1/23.
//

import MapKit
import UIKit


class PhotoViewController: UIViewController {
	
	var dataControllerVM: DataControllerViewModel!
	var flickerVM: FlickerViewModel!
	
	var selectedPinObject: Pin!
	var selectedImageName: String = ""
	let noImageLabel = UILabel()
	let spinner = UIActivityIndicatorView(style: .large)
	
	@IBOutlet weak var collectionView: UICollectionView!
	@IBOutlet weak var photoMap: MKMapView!
	@IBOutlet weak var toolbarButton: UIToolbar!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		/// hide the new collection button
		toolbarButton.isHidden = true
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		setupPhotoMap(pin: selectedPinObject)
		fetch()
		/**
		 This is going to be triggered if we previously delete all images and
		 we did not pressed on the new collection
		 */
		downloadFromFlicker(photoCount: selectedPinObject?.photos?.count, urlCount: flickerVM.pictureURL.count)
		
	}
	
	/// remove chached data when the view is pop out from the stack
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		flickerVM.removeInMemoryPictureInformation()
		dataControllerVM.photos = []
	}
	
	/// start fetching pictures
	private func fetch() {
		do {
			if let pin = selectedPinObject {
				try fetchPictures(selectedPinObject: pin)
			} else {
				DisplayError.showAlert(message: .invalidPin, viewController: self) { _ in
					self.navigationController?.popViewController(animated: true)
				}
			}
		} catch {
			DisplayError.showAlert(message: .errorFetchingPhotos, viewController: self) { _ in
				self.navigationController?.popViewController(animated: true)
			}
		}
	}
	
	func downloadFromFlicker(photoCount: Int?, urlCount: Int) {
		if let count = photoCount {
			if count == 0 && urlCount == 0 {
				setupSpinner(spinner: self.spinner, isVisible: true)
				/// get new collection from flickers
				getPhotosFromFlicker {
					DispatchQueue.main.async {
						/// stop the spinner once done
						self.setupSpinner(spinner: self.spinner, isVisible: false)
						self.collectionView.reloadData()
					}
				}
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
			DisplayError.showAlert(message: .photoMapNotInitialized, viewController: self) { _ in
				self.navigationController?.popViewController(animated: true)
			}
		}
	}
	
	private func fetchPictures(selectedPinObject: Pin) throws {
		try dataControllerVM.fetchPictures(selectedPinObject: selectedPinObject)
	}
	
	
	@IBAction func newCollectionBtn(_ sender: Any) {
		DispatchQueue.main.async {
			self.noImageLabel.text = ""
		}
		
		var index = 0
		
		for image in dataControllerVM.photos {
			/// delete photo from core data via dataController from core data
			if let imageName = image.name {
				do {
					try dataControllerVM.deletePicture(imageName: imageName)
				} catch {
					DispatchQueue.main.async {
						DisplayError.showAlert(message: .cannotSaveContext, viewController: self) { _ in
							self.navigationController?.popViewController(animated: true)
						}
					}
				}
			}
			index += 1
		}
		
		/// remove all in-memory picture info from the flicker service
		flickerVM.removeInMemoryPictureInformation()
		/// remove all images from dataController
		dataControllerVM.photos = []
		/// start the spinner animation since we start downloading new pictures
		setupSpinner(spinner: spinner, isVisible: true)
		/// reload the collection view
		DispatchQueue.main.async {
			self.collectionView.reloadData()
		}
		
		/// get new collection from flickers
		getPhotosFromFlicker {
			DispatchQueue.main.async {
				/// stop the spinner once done
				self.setupSpinner(spinner: self.spinner, isVisible: false)
				self.collectionView.reloadData()
				
			}
		}
	}
	
}

//MARK: - CollectionView Data Source
extension PhotoViewController: UICollectionViewDataSource {
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return flickerVM.pictureURL.count
//		if let numberOfStoredPictures = selectedPinObject?.photos?.count, numberOfStoredPictures > 0 {
//			return dataControllerVM.photos.count
//		} else {
//			return flickerVM.pictureURL.count
//		}
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as! PhotoCollectionViewCell
		/// setup a cell or use a placeholder
		cell.spinner.startAnimating()
		/// if we have already pictures available and associated with this Map pin we get it
		/// from core data, otherwise we will get from the downloaded URLs
		if let numberOfStoredPictures = selectedPinObject?.photos?.count, numberOfStoredPictures > 0 {
			/// pass the coredata binary data to the setupCollectionViewWithLocalPictures
			if let imgData = dataControllerVM.photos[indexPath.row].photoData {
				cell.photoImage.image = UIImage(data: imgData)
				cell.spinner.stopAnimating()
			}
			/// enable the new collection button
			toolbarButton.isHidden = false
			return cell
		} else {
			/// start fetching images from URLs
			let imgURL = flickerVM.pictureURL[indexPath.row].source
			if let url = URL(string: imgURL) {
				DispatchQueue.global().async {
					let imageData = try! Data(contentsOf: url)
					/// pass the imageData to the dataController to store it in Core data
					self.passPhotosToDataController(photoData: imageData)
					DispatchQueue.main.async {
						cell.photoImage.image = UIImage(data: imageData)
						cell.spinner.stopAnimating()
					}
				}
			}
			/// enable the new collection button
			toolbarButton.isHidden = false
			return cell
		}
	}
}

//MARK: - CollectionView Delegation
extension PhotoViewController: UICollectionViewDelegate {
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		/// remove a picture from core data
		passPhotoToDeleteToDataController(indexPath: indexPath)
		
		DispatchQueue.main.async {
			collectionView.reloadData()
		}
	}
}

//MARK: - UICollectionViewDelegateFlowLayout delegation
extension PhotoViewController: UICollectionViewDelegateFlowLayout {
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		return CGSize(width: 120, height: 120)
	}
}

//MARK: - Flicker APIs
extension PhotoViewController {
	private func getPhotosFromFlicker(completion: @escaping () -> Void) {
		/// start downloading picture in background
		DispatchQueue.global().async {
			Task {
				do {
					if let searchTerm = self.selectedPinObject?.fullAddress {
						try await self.flickerVM.getPicturesFromFlickerService(text: searchTerm)
						completion()
					}
				} catch {
					DisplayError.showAlert(message: .flickerAPIError, viewController: self, completion: nil)
					self.setupSpinner(spinner: self.spinner, isVisible: false)
					self.noImageLabel.isHidden = false
				}
			}
		}
	}
}

//MARK: - CoreData Helpers
extension PhotoViewController {
	
	/// Send the binary data to the dataController to perform the insert operation
	private func passPhotosToDataController(photoData: Data){
		DispatchQueue.global().async {
			/// create a unique image name
			self.selectedImageName = UUID().uuidString
			/// add photo from core data via dataController
			if let pin = self.selectedPinObject {
				do {
					try self.dataControllerVM.savePicture(imageData: photoData, imageName: self.selectedImageName, pin: pin)
				} catch {
					/// handling saving issue or data erase issue
					DispatchQueue.main.async {
						self.collectionView.reloadData()
						//showAlert(message: .cannotSaveContext, viewController: self, completion: nil)
					}
				}
			} else {
				DisplayError.showAlert(message: .invalidPin, viewController: self) { _ in
					self.navigationController?.popViewController(animated: true)
				}
			}
		}
	}
	
	/// delete selected photo from memory and core data
	private func passPhotoToDeleteToDataController(indexPath: IndexPath) {
		/// get the image name I want to delete from core data
		let imageName = dataControllerVM.photos[indexPath.row].name
		if let imageName = imageName {
			do {
				/// remove the image from the dataController first
				dataControllerVM.photos.remove(at: indexPath.row)
				/// delete photo from core data via dataController from core data
				try dataControllerVM.deletePicture(imageName: imageName)
				/// also remove the pictureURL at indexPath if the state is .flickerAPI
				if !flickerVM.pictureURL.isEmpty {
					flickerVM.pictureURL.remove(at: indexPath.row)
				}
				
				/// show no image if no images all images have been deleted
				if dataControllerVM.photos.isEmpty || flickerVM.pictureURL.isEmpty {
					setupNoImagesLabel(with: noImageLabel, numberOfImage: dataControllerVM.photos.count)
					toolbarButton.isHidden = false
				}
				
			} catch {
				DispatchQueue.main.async {
					DisplayError.showAlert(message: .cannotSaveContext, viewController: self, completion: nil)
				}
			}
			
		} else {
			DisplayError.showAlert(message: .cannotDeleteImage, viewController: self, completion: nil)
		}
	}
}
