//
//  Vehicle.swift
//  CoxAutomotiveChallenge
//
//  Created by Michael Dautermann on 1/25/20.
//  Copyright © 2020 Michael Dautermann. All rights reserved.
//

import UIKit

struct Vehicle: Decodable {
    var vehicleID : Int
    var year : Int
    var makeString : String
    var modelString : String
    var dealerID : Int
    
    enum CodingKeys: String, CodingKey {
        case vehicleId
        case year
        case make
        case model
        case dealerId
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        vehicleID = try container.decode(Int.self, forKey: .vehicleId)
        year = try container.decode(Int.self, forKey: .year)
        makeString = try container.decode(String.self, forKey: .make)
        modelString = try container.decode(String.self, forKey: .model)
        dealerID = try container.decode(Int.self, forKey: .dealerId)
    }
}
