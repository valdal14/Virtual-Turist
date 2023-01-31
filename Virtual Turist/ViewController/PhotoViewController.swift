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
	var selectedPinState: DSModel.PinState!
	var selectedPinObject: Pin!
	var selectedImageName: String = ""
	let noImageLabel = UILabel()
	let spinner = UIActivityIndicatorView(style: .large)
	
	@IBOutlet weak var collectionView: UICollectionView!
	@IBOutlet weak var photoMap: MKMapView!
	@IBOutlet weak var toolbarButton: UIToolbar!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		getPhotosByDataSourceState(pictures: flickerVM.pictureData)
		toolbarButton.isHidden = true
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		setupPhotoMap(pin: selectedPinObject)
	}
	
	/// remove chached data when the view is pop out from the stack
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		flickerVM.removeInMemoryPictureInformation()
		dataControllerVM.photos = []
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
		dataControllerVM.photos.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as! PhotoCollectionViewCell
		/// setup a cell or use a placeholder
		cell.spinner.startAnimating()
		
		let data = self.dataControllerVM.photos[indexPath.row].photoData
		
		if let coreDataImageData = data {
			DispatchQueue.main.async {
				cell.photoImage.image = UIImage(data: coreDataImageData)
				cell.spinner.stopAnimating()
			}
		}
		
		/// enable the new collection button
		toolbarButton.isHidden = false
		return cell
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

//MARK: - CoreData Helpers
extension PhotoViewController {
	
	func getPhotosByDataSourceState(pictures: [Picture]){
		switch selectedPinState {
		case .new:
			Task {
				for pic in pictures {
					do {
						try await flickerVM.getPhotoSizeURL(photoId: pic.id, pin: selectedPinObject, dataController: dataControllerVM)
						DispatchQueue.main.async {
							self.collectionView.reloadData()
						}
					} catch {
						DisplayError.showAlert(message: .flickerAPIError, viewController: self) { _ in
							self.navigationController?.popViewController(animated: true)
						}
					}
				}
			}
		case .old:
			do {
				/// fetch pictures from core data
				try dataControllerVM.fetchPictures(selectedPinObject: selectedPinObject)
				DispatchQueue.main.async {
					self.collectionView.reloadData()
				}
			} catch {
				DisplayError.showAlert(message: .errorFetchingPhotos, viewController: self) { _ in
					self.navigationController?.popViewController(animated: true)
				}
			}
		case .none:
			DisplayError.showAlert(message: .noGivenState, viewController: self) { _ in
				self.navigationController?.popViewController(animated: true)
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
