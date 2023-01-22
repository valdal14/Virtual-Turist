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
	
	@State private var locations = [
		Turist(coordinate: CLLocationCoordinate2D(latitude: 51.501, longitude: -0.141)),
		Turist(coordinate: CLLocationCoordinate2D(latitude: 51.508, longitude: -0.076))
	]
	
	@State var mapInitialPosition = CLLocationCoordinate2D(latitude: 51.5, longitude: -0.12)
	
	@FetchRequest(
		sortDescriptors: [NSSortDescriptor(keyPath: \Pin.id, ascending: true)],
		animation: .default)
	
	private var pins: FetchedResults<Pin>
	
	@State private var showError = false
	@State var longPressLocation = CGPoint.zero
	
	var body: some View {
		NavigationView {
			GeometryReader { proxy in
				Map(coordinateRegion: $mapRegion, annotationItems: pins) { location in
					MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)) {
						NavigationLink {
							Text(location.debugDescription)
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
								mapInitialPosition = CLLocationCoordinate2D(latitude: longPressLocation.x, longitude: longPressLocation.y)
								/// add new location
								viewModel.dataControllerService.performCoreDataOperation(persistentContainer: viewModel.container, dataType: .pin, operation: .add, coordinates: (mapInitialPosition.latitude, mapInitialPosition.longitude), imageData: nil)
								/// fetch new data
								do {
									try viewModel.fetchData()
									print(viewModel.dataControllerService.pins?.count ?? 0)
								} catch {
									showError.toggle()
									print(error.localizedDescription)
								}
							default:
								break
							}
						})
				.highPriorityGesture(DragGesture(minimumDistance: 10))
//				.onLongPressGesture {
//					mapInitialPosition = CLLocationCoordinate2D(latitude: 51.501, longitude: -0.141)
//					// append the new location
//					viewModel.dataControllerService.performCoreDataOperation(persistentContainer: viewModel.container, dataType: .pin, operation: .add, coordinates: (mapInitialPosition.latitude, mapInitialPosition.longitude), imageData: nil)
//					do {
//						try viewModel.fetchData()
//						print(viewModel.dataControllerService.pins?.count ?? 0)
//					} catch {
//						showError.toggle()
//						print(error.localizedDescription)
//					}
//				}
				.navigationTitle("Virtual Turist")
			}
		}
		.alert(isPresented: $showError) {
			Alert(title: Text("Errot"), message: Text("Error placing a new pin"))
		}
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
