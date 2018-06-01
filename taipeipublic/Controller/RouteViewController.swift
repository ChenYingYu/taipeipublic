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
    var route: Route?
    var routes = [Route]()
    var youbikeRoute: Route?
    var youbikeRoutes = [Route]()
    var cellTag = -1
    var youbikeRouteDictionary = [Int: [Route]]()
    var youbikeStations = [YoubikeStation]()
    var youbikeStationsDictionary = [Int: [YoubikeStation]]()
    var passHandller: ((Route?, [Route]?, [YoubikeStation]?, Bool) -> Void)?

    @IBOutlet weak var titleView: UIView!
    @IBOutlet weak var routeTableView: UITableView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var originLabel: UILabel!
    @IBOutlet weak var destinationLabel: UILabel!
    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

    override func viewDidLoad() {
        self.passHandller?(nil, nil, nil, false)
        resetRoutes()
        setUpTitleView()
        setUpRouteTableView()
        getRoutes()
    }

    override func viewWillDisappear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .default
    }

    func resetRoutes() {
        routes.removeAll()
        youbikeRoute = nil
        route = nil
        cellTag = -1
        youbikeRoutes.removeAll()
        youbikeRouteDictionary.removeAll()
        youbikeStations.removeAll()
        youbikeStationsDictionary.removeAll()
    }

    func setUpTitleView() {
        UIApplication.shared.statusBarStyle = .lightContent
        backButton.tintColor = UIColor.white
        destinationLabel.text = "  \(destinationName)"
        titleView.addGradient()
    }

    func setUpRouteTableView() {
        let customTableViewCell = UINib(nibName: "RouteTableViewCell", bundle: nil)
        routeTableView.register(customTableViewCell, forCellReuseIdentifier: "Cell")
        routeTableView.separatorStyle = .none
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
        route = routes[indexPath.row]
        var routeInfo = ""
        if let selectedRoute = route, let legs = selectedRoute.legs, let duration = legs.duration {
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
                routeInfo += " \(legs.steps[index].duration)"//交通工具時程
            }
        }
        cell.subtitleLabel.numberOfLines = 0
        cell.subtitleLabel.text = routeInfo
        if youbikeStationsDictionary[indexPath.row] != nil {
            cell.youbikeLabel.isHidden = false
        } else {
            cell.youbikeLabel.isHidden = true
        }
        return cell
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return indexPath
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.passHandller?(routes[indexPath.row], youbikeRouteDictionary[indexPath.row], youbikeStationsDictionary[indexPath.row], true)
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
        for index in routes.indices {
            guard let legs = routes[index].legs else {
                return
            }
            var firstYoubikeStation: YoubikeStation? = nil
            var secondYoubikeStation: YoubikeStation? = nil
            var thirdYoubikeStation: YoubikeStation? = nil
            var finalYoubikeStation: YoubikeStation? = nil
            //取得附近 Youbike 路線
            for index in legs.steps.indices {
                let startPosition = CLLocationCoordinate2D(latitude: legs.steps[index].startLocation.lat, longitude: legs.steps[index].startLocation.lng)
                let endPosition = CLLocationCoordinate2D(latitude: legs.steps[index].endLocation.lat, longitude: legs.steps[index].endLocation.lng)
                //起點 (index == 0) 及離起點最近的運輸站 (index == 1)
                if index < 2 {
                    if let youbikeManager = YoubikeManager.getStationInfo() {
                        if let station = youbikeManager.checkNearbyStation(position: startPosition) {
                            if index == 0 {
                                firstYoubikeStation = station
                            } else if index == 1 {
                                secondYoubikeStation = station
                            }
                        }
                    }
                }
                //終點 (index == legs.steps.count - 1) 及離終點最近的運輸站 (index == legs.steps.count - 2)
                if index > legs.steps.count - 3 {
                    if let youbikeManager = YoubikeManager.getStationInfo() {
                        if let station = youbikeManager.checkNearbyStation(position: endPosition) {
                            if index == legs.steps.count - 2 {
                                thirdYoubikeStation = station
                            } else if index == legs.steps.count - 1 {
                                finalYoubikeStation = station
                            }
                        }
                    }
                }
            }
            cellTag = index
            youbikeStations.removeAll()
            youbikeRoutes.removeAll()
            checkYoubikeStation(firstYoubikeStation, and: secondYoubikeStation, in: legs.steps[0], withRouteIndex: index)
            checkYoubikeStation(thirdYoubikeStation, and: finalYoubikeStation, in: legs.steps[legs.steps.count - 1], withRouteIndex: index)
        }
        routeTableView.reloadData()
    }

    func checkYoubikeStation(_ start: YoubikeStation?, and end: YoubikeStation?, in step: Step, withRouteIndex index: Int) {
        if let youbikeStart = start, let youbikeEnd = end, youbikeStart.name != youbikeEnd.name {
            //加入 Youbike 租借站做為中途點並取得新路線
            youbikeStations.append(youbikeStart)
            youbikeStations.append(youbikeEnd)
            youbikeStationsDictionary.updateValue(youbikeStations, forKey: cellTag)
            checkOutYoubikeRoute(of: step, from: youbikeStart, to: youbikeEnd, withRouteIndex: index)
        }
    }

    func checkOutYoubikeRoute(of step: Step, from start: YoubikeStation?, to destination: YoubikeStation?, withRouteIndex index: Int) {
        let routeManager = RouteManager()
        routeManager.youbikeDelegate = self
        //取得附近 Youbike 路線
        if let youbikeStart = start, let youbikeEnd = destination, youbikeStart.name != youbikeEnd.name {
            //加入 Youbike 租借站做為中途點並取得新路線
            let startPoint = step.startLocation
            let endPoint = step.endLocation
            routeManager.requestYoubikeRoute(originLatitude: startPoint.lat, originLongitude: startPoint.lng, destinationLatitude: endPoint.lat, destinationLongitude: endPoint.lng, through: youbikeStart, and: youbikeEnd, withRouteIndex: index)
        }
    }

    func manager(_ manager: RouteManager, didFailWith error: Error) {
        print("Found Error:\n\(error)\n")
    }
}

extension RouteViewController: YoubikeRouteManagerDelegate {
    func youbikeManager(_ manager: RouteManager, didGet routes: [Route], atRouteIndex index: Int) {
        if routes.count > 0 {
            self.youbikeRoutes.append(routes[0])
            self.youbikeRouteDictionary.updateValue(youbikeRoutes, forKey: index)
            return
        }
    }

    func youbikeManager(_ manager: RouteManager, didFailWith error: Error) {
        print("Found Error:\n\(error)\n")
    }
}

extension UIView {
    func addGradient() {
        // 漸層色彩
        let colorLeft =  UIColor(red: 10.0/255.0, green: 140.0/255.0, blue: 204.0/255.0, alpha: 1.0).cgColor
        let colorRight = UIColor(red: 8.0/255.0, green: 105.0/255.0, blue: 153.0/255.0, alpha: 1.0).cgColor
        let gradient = CAGradientLayer()
        gradient.colors = [colorLeft, colorRight]
        gradient.locations = [0.0, 1.0]
        gradient.startPoint = CGPoint(x: 0.0, y: 1.0)
        gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
        gradient.frame = self.bounds
        self.layer.insertSublayer(gradient, at: 0)
    }
}
