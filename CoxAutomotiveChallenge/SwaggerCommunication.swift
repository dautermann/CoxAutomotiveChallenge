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

    // what to do when we are done fetching everything?  let's call a closure!
    typealias UpdatedDataset = (String) -> Void
    var updatedDatasetClosure: UpdatedDataset?

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
    
    func getDataset(closure: @escaping UpdatedDataset) {
        guard let datasetURL = URL(string: baseURL + "/datasetId") else { return }
        var request = URLRequest(url: datasetURL)
        updatedDatasetClosure = closure

        request.httpMethod = "GET"

        talkToBackendForDictionary(request: request) { [weak self] (responseDict, error) in
            if let responseDict = responseDict {
               if let datasetID = responseDict["datasetId"] as? String {
                    // Swift.print("datasetID is \(datasetID)")
                    if let container = self?.persistentContainer {
                        container.performBackgroundTask { (context) in
                            let datasetObject: Dataset = Dataset.init(context: context)
                            datasetObject.datasetID = datasetID
                            do {
                                try context.save()
                                self?.currentDatasetObjectID = datasetObject.objectID
                            } catch let error {
                                Swift.print("couldn't save new dataset \(datasetID) - \(error.localizedDescription)")
                            }
                            self?.getVehiclesFor(datasetID: datasetID)
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
            if let responseDict = responseDict,
                let vehicleArray = responseDict["vehicleIds"] as? [Int],
                let backgroundContext = self?.persistentContainer?.newBackgroundContext() {
                let dispatchGroup = DispatchGroup()
                for vehicleID in vehicleArray {
                    self?.createVehicleObjectFor(datasetID: datasetID, vehicleID: vehicleID, context: backgroundContext, withinDispatchGroup: dispatchGroup)
                }
                // save the current dataset id for next time we launch
                UserDefaults.standard.set(datasetID, forKey: "CurrentDatasetID")
                dispatchGroup.notify(queue: DispatchQueue.main, execute: { [weak self] in
                    self?.findAllDealersIn(datasetID: datasetID)
                })
            } else {
                Swift.print("no vehicles in getvehiclesfor")
            }
        }
    }
    
    func createVehicleObjectFor(datasetID: String, vehicleID: Int, context: NSManagedObjectContext , withinDispatchGroup: DispatchGroup) {
        guard let datasetURL = URL(string: baseURL + "/" + datasetID + "/vehicles/\(vehicleID)") else { return }
        var request = URLRequest(url: datasetURL)

        request.httpMethod = "GET"
        Swift.print("entering for vehicle \(vehicleID)")
        withinDispatchGroup.enter()
        talkToBackendForData(request: request) { [weak self] (data, error) in
            defer {
                withinDispatchGroup.leave()
                Swift.print("leaving for vehicle \(vehicleID)")
            }
            if let responseData = data {
                context.perform {
                    let decoder = JSONDecoder()
                    decoder.userInfo[.context] = context

                    do {
                        let newVehicle = try decoder.decode(Vehicle.self, from: responseData)
                        if let datasetObjectID = self?.currentDatasetObjectID, let currentDatasetObject = try context.existingObject(with: datasetObjectID) as? Dataset {
                            currentDatasetObject.addToVehicles(newVehicle)
                        }
                        do {
                            try context.save() //make sure to save your data once decoding is complete
                        } catch let error {
                            Swift.print("couldn't save new vehicle id \(vehicleID) - \(error.localizedDescription)")
                        }
                    } catch let error {
                        Swift.print("couldn't decode new vehicle id \(vehicleID) - \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func findAllDealersIn(datasetID: String) {
        do {
            if let context = persistentContainer?.newBackgroundContext(),
                let datasetObjectID = currentDatasetObjectID,
                let currentDatasetObject = try context.existingObject(with: datasetObjectID) as? Dataset {
                if let vehicleArray = currentDatasetObject.vehicles?.allObjects as? [Vehicle], let backgroundContext = persistentContainer?.newBackgroundContext() {
                    
                    let dealerIDarray = vehicleArray.map({ (vehicle: Vehicle) -> Int32 in
                        vehicle.dealerID
                    })
                    let dealerIDset = Set(dealerIDarray)
                    let dispatchGroup = DispatchGroup()
                    for eachDealerID in dealerIDset {
                        createDealerObjectIfNecessaryFor(datasetID: datasetID, dealerID: eachDealerID, context: backgroundContext, withinDispatchGroup: dispatchGroup)
                    }

                    // don't proceed until the dispatch group returns, meaning all the dealers have been saved
                    dispatchGroup.notify(queue: DispatchQueue.main, execute: { [weak self] in
                        if let closure = self?.updatedDatasetClosure {
                            closure(datasetID)
                        }
                    })
                }
            }
            
        } catch let error as NSError {
            Swift.print("findAllDealersIn couldn't find datasetObject for \(datasetID) - \(error.localizedDescription)")
        }
    }
    
    func createDealerObjectIfNecessaryFor(datasetID: String, dealerID: Int32, context: NSManagedObjectContext, withinDispatchGroup: DispatchGroup) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Dealer")
        fetchRequest.predicate = NSPredicate(format: "dealerID = %ld", dealerID)

        if let container = persistentContainer {
            do {
                let moc = container.viewContext
                let dealers = try moc.fetch(fetchRequest)
                assert(dealers.count < 2) // we shouldn't have any duplicates in CD
                if dealers.isEmpty {
                    guard let dealersInfoURL = URL(string: baseURL + "/" + datasetID + "/dealers/\(dealerID)") else { return }
                    var request = URLRequest(url: dealersInfoURL)

                    request.httpMethod = "GET"
                    Swift.print("entering for dealer \(dealerID)")
                    withinDispatchGroup.enter()
                    talkToBackendForData(request: request) { [weak self] (data, error) in
                        defer {
                            withinDispatchGroup.leave()
                            Swift.print("leaving for dealer \(dealerID)")
                        }
                        if let responseData = data {
                            context.perform {
                                let decoder = JSONDecoder()
                                decoder.userInfo[.context] = context

                                do {
                                    let newDealer = try decoder.decode(Dealer.self, from: responseData)
                                    if let datasetObjectID = self?.currentDatasetObjectID, let currentDatasetObject = try context.existingObject(with: datasetObjectID) as? Dataset {
                                        currentDatasetObject.addToDealers(newDealer)
                                    }
                                    try context.save() //make sure to save your data once decoding is complete
                                } catch let error {
                                   Swift.print("couldn't decode or save dealer object with id \(dealerID) - \(error.localizedDescription)")
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
