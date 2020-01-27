//
//  ResultsTableViewController.swift
//  CoxAutomotiveChallenge
//
//  Created by Michael Dautermann on 1/26/20.
//  Copyright © 2020 Michael Dautermann. All rights reserved.
//

import UIKit
import CoreData

enum DisplayResultsFor {
    case dealers
    case vehicles // would love to add an associated value to this case but maybe we can iterate later?
}

class DealerCell : UITableViewCell
{
    @IBOutlet weak var nameAndIDLabel : UILabel!
}

class VehicleCell : UITableViewCell
{
    @IBOutlet weak var yearMakeModelLabel : UILabel!
    @IBOutlet weak var vehicleAndDealerIDLabel: UILabel!
}


class ResultsTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var displaying: DisplayResultsFor = .dealers
    @IBOutlet var resultTable: UITableView!
    var managedObjectContext: NSManagedObjectContext?
    var currentDatasetID: String?
    
    var dealers = [Dealer]()
    var vehicles = [Vehicle]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let previousFetchedDatasetID = currentDatasetID {
            fetchLatestFor(datasetID: previousFetchedDatasetID)
        }
    }
        
    override func viewDidAppear(_ animated: Bool) {
        // only allow selecting cells in the table if we are displaying dealers
        resultTable.allowsSelection = (displaying == .dealers)
    }
    
    func fetchLatestFor(datasetID: String) {
        // we have a datasetID, let's fetch records associated with this dataset
        let request = NSFetchRequest<Dataset>(entityName: "Dataset")
        if let context = managedObjectContext {
            request.predicate = NSPredicate(format: "datasetID == %@", datasetID)
            do {
                let matchingObjects = try context.fetch(request)
                if let datasetObject = matchingObjects.first {
                    let dealerDescriptor = NSSortDescriptor(key: "name", ascending: true)
                    dealers = datasetObject.dealers?.sortedArray(using: [dealerDescriptor]) as? [Dealer] ?? [Dealer]()
                    let vehicleDescriptor = NSSortDescriptor(key: "year", ascending: true)
                    vehicles = datasetObject.vehicles?.sortedArray(using: [vehicleDescriptor]) as? [Vehicle] ?? [Vehicle]()
                    resultTable.reloadData()
                }
            } catch let error {
                Swift.print("can't find dataset object in coredata with id \(datasetID) - \(error.localizedDescription)")
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (displaying == .dealers ? dealers.count : vehicles.count)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell
        switch(displaying) {
        case .dealers:
            let dealerForThisCell = dealers[indexPath.row]
            let dealerCell = tableView.dequeueReusableCell(withIdentifier: "DealerCell", for: indexPath) as! DealerCell
            dealerCell.nameAndIDLabel.text = "\(dealerForThisCell.name) - \(dealerForThisCell.dealerID)"
            cell = dealerCell
        case .vehicles:
            let vehicleForThisCell = vehicles[indexPath.row]
            let vehicleCell = tableView.dequeueReusableCell(withIdentifier: "VehicleCell", for: indexPath) as! VehicleCell
            vehicleCell.yearMakeModelLabel.text = "\(vehicleForThisCell.year) \(vehicleForThisCell.makeString) \(vehicleForThisCell.modelString)"
            vehicleCell.vehicleAndDealerIDLabel.text = "vehicle ID:\(vehicleForThisCell.vehicleID) dealerID: \(vehicleForThisCell.dealerID)"
            cell = vehicleCell
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Yeah, I know I could simply "reloadData" and change the "displaying" enum to .vehicles,
        // but maybe we'd like to allow a navigation bar or some other way to push into the vehicles table
        // and then let the user "go back"?
        let dealerID = dealers[indexPath.row].dealerID
        let viewController:ResultsTableViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ResultsTableViewController") as! ResultsTableViewController
        let filteredVehicles = vehicles.filter { $0.dealerID == dealerID }
        viewController.vehicles = filteredVehicles
        viewController.displaying = .vehicles
        self.navigationController?.pushViewController(viewController, animated: true)
    }
}
