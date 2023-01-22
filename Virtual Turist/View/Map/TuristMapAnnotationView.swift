//
//  MapAnnotation.swift
//  Virtual Turist
//
//  Created by Valerio D'ALESSIO on 22/1/23.
//

import SwiftUI

struct TuristMapAnnotationView: View {
    var body: some View {
		NavigationLink {
			Text("Go")
		} label: {
			Image(systemName: "mappin")
				.font(.title)
				.tint(.red)
		}

    }
}

struct MapAnnotation_Previews: PreviewProvider {
    static var previews: some View {
        TuristMapAnnotationView()
    }
}
