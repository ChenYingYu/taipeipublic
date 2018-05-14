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
    var youbikeRoute: Route?
    var youbikeRoutes = [Route?]()
    var youbikeStations = [[YoubikeStation]?]()
    var passHandller: ((Route?, Route?, [YoubikeStation]?, Bool) -> Void)?
    @IBOutlet weak var routeTableView: UITableView!
    @IBOutlet weak var backButton: UIButton!
    @IBAction func back(_ sender: UIButton) {
        self.passHandller?(nil, nil, nil, false)
        dismiss(animated: true, completion: nil)
    }
    @IBOutlet weak var destinationLabel: UILabel!
    override func viewDidLoad() {
        routes = [Route]()
        youbikeRoutes = [Route]()
        youbikeStations = [[YoubikeStation]]()
        backButton.tintColor = UIColor.white
        destinationLabel.text = "  \(destinationName)"
        routeTableView.delegate = self
        routeTableView.dataSource = self
        let routeManager = RouteManager()
        routeManager.delegate = self
        routeManager.requestRoute(originLatitude: getUserLatitude(), originLongitude: getUserLongitude(), destinationId: destinationId)
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
    func addYoubikeMarker(of station: YoubikeStation) {
        if let stationLatitude = Double(station.latitude), let stationLongitude = Double(station.longitude) {
            let position = CLLocationCoordinate2D(latitude: stationLatitude, longitude: stationLongitude)
        }
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
        let youbikeStations = self.youbikeStations[indexPath.row]
        var youbikeRoute: Route?
        if youbikeRoutes.count > indexPath.row {
            youbikeRoute = youbikeRoutes[indexPath.row]
        }
        self.passHandller?(route, youbikeRoute, youbikeStations, true)
        dismiss(animated: true, completion: nil)
    }
}
extension RouteViewController: RouteManagerDelegate {
    func manager(_ manager: RouteManager, didGet routes: [Route]) {
        self.routes += routes
        for route in routes {
            guard let legs = route.legs else {
                return
            }
            // Try to replace first walking polyline to youbike polyline
            var startingYoubikeStation: YoubikeStation?
            var endingYoubikeStation: YoubikeStation?
            for index in legs.steps.indices {
                let position = CLLocationCoordinate2D(latitude: legs.steps[index].startLocation.lat, longitude: legs.steps[index].startLocation.lng)
                if index < 2 {
                    if let youbikeManager = YoubikeManager.getStationInfo() {
                        let stations = youbikeManager.checkNearbyStation(position: position)
                        if stations.count > 0 {
                            let station = stations[0]
                            if index == 0 {
                                startingYoubikeStation = station
                            } else if index == 1 {
                                endingYoubikeStation = station
                            }
                        }
                    }
                }
            }
            if let newStart = startingYoubikeStation, let newEnd = endingYoubikeStation, newStart.name != newEnd.name {
                print("= = = = = = = = = = = = = = = =")
                print("AWESOME! WE FOUND A NEW ROUTE!")
                print("= = = = = = = = = = = = = = = =")
                addYoubikeMarker(of: newStart)
                addYoubikeMarker(of: newEnd)
                var stations = [YoubikeStation]()
                stations.append(newStart)
                stations.append(newEnd)
                youbikeStations.append(stations)
                let startPoint = legs.steps[0].startLocation
                let endPoint = legs.steps[0].endLocation
                let routeManager = RouteManager()
                routeManager.youbikeDelegate = self
                routeManager.requestYoubikeRoute(originLatitude: startPoint.lat, originLongitude: startPoint.lng, destinationLatitude: endPoint.lat, destinationLongitude: endPoint.lng, through: newStart, and: newEnd)
            } else {
                let routeManager = RouteManager()
                routeManager.requestYoubikeRoute(originLatitude: 1000000.0, originLongitude: 1000000.0, destinationLatitude: 1000000.0, destinationLongitude: 1000000.0, through: YoubikeStation(name: "", latitude: "1000000.0", longitude: "1000000.0"), and: YoubikeStation(name: "", latitude: "1000000.0", longitude: "1000000.0"))
                self.youbikeStations.append(nil)
            }
        }
        routeTableView.reloadData()
    }
    func manager(_ manager: RouteManager, didFailWith error: Error) {
        print("Found Error:\n\(error)\n")
    }
}
extension RouteViewController: YoubikeRouteManagerDelegate {
    func youbikeManager(_ manager: RouteManager, didGet routes: [Route]) {
        self.youbikeRoute = nil
        if routes.count > 0 {
            self.youbikeRoute = routes[0]
        }
        guard let route = self.youbikeRoute else {
            self.youbikeRoutes.append(self.youbikeRoute)
            print("==== No Value ====")
            print("==== \(self.youbikeRoutes.count) Youbike Routes Now ====")
            print("- - - - - - - - - - - - - - - - - - -- ")
            return
        }
        self.youbikeRoutes.append(route)
        print("==== Got Value ====")
        print("==== \(self.youbikeRoutes.count) Youbike Routes Now ====")
        print("- - - - - - - - - - - - - - - - - - -- ")
    }
    func youbikeManager(_ manager: RouteManager, didFailWith error: Error) {
        print("Found Error:\n\(error)\n")
        self.youbikeRoutes.append(Route(bounds: nil, legs: nil))
    }
}
