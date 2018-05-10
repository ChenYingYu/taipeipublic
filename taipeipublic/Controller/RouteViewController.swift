//
//  RouteViewController.swift
//  taipeipublic
//
//  Created by ChenAlan on 2018/5/3.
//  Copyright © 2018年 ChenAlan. All rights reserved.
//

import Foundation
import UIKit
import GoogleMaps

class RouteViewController: UIViewController {
    var destinationName = ""
    var destinationId = ""
    var routes = [Route]()
    var passHandller: ((Route?, Bool) -> Void)?
    @IBOutlet weak var routeTableView: UITableView!
    @IBOutlet weak var backButton: UIButton!
    @IBAction func back(_ sender: UIButton) {
        self.passHandller?(nil, false)
        dismiss(animated: true, completion: nil)
    }
    @IBOutlet weak var destinationLabel: UILabel!
    override func viewDidLoad() {
        backButton.tintColor = UIColor.white
        destinationLabel.text = "  \(destinationName)"
        routeTableView.delegate = self
        routeTableView.dataSource = self
    }
    func getUserLatitude() -> Double {
        let locationmanager = CLLocationManager()
        guard let userLatitude = locationmanager.location?.coordinate.latitude else {
            print("Cannot find user's location")
            return 25.042416
        }
        return userLatitude
    }
    func getUserLongitude() -> Double {
        let locationmanager = CLLocationManager()
        guard let userLongitude = locationmanager.location?.coordinate.longitude else {
            print("Cannot find user's location")
            return 121.564793
        }
        return userLongitude
    }
}

extension RouteViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return routes.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.backgroundColor = UIColor.white
        cell.layer.shadowColor = UIColor(red: 100/255, green: 100/255, blue: 100/255, alpha: 1.0).cgColor
        cell.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        cell.layer.shadowRadius = 4.0
        cell.layer.shadowOpacity = 1.0
        guard routes.count > indexPath.row else {
            return cell
        }
        let route = routes[indexPath.row]
        var routeInfo = ""
        if let legs = route.legs, let duration = legs.duration {
            routeInfo += "\(duration): \n"
            for index in legs.steps.indices {
                if index != 0 {
                    routeInfo += " > "
                }
                let instruction = legs.steps[index].instructions.enumerated()
                for (index, character) in instruction {
                    if index < 2 {
                        routeInfo += "\(character)"
                    }
                }
                routeInfo += "\(legs.steps[index].duration)"
            }
        }
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.text = routeInfo
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let route = routes[indexPath.row]
        self.passHandller?(route, true)
        dismiss(animated: true, completion: nil)
    }
}
