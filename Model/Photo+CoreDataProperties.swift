//
//  Photo+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Jae Seung Lee on 11/28/17.
//  Copyright © 2017 Jae-Seung Lee. All rights reserved.
//
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo")
    }

    @NSManaged public var imageData: NSData?
    @NSManaged public var imageURL: String
    @NSManaged public var created: Date
    @NSManaged public var pin: Pin

}
