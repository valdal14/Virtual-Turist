//
//  Pin+CoreDataProperties.swift
//  Virtual Turist
//
//  Created by Valerio D'ALESSIO on 29/1/23.
//
//

import Foundation
import CoreData


extension Pin {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Pin> {
        return NSFetchRequest<Pin>(entityName: "Pin")
    }

    @NSManaged public var creationDate: Date?
    @NSManaged public var fullAddress: String?
    @NSManaged public var latDelta: Double
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var longDelta: Double
    @NSManaged public var photos: NSSet?

}

// MARK: Generated accessors for photos
extension Pin {

    @objc(addPhotosObject:)
    @NSManaged public func addToPhotos(_ value: Photo)

    @objc(removePhotosObject:)
    @NSManaged public func removeFromPhotos(_ value: Photo)

    @objc(addPhotos:)
    @NSManaged public func addToPhotos(_ values: NSSet)

    @objc(removePhotos:)
    @NSManaged public func removeFromPhotos(_ values: NSSet)

}

extension Pin : Identifiable {

}
