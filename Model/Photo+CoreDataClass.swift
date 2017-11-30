//
//  Photo+CoreDataClass.swift
//  VirtualTourist
//
//  Created by Jae Seung Lee on 11/28/17.
//  Copyright © 2017 Jae-Seung Lee. All rights reserved.
//
//

import Foundation
import CoreData

public class Photo: NSManagedObject {
    convenience init(url: String, pin: Pin, context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
            self.init(entity: entity, insertInto: context)
            self.imageURL = url
            self.pin = pin
        } else {
            fatalError("Unable to find the entity name, \"Photo\".")
        }
    }
}
