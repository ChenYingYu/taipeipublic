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
    var haveYoubikeRoute = [Bool]()
    var passHandller: ((Route?, Route?, [YoubikeStation]?, Bool) -> Void)?

    @IBOutlet weak var titleView: UIView!
    @IBOutlet weak var routeTableView: UITableView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var destinationLabel: UILabel!
    @IBAction func back(_ sender: UIButton) {
        self.passHandller?(nil, nil, nil, false)
        dismiss(animated: true, completion: nil)
    }

    override func viewDidLoad() {
        resetRoutes()
        setUpTitleView()
        setUpRouteTableView()
        getRoutes()
    }

    override func viewWillDisappear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .default
    }

    func resetRoutes() {
        routes = [Route]()
        youbikeRoutes = [Route]()
        youbikeStations = [[YoubikeStation]]()
    }

    func setUpTitleView() {
        backButton.tintColor = UIColor.white
        destinationLabel.text = "  \(destinationName)"
        // 漸層色彩
        let colorLeft =  UIColor(red: 10.0/255.0, green: 140.0/255.0, blue: 204.0/255.0, alpha: 1.0).cgColor
        let colorRight = UIColor(red: 8.0/255.0, green: 105.0/255.0, blue: 153.0/255.0, alpha: 1.0).cgColor
        let gradient = CAGradientLayer()
        gradient.colors = [colorLeft, colorRight]
        gradient.locations = [0.0, 1.0]
        gradient.startPoint = CGPoint(x: 0.0, y: 1.0)
        gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
        gradient.frame = self.titleView.bounds
        self.titleView.layer.insertSublayer(gradient, at: 0)
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
    }

    func setUpRouteTableView() {
        let customTableViewCell = UINib(nibName: "RouteTableViewCell", bundle: nil)
        routeTableView.register(customTableViewCell, forCellReuseIdentifier: "Cell")
        routeTableView.delegate = self
        routeTableView.dataSource = self
    }

    func getRoutes() {
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
}

extension RouteViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return routes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as? RouteTableViewCell else {
            return UITableViewCell()
        }
        setUpStyle(of: cell)
        guard routes.count > indexPath.row else {
            return cell
        }
        let route = routes[indexPath.row]
        var routeInfo = ""
        if let legs = route.legs, let duration = legs.duration {
            //路線資訊格式
            routeInfo += "\(duration): \n" //總時間：
            for index in legs.steps.indices {
                if index != 0 {
                    routeInfo += " > "//更換交通工具
                }
                let instruction = legs.steps[index].instructions.enumerated()
                for (index, character) in instruction where index < 2 {
                        routeInfo += "\(character)"//交通工具
                }
                routeInfo += "\(legs.steps[index].duration)"//交通工具時程
            }
        }
        cell.subtitleLabel.numberOfLines = 0
        cell.subtitleLabel.text = routeInfo
        if haveYoubikeRoute.count > indexPath.row {
            cell.youbikeLabel.isHidden = haveYoubikeRoute[indexPath.row] ? false : true
        }
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

    func setUpStyle(of cell: RouteTableViewCell) {
        cell.layer.shadowColor = UIColor(red: 100/255, green: 100/255, blue: 100/255, alpha: 1.0).cgColor
        cell.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        cell.layer.shadowRadius = 4.0
        cell.layer.shadowOpacity = 1.0
    }
}

extension RouteViewController: RouteManagerDelegate {
    func manager(_ manager: RouteManager, didGet routes: [Route]) {
        self.routes += routes
        for _ in routes.indices {
            self.youbikeRoutes.append(nil)
        }
        for route in routes {
            guard let legs = route.legs else {
                return
            }
            //取得起點附近 Youbike 路線
            var firstYoubikeStation: YoubikeStation?
            var secondYoubikeStation: YoubikeStation?
            for index in legs.steps.indices {
                let position = CLLocationCoordinate2D(latitude: legs.steps[index].startLocation.lat, longitude: legs.steps[index].startLocation.lng)
                //起點 (index == 0) 及離起點最近的運輸站 (index == 1)
                if index < 2 {
                    if let youbikeManager = YoubikeManager.getStationInfo() {
                        let stations = youbikeManager.checkNearbyStation(position: position)
                        if stations.count > 0 {
                            let station = stations[0]
                            if index == 0 {
                                firstYoubikeStation = station
                            } else if index == 1 {
                                secondYoubikeStation = station
                            }
                        }
                    }
                }
            }
            if let youbikeStart = firstYoubikeStation, let youbikeEnd = secondYoubikeStation, youbikeStart.name != youbikeEnd.name {
                print("= = = = = = = = = = = = = = = =")
                print("AWESOME! WE FOUND A NEW ROUTE!")
                print("= = = = = = = = = = = = = = = =")
                var stations = [YoubikeStation]()
                stations.append(youbikeStart)
                stations.append(youbikeEnd)
                youbikeStations.append(stations)
                //加入 Youbike 租借站做為中途點並取得新路線
                let startPoint = legs.steps[0].startLocation
                let endPoint = legs.steps[0].endLocation
                let routeManager = RouteManager()
                routeManager.youbikeDelegate = self
                routeManager.requestYoubikeRoute(originLatitude: startPoint.lat, originLongitude: startPoint.lng, destinationLatitude: endPoint.lat, destinationLongitude: endPoint.lng, through: youbikeStart, and: youbikeEnd)
                self.haveYoubikeRoute.append(true)
            } else {
                let routeManager = RouteManager()
                routeManager.requestYoubikeRoute(originLatitude: 1000000.0, originLongitude: 1000000.0, destinationLatitude: 1000000.0, destinationLongitude: 1000000.0, through: YoubikeStation(name: "", latitude: "1000000.0", longitude: "1000000.0"), and: YoubikeStation(name: "", latitude: "1000000.0", longitude: "1000000.0"))
                self.youbikeStations.append(nil)
                self.haveYoubikeRoute.append(false)
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
            for index in haveYoubikeRoute.indices where self.haveYoubikeRoute[index] && self.youbikeRoutes[index] == nil {
                    self.youbikeRoutes[index] = routes[0]
                    return
            }
        }
    }

    func youbikeManager(_ manager: RouteManager, didFailWith error: Error) {
        print("Found Error:\n\(error)\n")
    }
}
