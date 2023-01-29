//
//  Photo+CoreDataProperties.swift
//  Virtual Turist
//
//  Created by Valerio D'ALESSIO on 29/1/23.
//
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo")
    }

    @NSManaged public var name: String?
    @NSManaged public var photoData: Data?
    @NSManaged public var pin: Pin?

}

extension Photo : Identifiable {

}
