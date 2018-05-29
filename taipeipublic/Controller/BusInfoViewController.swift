//
//  BusInfoViewController.swift
//  taipeipublic
//
//  Created by ChenAlan on 2018/5/21.
//  Copyright © 2018年 ChenAlan. All rights reserved.
//

import UIKit

class BusInfoViewController: UIViewController {
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var busNumberLabel: UILabel!
    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

    var busNumber = ""
    override func viewDidLoad() {
        super.viewDidLoad()

        backButton.tintColor = UIColor.white
        busNumberLabel.text = busNumber

        let manager = RouteManager()
        manager.requestBusStopInfo(ofRouteName: busNumber)
    }
}
