//
//  PhotoCollectionViewCell.swift
//  Virtual Turist
//
//  Created by Valerio D'ALESSIO on 27/1/23.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    
	@IBOutlet weak var photoImage: UIImageView!
	
	func setupCell(with photos: [Photo], indexPath: IndexPath) {
		guard !photos.isEmpty else { return }
		
		if let data = photos[indexPath.row].photoData {
			photoImage.image = UIImage(data: data)
		} else {
			photoImage.image = UIImage(systemName: "camera.aperture")
		}
	}
}
