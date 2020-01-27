//
//  Vehicle+CoreDataClass.swift
//  CoxAutomotiveChallenge
//
//  Created by Michael Dautermann on 1/25/20.
//  Copyright © 2020 Michael Dautermann. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Vehicle)
public class Vehicle: NSManagedObject, Decodable {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Vehicle> {
        return NSFetchRequest<Vehicle>(entityName: "Vehicle")
    }

    @NSManaged public var vehicleID: Int32
    @NSManaged public var year: Int16
    @NSManaged public var makeString: String
    @NSManaged public var modelString: String
    @NSManaged public var dealerID: Int32

    enum CodingKeys: String, CodingKey {
        case vehicleId
        case year
        case make
        case model
        case dealerId
    }

    required convenience public init(from decoder: Decoder) throws {

        guard let context = decoder.userInfo[CodingUserInfoKey.context] as? NSManagedObjectContext else { fatalError() }
        guard let entity = NSEntityDescription.entity(forEntityName: "Vehicle", in: context) else { fatalError() }

        self.init(entity: entity, insertInto: context)

        let container = try decoder.container(keyedBy: CodingKeys.self)
        vehicleID = try container.decode(Int32.self, forKey: .vehicleId)
        year = try container.decode(Int16.self, forKey: .year)
        makeString = try container.decode(String.self, forKey: .make)
        modelString = try container.decode(String.self, forKey: .model)
        dealerID = try container.decode(Int32.self, forKey: .dealerId)
    }

}
