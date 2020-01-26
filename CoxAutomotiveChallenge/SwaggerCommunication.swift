//
//  SwaggerCommunication.swift
//  CoxAutomotiveChallenge
//
//  Created by Michael Dautermann on 1/25/20.
//  Copyright © 2020 Michael Dautermann. All rights reserved.
//

import Foundation
import CoreData
import UIKit

extension NSManagedObject {
    // Returns the unqualified class name, i.e. the last component.
    // Can be overridden in a subclass.
    class func entityName() -> String {
        return String(describing: self)
    }

    convenience init(context: NSManagedObjectContext) {
        let eName = type(of: self).entityName()
        let entity = NSEntityDescription.entity(forEntityName: eName, in: context)!
        self.init(entity: entity, insertInto: context)
    }
}

class SwaggerComm {
    var currentDatasetObjectID: NSManagedObjectID?
    let baseURL = "https://api.coxauto-interview.com/api"
    let persistentContainer: NSPersistentContainer?

    typealias BackEndToDictionaryClosureType = ([String: Any]?, Error?) -> Void
    typealias BackEndToDataClosureType = (Data?, Error?) -> Void

    init() {
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            persistentContainer = delegate.persistentContainer
        } else {
            persistentContainer = nil
        }
    }
    
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
                    if let container = strongSelf.persistentContainer {
                        container.performBackgroundTask { (context) in
                            let datasetObject: Dataset = Dataset.init(context: context)
                            datasetObject.datasetID = datasetID
                            do {
                                try context.save()
                                strongSelf.currentDatasetObjectID = datasetObject.objectID
                            } catch let error {
                                Swift.print("couldn't save new dataset \(datasetID) - \(error.localizedDescription)")
                            }
                            strongSelf.getVehiclesFor(datasetID: datasetID)
                        }
                    }
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
                    strongSelf.createVehicleObjectFor(datasetID: datasetID, vehicleID: vehicleID)
                }
                // when we are done filling out the VehicleData object, let's go through each vehicle
                // and get dealership info...
            } else {
                Swift.print("no vehicles in getvehiclesfor")
            }
        }
    }
    
    func createVehicleObjectFor(datasetID: String, vehicleID: Int) {
        Swift.print("in createVehicleObjectFor for \(vehicleID)")
        guard let datasetURL = URL(string: baseURL + "/" + datasetID + "/vehicles/\(vehicleID)") else { return }
        var request = URLRequest(url: datasetURL)

        request.httpMethod = "GET"

        talkToBackendForData(request: request) { [weak self] (data, error) in
            #warning ("do we want to strongSelf here and if so, why?")
            guard let strongSelf = self else {
              return
            }
            if let responseData = data, let container = strongSelf.persistentContainer {
                container.performBackgroundTask { (context) in
                    let decoder = JSONDecoder()
                    decoder.userInfo[.context] = context

                    do {
                        let newVehicle = try decoder.decode(Vehicle.self, from: responseData)
                        if let datasetObjectID = strongSelf.currentDatasetObjectID, let currentDatasetObject = try context.existingObject(with: datasetObjectID) as? Dataset {
                            currentDatasetObject.addToVehicles(newVehicle)
                        }
                        // now that we have a newVehicle object, see if there's a corresponding dealer object and if not, we'll go get that information...
                        strongSelf.createDealerObjectIfNecessaryFor(datasetID: datasetID, dealerID: newVehicle.dealerID)
                        try context.save() //make sure to save your data once decoding is complete
                    } catch let error {
                        Swift.print("couldn't decode or save \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func createDealerObjectIfNecessaryFor(datasetID: String, dealerID: Int32) {
        Swift.print("in createDealerObjectIfNecessary")
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Dealer")
        fetchRequest.predicate = NSPredicate(format: "dealerID = %ld", dealerID)

        if let container = persistentContainer {
            do {
                let moc = container.viewContext
                let dealers = try moc.fetch(fetchRequest)
                assert(dealers.count < 2) // we shouldn't have any duplicates in CD

                if dealers.isEmpty {
                    
                    Swift.print("creating new dealer object for \(dealerID)")
                    guard let dealersInfoURL = URL(string: baseURL + "/" + datasetID + "/dealers/\(dealerID)") else { return }
                    var request = URLRequest(url: dealersInfoURL)

                    request.httpMethod = "GET"

                    talkToBackendForData(request: request) { [weak self] (data, error) in
                        #warning ("do we want to strongSelf here and if so, why?")
                        guard let strongSelf = self else {
                          return
                        }
                        if let responseData = data, let container = strongSelf.persistentContainer {
                            container.performBackgroundTask { (context) in
                                let decoder = JSONDecoder()
                                decoder.userInfo[.context] = context

                                do {
                                    _ = try decoder.decode(Dealer.self, from: responseData)
                                    try context.save() //make sure to save your data once decoding is complete
                                } catch let error {
                                   Swift.print("couldn't decode or save \(error.localizedDescription)")
                               }
                            }
                        }
                    }
                }
            } catch {
                // handle error
                Swift.print("couldn't fetch any dealers from CoreData")
            }
        }
    }
}
