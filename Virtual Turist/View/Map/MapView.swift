//
//  MapView.swift
//  Virtual Turist
//
//  Created by Valerio D'ALESSIO on 22/1/23.
//

import MapKit
import SwiftUI

struct MapView: View {
	
	@Binding var mapInitialPosition: CLLocationCoordinate2D
	
	@State private var mapRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.5, longitude: -0.12), span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
	
	@State private var locations = [
		Turist(coordinate: CLLocationCoordinate2D(latitude: 51.501, longitude: -0.141)),
		Turist(coordinate: CLLocationCoordinate2D(latitude: 51.508, longitude: -0.076))
	]
	
	@State private var showAddPin = false
	
	var body: some View {
		NavigationView {
			
			Map(coordinateRegion: $mapRegion, annotationItems: locations) { location in
				MapAnnotation(coordinate: location.coordinate) {
					TuristMapAnnotationView()
						.contextMenu {
							Button {
								showAddPin = true
							} label: {
								Text("View or Add new photos")
							}

						}
				}
			}
			.onLongPressGesture {
				DispatchQueue.main.async {
					locations.append(Turist(coordinate: CLLocationCoordinate2D(latitude: 41.9140229, longitude: 12.4510282)))
				}
			}
			.navigationTitle("Virtual Turist")
		}
	}
}

struct MapView_Previews: PreviewProvider {
	
	@State static var mapInitialPosition = CLLocationCoordinate2D(latitude: 51.5, longitude: -0.12)
	@State static var mapRegion = MKCoordinateRegion(center: mapInitialPosition, span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
	
    static var previews: some View {
		MapView(mapInitialPosition: $mapInitialPosition)
			.edgesIgnoringSafeArea(.all)
    }
}
