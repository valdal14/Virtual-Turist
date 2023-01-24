//
//  PhotoAlbumView.swift
//  Virtual Turist
//
//  Created by Valerio D'ALESSIO on 23/1/23.
//

import SwiftUI

struct PhotoAlbumView: View {
	@Environment(\.managedObjectContext) private var viewContext
	@ObservedObject var flickerVM = FlickerViewModel(flickerService: FlickerService())
	@EnvironmentObject var viewModel: DataControllerViewModel
	@Binding var searchTerm: String
	@Binding var selectedPing: Pin
	@State private var showError = false
	
	let columns: [GridItem] = [GridItem(.fixed(150), spacing: 5, alignment: .center),
							   GridItem(.fixed(150), spacing: 5, alignment: .center),
							   GridItem(.fixed(150), spacing: 5, alignment: .center)]
	
	var body: some View {
		VStack {
			Text("Photos from \(searchTerm)")
				.font(.headline)
			ScrollView {
				LazyVGrid(columns: columns) {
					ForEach(flickerVM.urls, id: \.absoluteString) { url in
						if selectedPing.photos?.count == 0 {
							AsyncImage(url: url) { phase in
								if let image = phase.image {
									image.resizable()
										.onAppear {
											flickerVM.saveImages(img: image, pin: selectedPing)
										}
										.padding(3)
										.aspectRatio(contentMode: .fit)
										.cornerRadius(20)
										.frame(width: 140,
											   height: 140)
										.contextMenu {
											Button {
												// here we delete the selected image using selectedPing
												flickerVM.urls.removeAll { picUrl in
													picUrl == url
												}
											} label: {
												Text("Delete Image")
											}
											
										}
								} else if phase.error != nil {
									Text("No Images")
										.font(.headline)
										.foregroundColor(.accentColor)
								} else {
									Image(systemName: "camera.aperture")
										.resizable()
										.tint(.gray)
										.opacity(0.5)
										.aspectRatio(contentMode: .fit)
										.frame(width: 50, height: 50)
								}
							}
						} else {
							Text("Load Images from core data")
						}
					}
				}
			}
			.padding()
			.onAppear {
				Task {
					do {
						try await flickerVM.combineFetchedData(text: searchTerm)
					} catch {
						showError = flickerVM.apiError
					}
				}
			}
			.alert(isPresented: $showError) {
				Alert(title: Text("Error"), message: Text("An error occurred while retrieving images"))
			}
			
			ZStack {
				if flickerVM.donwloadCompled {
					Button {
						//
					} label: {
						Text("New Collection")
							.foregroundColor(.primary)
					}
					.frame(width: UIScreen.main.bounds.width, height: 60)
				}
			}
			.background(flickerVM.donwloadCompled ? Color.accentColor : Color.primary)
			
		}
	}
}

struct PictureCollectionView_Previews: PreviewProvider {
	
	@State static var searchTearm: String = "Albacete Spain"
	@State static var selectedPIN: Pin = Pin(context: DataControllerViewModel(dataControllerService: DataControllerService(), containerName: "VirtualTuristModel").container.viewContext)
	
	static var previews: some View {
		PhotoAlbumView(searchTerm: $searchTearm, selectedPing: $selectedPIN)
	}
}
