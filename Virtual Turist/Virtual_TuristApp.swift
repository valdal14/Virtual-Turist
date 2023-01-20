//
//  Virtual_TuristApp.swift
//  Virtual Turist
//
//  Created by Valerio D'ALESSIO on 20/1/23.
//

import SwiftUI

@main
struct Virtual_TuristApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
