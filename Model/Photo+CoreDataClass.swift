//
//  Photo+CoreDataClass.swift
//  VirtualTourist
//
//  Created by Jae Seung Lee on 11/24/17.
//  Copyright © 2017 Jae-Seung Lee. All rights reserved.
//
//

import Foundation
import CoreData


public class Photo: NSManagedObject {
    // MARK: Initializer
    convenience init(imageData: NSData?, pin: Pin, context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
            self.init(entity: entity, insertInto: context)
            self.imageData = imageData
            self.pin = pin
        } else {
            fatalError("Unable find the entity name \"Photo\".")
        }
    }
}
