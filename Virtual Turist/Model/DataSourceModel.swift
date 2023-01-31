//
//  DataSourceModel.swift
//  Virtual Turist
//
//  Created by Valerio D'ALESSIO on 31/1/23.
//

import Foundation

struct DSModel {
	
	enum PinState {
		case new
		case old
	}
	
	static func setPinState(newPin: Bool) -> PinState {
		newPin ? .new : .old
	}
}
