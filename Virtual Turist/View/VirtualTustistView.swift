//
//  VirtualTustistView.swift
//  Virtual Turist
//
//  Created by Valerio D'ALESSIO on 21/1/23.
//

import CoreData
import MapKit
import SwiftUI

struct VirtualTustistView: View {
	@Environment(\.managedObjectContext) private var viewContext
	@EnvironmentObject var viewModel: DataControllerViewModel
	
	@State private var mapRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.5, longitude: -0.12), span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
	
	@State var mapInitialPosition = CLLocationCoordinate2D(latitude: 51.5, longitude: -0.12)
	@State var mapSpan = MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
	
	@State private var showError = false
	@State var longPressLocation = CGPoint.zero
	@State var fullAddress = ""
	
	var body: some View {
		NavigationView {
			GeometryReader { proxy in
				Map(coordinateRegion: $mapRegion,
					annotationItems: viewModel.pins) { location in
					MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)) {
						NavigationLink {
							PictureCollectionView(searchTerm: Binding<String>(
							get: { location.fullAddress ?? "Unknown" }, set: { _ in }))
						} label: {
							Image(systemName: "mappin")
								.font(.title)
								.tint(.red)
						}
					}
				}
				.gesture(LongPressGesture(
					minimumDuration: 0.25)
					.sequenced(before: DragGesture(
						minimumDistance: 0,
						coordinateSpace: .local))
						.onEnded { gestureValues in
							switch gestureValues {
							case .second(true, let drag):
								/// give a client an aptive feedback
								let _ = UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
								/// get the new coordinates
								longPressLocation = drag?.location ?? .zero
								/// add new location if the full address is valid
								fromPointsToCoordinates(at: longPressLocation, for: proxy.size)
							default:
								break
							}
						})
				.highPriorityGesture(DragGesture(minimumDistance: 10))
				.navigationTitle("Virtual Turist")
			}
		}
		.onAppear {
			/// fetch data on appear
			fetchNewData()
			/// updates the mapRegion
			updateMapRegion(lat: viewModel.pins.last?.latitude ?? 51.5, long: viewModel.pins.last?.longitude ?? -0.12)
		}
		.alert(isPresented: $showError) {
			Alert(title: Text("Error"), message: Text("Cannot place a new pin if the location is not valid"))
		}
	}
	
	//MARK: - Helpers
	
	/// Fetch new data from Core Data
	func fetchNewData() {
		do {
			try viewModel.fetchData()
		} catch {
			showError = true
			print(error.localizedDescription)
		}
	}
	
	/// From CGPoint to CLLocationCoordinate2D
	func fromPointsToCoordinates(at point: CGPoint, for mapSize: CGSize)  {
		
		let latidute = mapRegion.center.latitude
		let longitude = mapRegion.center.longitude

		let mapCenter = CGPoint(x: mapSize.width/2, y: mapSize.height/2)

		// X coordinate
		let xValue = (point.x - mapCenter.x) / mapCenter.x
		let xSpan = xValue * mapRegion.span.longitudeDelta/2

		// Y coordinate
		let yValue = (point.y - mapCenter.y) / mapCenter.y
		let ySpan = yValue * mapRegion.span.latitudeDelta/2

		mapInitialPosition = CLLocationCoordinate2D(latitude: latidute - ySpan, longitude: longitude * xSpan)
		let newLocation = CLLocation(latitude: mapInitialPosition.latitude, longitude: mapInitialPosition.longitude)
		/// update the address
		reverseGeoLocationData(newLocation: newLocation)
	}
	
	/// Update te Center of the Map
	func updateMapRegion(lat: Double, long: Double) {
		mapRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: lat, longitude: long), span: mapSpan)
	}
	
	/// From coordinates gets the location I.E: City and Country
	func reverseGeoLocationData(newLocation: CLLocation) {
		let geoCoder = CLGeocoder()
		geoCoder.reverseGeocodeLocation(newLocation, completionHandler: setNewAddress)
	}
	
	/// Closure of reverseGeocodeLocation that sets the fullAddress property wrapper
	func setNewAddress(placemarks: [CLPlacemark]?, error: Error?) {
		if let placemarks = placemarks, let placemark = placemarks.first {
			if let city = placemark.locality, let country = placemark.country {
				fullAddress = "\(city) \(country)"
				print(fullAddress)
				updateMapRegion(lat: mapInitialPosition.latitude, long: mapInitialPosition.longitude)
				addNewPin()
				/// fetch new data
				fetchNewData()
			} else {
				showError = true
			}
		} else {
			showError = true
		}
	}
	
	/// Add a new Pin to the Map
	func addNewPin() {
		viewModel.dataControllerService.performCoreDataOperation(persistentContainer: viewModel.container, dataType: .pin, operation: .add, coordinates: (mapInitialPosition.latitude, mapInitialPosition.longitude), address: fullAddress, imageData: nil)
	}
}

struct VirtualTustistView_Previews: PreviewProvider {
	
	static let dataControllerService = DataControllerService()
	static let dataControllerViewModel = DataControllerViewModel(dataControllerService: dataControllerService, containerName: "VirtualTuristModel")
	static let context = dataControllerViewModel.container.viewContext
	
	static var previews: some View {
		VirtualTustistView()
			.environment(\.managedObjectContext, context)
			.environmentObject(dataControllerViewModel)
	}
}
