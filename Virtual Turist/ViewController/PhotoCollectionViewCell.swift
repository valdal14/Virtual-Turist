//
//  PhotoCollectionViewCell.swift
//  Virtual Turist
//
//  Created by Valerio D'ALESSIO on 27/1/23.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    
	@IBOutlet weak var photoImage: UIImageView!
	let spinner = UIActivityIndicatorView(style: .large)
	
	override func awakeFromNib() {
		super.awakeFromNib()
		spinner.style = .medium
		spinner.hidesWhenStopped = true
		spinner.center = contentView.center
		contentView.addSubview(spinner)
	}
	
	func setupCell(with photos: [UIImage], indexPath: IndexPath) {
		guard !photos.isEmpty else { return }
		photoImage.image = photos[indexPath.row]
	}
}
