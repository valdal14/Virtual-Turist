//
//  Photo+CoreDataProperties.swift
//  Virtual Turist
//
//  Created by Valerio D'ALESSIO on 27/1/23.
//
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo")
    }

    @NSManaged public var photoData: Data?
    @NSManaged public var pin: Pin?

}

extension Photo : Identifiable {

}
