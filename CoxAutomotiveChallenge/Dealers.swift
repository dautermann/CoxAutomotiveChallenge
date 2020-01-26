//
//  Dealers.swift
//  CoxAutomotiveChallenge
//
//  Created by Michael Dautermann on 1/25/20.
//  Copyright © 2020 Michael Dautermann. All rights reserved.
//

import UIKit

struct Dealers: Decodable {
    var dealerID : Int
    var nameString : String

    enum CodingKeys: String, CodingKey {
        case dealerId
        case name
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dealerID = try container.decode(Int.self, forKey: .dealerId)
        nameString = try container.decode(String.self, forKey: .name)
    }
}
