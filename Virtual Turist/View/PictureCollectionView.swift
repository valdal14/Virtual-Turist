//
//  PictureCollectionView.swift
//  Virtual Turist
//
//  Created by Valerio D'ALESSIO on 23/1/23.
//

import SwiftUI

struct PictureCollectionView: View {
	@Environment(\.managedObjectContext) private var viewContext
	@ObservedObject var flickerVM = FlickerViewModel(flickerService: FlickerService())
	@EnvironmentObject var viewModel: DataControllerViewModel
	@Binding var searchTerm: String
	@State private var showError = false
	
    var body: some View {
        Text(searchTerm)
			.onAppear {
				Task {
					do {
						try await flickerVM.getPictures(text: searchTerm)
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
		PictureCollectionView(searchTerm: $searchTearm)
    }
}
