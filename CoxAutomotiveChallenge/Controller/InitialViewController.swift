//
//  ViewController.swift
//  CoxAutomotiveChallenge
//
//  Created by Michael Dautermann on 1/25/20.
//  Copyright © 2020 Michael Dautermann. All rights reserved.
//

import UIKit
import CoreData

class InitialViewController: UIViewController {
    @IBOutlet var currentDatasetButton: UIButton!
    @IBOutlet var activitySpinner: UIActivityIndicatorView!
    
    let swaggerBackendManager = SwaggerManager.init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateCurrentDatasetButton()
    }

    func getCountOfRecords() {
        // if you're looking at this, I used this for debugging -- usually called from viewDidLoad or viewWillAppear!
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            let context = delegate.persistentContainer.newBackgroundContext()
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>.init(entityName: "Vehicle")
            do {
                let count = try context.count(for: fetchRequest)
                Swift.print("number of Vehicle records is \(count)")
            } catch let error as NSError {
                Swift.print("error while trying to get count - \(error.localizedDescription)")
            }
            let fetchRequest2 = NSFetchRequest<NSFetchRequestResult>.init(entityName: "Dealer")
            do {
               let count = try context.count(for: fetchRequest2)
               Swift.print("number of Dealer records is \(count)")
            } catch let error as NSError {
               Swift.print("error while trying to get count - \(error.localizedDescription)")
            }
        }
    }

    func updateCurrentDatasetButton() {
        if let lastDatasetID = UserDefaults.standard.string(forKey: "CurrentDatasetID") {
            currentDatasetButton.setTitle("Go to current dataset ID: \(lastDatasetID)", for: .normal)
            currentDatasetButton.isHidden = false
        } else {
            currentDatasetButton.isHidden = true
        }
    }

    @IBAction func fetchDataset(sender: UIButton) {
        currentDatasetButton.isHidden = true
        activitySpinner.startAnimating()
        swaggerBackendManager.getDataset { [weak self] (datasetID) in
            self?.performSegue(withIdentifier: "GoToResults", sender: nil)
            self?.activitySpinner.stopAnimating()
            self?.updateCurrentDatasetButton()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navigationVC = segue.destination as? UINavigationController, let resultsVC = navigationVC.topViewController as? ResultsTableViewController {
            // pass along the managedObjectContext and any saved CurrentDatasetID from UserDefaults
            resultsVC.managedObjectContext = swaggerBackendManager.persistentContainer?.viewContext
            if let lastDatasetID = UserDefaults.standard.string(forKey: "CurrentDatasetID") {
                resultsVC.currentDatasetID = lastDatasetID
            }
        }
    }
}

