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
							Text(fullAddress)
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
								if !showError {
									/// give a client an aptive feedback
									let _ = UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
									/// get the new coordinates
									longPressLocation = drag?.location ?? .zero
									fromPointsToCoordinates(at: longPressLocation, for: proxy.size)
									/// add new location
									viewModel.dataControllerService.performCoreDataOperation(persistentContainer: viewModel.container, dataType: .pin, operation: .add, coordinates: (mapInitialPosition.latitude, mapInitialPosition.longitude), address: fullAddress, imageData: nil)
									/// fetch new data
									fetchNewData()
								}
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
			updateMapRegion(lat: viewModel.pins.last?.latitude ?? 51.5, long: viewModel.pins.last?.longitude ?? -0.12)
		}
		.alert(isPresented: $showError) {
			Alert(title: Text("Errot"), message: Text("Error placing a new pin"))
		}
	}
	
	//MARK: - Helpers
	func fetchNewData() {
		do {
			try viewModel.fetchData()
			print(viewModel.pins.count)
		} catch {
			showError.toggle()
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
		updateMapRegion(lat: mapInitialPosition.latitude, long: mapInitialPosition.longitude)
		let newLocation = CLLocation(latitude: mapInitialPosition.latitude, longitude: mapInitialPosition.longitude)
		/// get the address
		let geoCoder = CLGeocoder()
		geoCoder.reverseGeocodeLocation(newLocation) { placemarks, error in
			guard let placemarks = placemarks, let placemark = placemarks.first else {
				showError.toggle()
				return
			}
			if let city = placemark.locality, let country = placemark.country {
				fullAddress = "\(city), \(country)"
			} else {
				showError.toggle()
			}
			
		}
	}
	
	func updateMapRegion(lat: Double, long: Double) {
		mapRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: lat, longitude: long), span: mapSpan)
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
