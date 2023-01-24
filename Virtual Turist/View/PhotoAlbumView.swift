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
						AsyncImage(url: url) { image in
							image.resizable()
								.padding(3)
								.aspectRatio(contentMode: .fit)
								.cornerRadius(20)
								.frame(width: 140,
									   height: 140)
								.contextMenu {
									Button {
										// here we delete the selected image
										flickerVM.urls.removeAll { picUrl in
											picUrl == url
										}
									} label: {
										Text("Delete Image")
									}

								}
						} placeholder: {
							ProgressView()
						}
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
        
			
    }
}

struct PictureCollectionView_Previews: PreviewProvider {
	
	@State static var searchTearm: String = "Albacete Spain"
	
    static var previews: some View {
		PhotoAlbumView(searchTerm: $searchTearm)
    }
}
