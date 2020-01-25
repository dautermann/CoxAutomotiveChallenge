//
//  SwaggerCommunication.swift
//  CoxAutomotiveChallenge
//
//  Created by Michael Dautermann on 1/25/20.
//  Copyright © 2020 Michael Dautermann. All rights reserved.
//

import Foundation

class SwaggerComm {
    let baseURL = "https://api.coxauto-interview.com/api"
    // let dataset = baseURL + "/datasetId"

    func getDataset() {
        guard let datasetURL = URL(string: baseURL + "/datasetId") else { return }
        var request = URLRequest(url: datasetURL)

         request.httpMethod = "GET"

         let task = URLSession.shared.dataTask(with: request) { data, response, error in
             if let actualError = error
             {
                 Swift.print("error while talking to weather API - \(actualError.localizedDescription)")
             }
             guard let responseData = data else {
                 // FIXME: Need to throw closure / failure block here
                 Swift.print("data is unexpectedly nil")
                 return
             }

             if (responseData.count > 0) {
                 do {
                    if let json = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any] {
                        let datasetID = json["datasetId"]
                        Swift.print("datasetID is \(datasetID)")
                    }

                 } catch let error {
                     Swift.print("error while deserializing weather data - \(error.localizedDescription)")
                 }
             } else {
                 Swift.print("no response data to work with")
             }
         }
         task.resume()
    }

    func getVehiclesFor(dataset: String) {

    }
}
