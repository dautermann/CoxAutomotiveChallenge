//
//  Dealer+CoreDataClass.swift
//  CoxAutomotiveChallenge
//
//  Created by Michael Dautermann on 1/25/20.
//  Copyright © 2020 Michael Dautermann. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Dealer)
public class Dealer: NSManagedObject, Decodable {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Dealer> {
        return NSFetchRequest<Dealer>(entityName: "Dealer")
    }

    @NSManaged public var dealerID: Int32
    @NSManaged public var name: String

    enum CodingKeys: String, CodingKey {
        case dealerId
        case name
    }
    
    required convenience public init(from decoder: Decoder) throws {
        guard let context = decoder.userInfo[CodingUserInfoKey.context] as? NSManagedObjectContext else { fatalError() }
        guard let entity = NSEntityDescription.entity(forEntityName: "Dealer", in: context) else { fatalError() }

        self.init(entity: entity, insertInto: context)

        let container = try decoder.container(keyedBy: CodingKeys.self)
        dealerID = try container.decode(Int32.self, forKey: .dealerId)
        name = try container.decode(String.self, forKey: .name)
    }

}
