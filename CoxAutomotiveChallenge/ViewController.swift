//
//  ViewController.swift
//  CoxAutomotiveChallenge
//
//  Created by Michael Dautermann on 1/25/20.
//  Copyright © 2020 Michael Dautermann. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    let comm = SwaggerComm.init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func fetchDataset(sender: UIButton) {
        comm.getDataset()
    }
}

