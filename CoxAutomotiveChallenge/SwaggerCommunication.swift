//
//  SwaggerCommunication.swift
//  CoxAutomotiveChallenge
//
//  Created by Michael Dautermann on 1/25/20.
//  Copyright © 2020 Michael Dautermann. All rights reserved.
//

import Foundation

class SwaggerComm {
    var theDatasetID: String?
    let baseURL = "https://api.coxauto-interview.com/api"

    typealias BackEndToDictionaryClosureType = ([String: Any]?, Error?) -> Void
    typealias BackEndToDataClosureType = (Data?, Error?) -> Void

    func talkToBackendForDictionary(request: URLRequest, closure: @escaping BackEndToDictionaryClosureType) {
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let actualError = error
            {
                Swift.print("error while talking to back end API - \(actualError.localizedDescription)")
            }
            
            if let responseData = data, responseData.count > 0 {
                do {
                   if let json = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any] {
                    closure(json, nil)
                   }

                } catch let error {
                    Swift.print("error while deserializing backend data - \(error.localizedDescription)")
                    closure(nil, error)
                }
            } else {
                Swift.print("no response data to work with")
                closure(nil, nil)
            }
        }
        task.resume()
    }
    
    func talkToBackendForData(request: URLRequest, closure: @escaping BackEndToDataClosureType) {
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let actualError = error
            {
                Swift.print("error while talking to back end API - \(actualError.localizedDescription)")
            }
            
            if let responseData = data {
                closure(responseData, nil)
            } else {
                closure(nil, error)
            }
        }
        task.resume()
    }
    
    func getDataset() {
        guard let datasetURL = URL(string: baseURL + "/datasetId") else { return }
        var request = URLRequest(url: datasetURL)

        request.httpMethod = "GET"

        talkToBackendForDictionary(request: request) { [weak self] (responseDict, error) in
            #warning ("do we want to strongSelf here and if so, why?")
            guard let strongSelf = self else {
              return
            }
            if let responseDict = responseDict {
               if let datasetID = responseDict["datasetId"] as? String {
                    Swift.print("datasetID is \(datasetID)")
                    strongSelf.theDatasetID = datasetID
                    strongSelf.getVehiclesFor(datasetID: datasetID)
               }
            }
        }
    }

    func getVehiclesFor(datasetID: String) {
        Swift.print("in getVehiclesFor")
        guard let datasetURL = URL(string: baseURL + "/" + datasetID + "/vehicles") else { return }
        var request = URLRequest(url: datasetURL)

        request.httpMethod = "GET"

        talkToBackendForDictionary(request: request) { [weak self] (responseDict, error) in
            #warning ("do we want to strongSelf here and if so, why?")
            guard let strongSelf = self else {
              return
            }
            if let responseDict = responseDict, let vehicleArray = responseDict["vehicleIds"] as? [Int] {
                for vehicleID in vehicleArray {
                    Swift.print("vehicleID is \(vehicleID)")
                    strongSelf.createVehicleObjectFor(vehicleID: vehicleID)
                }
                // when we are done filling out the VehicleData object, let's go through each vehicle
                // and get dealership info...
            } else {
                Swift.print("no vehicles in getvehiclesfor")
            }
        }
    }
    
    func createVehicleObjectFor(vehicleID: Int) {
        Swift.print("in createVehicleObjectFor for \(vehicleID)")
        guard let datasetID = theDatasetID else { Swift.print("no dataset id in createVehicleObject") ; return }
        guard let datasetURL = URL(string: baseURL + "/" + datasetID + "/vehicles/\(vehicleID)") else { return }
        var request = URLRequest(url: datasetURL)

        request.httpMethod = "GET"

        talkToBackendForData(request: request) { (data, error) in
            if let responseData = data {
                do {
                    let newVehicle = try JSONDecoder().decode(Vehicle.self, from: responseData)
                    // a singleton? Sure, it could be CoreData if I didn't have a sick family member at home to take care of this weekend
                    VehicleData.shared.vehicles.append(newVehicle)
                    Swift.print("newVehicle id is \(newVehicle.vehicleID) and dealerID is \(newVehicle.dealerID)")
                    if DealersData.shared.dealers.contains(where: { $0.dealerID == newVehicle.dealerID }) == false {
                        Swift.print("Dealer \(newVehicle.dealerID) doesn't exist in the Dealers array")
                    }
                }  catch let error {
                    Swift.print("error while deserializing vehicle data - \(error.localizedDescription)")
                }
            }
        }
    }
}
