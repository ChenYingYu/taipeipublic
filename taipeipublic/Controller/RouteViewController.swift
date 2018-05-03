//
//  RouteViewController.swift
//  taipeipublic
//
//  Created by ChenAlan on 2018/5/3.
//  Copyright © 2018年 ChenAlan. All rights reserved.
//

import Foundation
import UIKit

class RouteViewController: UIViewController {
    var destinationName = ""
    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    @IBOutlet weak var destinationLabel: UILabel!
    override func viewDidLoad() {
        destinationLabel.text = destinationName
    }
}
