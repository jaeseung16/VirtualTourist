//
//  Pin+CoreDataClass.swift
//  VirtualTourist
//
//  Created by Jae Seung Lee on 11/28/17.
//  Copyright © 2017 Jae-Seung Lee. All rights reserved.
//
//

import Foundation
import CoreData

public class Pin: NSManagedObject {
    convenience init(longitude: Double, latitude: Double, context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entity(forEntityName: "Pin", in: context) {
            self.init(entity: entity, insertInto: context)
            self.longitude = longitude
            self.latitude = latitude
            self.created = Date()
        } else {
            fatalError("Unable to find the entity name, \"Pin\".")
        }
    }
}
