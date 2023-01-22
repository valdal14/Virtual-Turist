//
//  Virtual_TuristApp.swift
//  Virtual Turist
//
//  Created by Valerio D'ALESSIO on 21/1/23.
//

import SwiftUI

@main
struct Virtual_TuristApp: App {
	
	let dataControllerService = DataControllerService()
	
    var body: some Scene {
		
		let dataControllerViewModel: DataControllerViewModel = DataControllerViewModel(dataControllerService: self.dataControllerService, containerName: "VirtualTuristModel")
		
        WindowGroup {
			VirtualTustistView()
				.environment(\.managedObjectContext, dataControllerViewModel.container.viewContext)
				.environmentObject(dataControllerViewModel)
        }
    }
}
