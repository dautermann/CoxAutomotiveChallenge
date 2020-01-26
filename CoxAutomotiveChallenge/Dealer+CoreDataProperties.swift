//
//  Dealer+CoreDataProperties.swift
//  CoxAutomotiveChallenge
//
//  Created by Michael Dautermann on 1/25/20.
//  Copyright © 2020 Michael Dautermann. All rights reserved.
//
//

import Foundation
import CoreData


extension Dealer {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Dealer> {
        return NSFetchRequest<Dealer>(entityName: "Dealer")
    }

    @NSManaged public var dealerID: Int32
    @NSManaged public var name: String?

}
