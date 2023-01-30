//
//  PhotoViewController+UIExtensions.swift
//  Virtual Turist
//
//  Created by Valerio D'ALESSIO on 29/1/23.
//

import Foundation
import UIKit

//MARK: - Helper function to setup label and spinner indicator
extension PhotoViewController {
	
	public func setupNoImagesLabel(with label: UILabel, numberOfImage: Int){
		if numberOfImage == 0 {
			label.text = "No Images"
			label.font = UIFont.systemFont(ofSize: 24)
			label.textColor = .black
			/// add the new label
			view.addSubview(label)
			label.frame = CGRect(x: 0, y: 0, width: 200, height: 50)
			/// constraints and placement
			label.center = view.center
			label.translatesAutoresizingMaskIntoConstraints = false
			label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
			label.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
			label.isHidden = false
		} else {
			label.isHidden = true
		}
	}
	
	public func setupSpinner(spinner: UIActivityIndicatorView, isVisible: Bool) {
			view.addSubview(spinner)
			spinner.translatesAutoresizingMaskIntoConstraints = false
			spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
			spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
			isVisible ? spinner.startAnimating() : spinner.stopAnimating()
		}
}
