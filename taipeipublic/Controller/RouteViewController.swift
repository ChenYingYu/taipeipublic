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
    var passHandller: ((String) -> Void)?
    @IBOutlet weak var routeTableView: UITableView!
    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    @IBOutlet weak var destinationLabel: UILabel!
    override func viewDidLoad() {
        destinationLabel.text = destinationName
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
        guard routes.count > indexPath.row else {
            cell.backgroundColor = UIColor.gray
            return cell
        }
        let route = routes[indexPath.row]
        var text = ""
        for step in route.legs.steps {
            text += "\(step.instructions)\n"
        }
        cell.backgroundColor = UIColor.gray
        cell.textLabel?.text = text
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let path = routes[indexPath.row].legs.points
        self.passHandller?(path)
        dismiss(animated: true, completion: nil)
    }
}
