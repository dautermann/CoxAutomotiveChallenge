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
    let comm = SwaggerComm.init()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            let context = delegate.persistentContainer.newBackgroundContext()
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>.init(entityName: "Vehicle")
            do {
                let count = try context.count(for: fetchRequest)
                Swift.print("number of Vehicle records is \(count)")
            } catch let error as NSError {
                Swift.print("error while trying to get count - \(error.localizedDescription)")
            }
        }
    }

    @IBAction func fetchDataset(sender: UIButton) {
        comm.getDataset()
    }
}

