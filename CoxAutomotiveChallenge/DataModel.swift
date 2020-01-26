//
//  DataModel.swift
//  CoxAutomotiveChallenge
//
//  Created by Michael Dautermann on 1/25/20.
//  Copyright © 2020 Michael Dautermann. All rights reserved.
//

import Foundation
import UIKit

class VehicleData {
    static let shared = VehicleData()
    var vehicles = [Vehicle]()

    private init() { }
}

class DealersData {
    static let shared = DealersData()
    var dealers = [Dealers]()

    private init() { }
}
