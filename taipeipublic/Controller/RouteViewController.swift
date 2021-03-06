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
import GooglePlaces

class RouteViewController: UIViewController {

    var destination: GMSPlace?
    var destinationName = Constant.DefaultValue.emptyString
    var destinationId = Constant.DefaultValue.emptyString
    var origin: GMSPlace?
    var originId = Constant.DefaultValue.emptyString
    var originName = Constant.DefaultValue.emptyString
    var route: Route?
    var routes = [Route]()
    var youbikeRoute: Route?
    var youbikeRouteDictionary = [Int: Route]()
    var cellTag = -1
    var routeDictionary = [Int: [Int: Route]]()
    var youbikeStations = [YoubikeStation]()
    var youbikeStationsDictionary = [Int: [YoubikeStation]]()
    var passHandler: ((Route?, [Route]?, [YoubikeStation]?, Bool, GMSPlace?, GMSPlace?) -> Void)?
    weak var navigationDelegate: NavigationDelegate?
    let spinner = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
    var originLatitude = CLLocationManager().getUserLatitude()
    var originLongitude = CLLocationManager().getUserLongitude()
    var targetButton = UIButton()

    @IBOutlet weak var titleView: UIView!
    @IBOutlet weak var routeTableView: UITableView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var originLabel: UILabel!
    @IBOutlet weak var destinationLabel: UILabel!
    @IBOutlet weak var originButton: UIButton!
    @IBOutlet weak var destinationButton: UIButton!
    @IBAction func showGoogleSearchController(_ sender: UIButton) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.tintColor = .blue
        autocompleteController.delegate = self
        targetButton = sender
        present(autocompleteController, animated: true, completion: nil)
    }

    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
        if let destination = destination {
            self.passHandler?(nil, nil, nil, false, destination, nil)
        }
        navigationDelegate?.stopNavigation()
        navigationDelegate?.showDestination()
    }

    override func viewDidLoad() {
        self.passHandler?(nil, nil, nil, false, nil, nil)
        resetRoutes()
        setUpTitleView()
        setUpRouteTableView()
        runSpinner(spinner, in: self.view)
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
        youbikeRouteDictionary.removeAll()
        routeDictionary.removeAll()
        youbikeStations.removeAll()
        youbikeStationsDictionary.removeAll()
    }

    func setUpTitleView() {
        UIApplication.shared.statusBarStyle = .lightContent
        backButton.tintColor = UIColor.white
        destinationButton.setTitle("  \(destinationName)", for: .normal)
        originButton.setTitle("  \(origin?.name ?? "我的位置")", for: .normal)
        titleView.addGradient()
    }

    func setUpRouteTableView() {
        let customTableViewCell = UINib(nibName: Constant.Identifier.routeTableViewCell, bundle: nil)
        routeTableView.register(customTableViewCell, forCellReuseIdentifier: Constant.Identifier.cell)
        routeTableView.separatorStyle = .none
        routeTableView.delegate = self
        routeTableView.dataSource = self
    }

    func getRoutes() {
        let routeManager = RouteManager()
        routeManager.delegate = self
        routeManager.requestRoute(originLatitude: originLatitude, originLongitude: originLongitude, destinationId: destinationId)
    }
}

extension RouteViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return routes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Constant.Identifier.cell, for: indexPath) as? RouteTableViewCell else {
            return UITableViewCell()
        }
        setUpStyle(of: cell)
        guard routes.count > indexPath.row else {
            return cell
        }
        route = routes[indexPath.row]
        var routeInfo = Constant.DefaultValue.emptyString
        guard let selectedRoute = route, let legs = selectedRoute.legs else {
            return cell
        }
        let leg = legs[0]
        let duration = leg.duration?.durationText ?? ""
        let durationValue = leg.duration?.durationValue ?? 0
        var firstYoubikeDuration = ""
        var firstYoubikeDurationValue = 0
        var secondYoubikeDuration = ""
        var secondYoubikeDurationValue = 0
        if let youbikeRoutes = routeDictionary[indexPath.row] {
            for youbikeRoute in youbikeRoutes {
                if let leg = youbikeRoute.value.legs?[0], let youbikeValue = leg.duration?.durationValue {
                    if youbikeRoute.key == 1 {
                        firstYoubikeDuration = "Youbike \(String(youbikeValue / 120 + 4)) 分鐘"
                        firstYoubikeDurationValue = youbikeValue / 120 + 4
                    } else if youbikeRoute.key == 2 {
                        secondYoubikeDuration = "Youbike \(String(youbikeValue / 120 + 4)) 分鐘"
                        secondYoubikeDurationValue = youbikeValue / 120 + 4
                    }
                }
            }
        } else {
            cell.youbikeLabel.isHidden = true
        }
        //路線資訊格式
        var totalDuration = "\(duration)：\n" //總時間：
        var finalDuration = durationValue / 60
        var routeDetails = ""
        for index in leg.steps.indices {
            if index == 0, firstYoubikeDurationValue != 0 {
                if firstYoubikeDurationValue < leg.steps[index].duration.durationValue / 60 {
                    finalDuration -= leg.steps[index].duration.durationValue / 60 - firstYoubikeDurationValue
                    totalDuration = "\(finalDuration) 分鐘： \n"
                } else {
                    routeDictionary[indexPath.row]?.removeValue(forKey: 1)
                }
            } else if index == leg.steps.count - 1, secondYoubikeDurationValue != 0 {
                if secondYoubikeDurationValue < leg.steps[index].duration.durationValue / 60 {
                    finalDuration -= leg.steps[index].duration.durationValue / 60 - secondYoubikeDurationValue
                    totalDuration = "\(finalDuration) 分鐘： \n"
                } else {
                    routeDictionary[indexPath.row]?.removeValue(forKey: 2)
                }
            }
            if index != 0 {
                routeDetails += " > "//更換交通工具
            }
            if let instruction = leg.steps[index].instructions?.enumerated() {
                if index == 0, firstYoubikeDurationValue != 0, firstYoubikeDurationValue < leg.steps[index].duration.durationValue / 60 {
                    routeDetails += firstYoubikeDuration
                } else if index == leg.steps.count - 1, secondYoubikeDurationValue != 0, secondYoubikeDurationValue < leg.steps[index].duration.durationValue / 60 {
                    routeDetails += secondYoubikeDuration
                } else {
                    for (index, character) in instruction where index < 2 {
                        routeDetails += "\(character)"//交通工具
                    }
                    routeDetails += " \(leg.steps[index].duration.durationText)"//交通工具時程
                }
            }
        }
        if finalDuration >= 60 {
            totalDuration = "\(finalDuration / 60) 小時 \(finalDuration % 60) 分鐘：\n"
        }
        routeInfo += totalDuration
        routeInfo += routeDetails
        cell.subtitleLabel.text = routeInfo
        return cell
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return indexPath
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let destination = destination {
            var youbikeRoutes = [Route]()
            if let dictionary = routeDictionary[indexPath.row] {
                for youbikeRoute in dictionary {
                    youbikeRoutes.append(youbikeRoute.value)
                }
            }
            self.passHandler?(routes[indexPath.row], youbikeRoutes, youbikeStationsDictionary[indexPath.row], true, destination, origin ?? nil)
        }
        navigationDelegate?.hideDestination()
        navigationDelegate?.startNavigation()
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
        self.routes = routes
        for index in routes.indices {
            guard let legs = routes[index].legs else {
                return
            }
            let leg = legs[0]
            var firstYoubikeStation: YoubikeStation? = nil
            var secondYoubikeStation: YoubikeStation? = nil
            var thirdYoubikeStation: YoubikeStation? = nil
            var finalYoubikeStation: YoubikeStation? = nil
            //取得附近 Youbike 路線
            for index in leg.steps.indices {
                let startPosition = CLLocationCoordinate2D(latitude: leg.steps[index].startLocation.lat, longitude: leg.steps[index].startLocation.lng)
                let endPosition = CLLocationCoordinate2D(latitude: leg.steps[index].endLocation.lat, longitude: leg.steps[index].endLocation.lng)
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
                //終點 (index == leg.steps.count - 1) 及離終點最近的運輸站 (index == leg.steps.count - 2)
                if index > leg.steps.count - 3 {
                    if let youbikeManager = YoubikeManager.getStationInfo() {
                        if let station = youbikeManager.checkNearbyStation(position: endPosition) {
                            if index == leg.steps.count - 2 {
                                thirdYoubikeStation = station
                            } else if index == leg.steps.count - 1 {
                                finalYoubikeStation = station
                            }
                        }
                    }
                }
            }
            cellTag = index
            youbikeStations.removeAll()
            youbikeRouteDictionary.removeAll()
            checkYoubikeStation(firstYoubikeStation, and: secondYoubikeStation, in: leg.steps[0], withRouteIndex: index, atYoubikeRouteIndex: 1)
            checkYoubikeStation(thirdYoubikeStation, and: finalYoubikeStation, in: leg.steps[leg.steps.count - 1], withRouteIndex: index, atYoubikeRouteIndex: 2)
        }
        routeTableView.reloadData()
        spinner.stopAnimating()
    }

    func checkYoubikeStation(_ start: YoubikeStation?, and end: YoubikeStation?, in step: Step, withRouteIndex index: Int, atYoubikeRouteIndex youbikeRouteIndex: Int) {
        if let youbikeStart = start, let youbikeEnd = end, youbikeStart.name != youbikeEnd.name {
            //加入 Youbike 租借站做為中途點並取得新路線
            youbikeStations.append(youbikeStart)
            youbikeStations.append(youbikeEnd)
            youbikeStationsDictionary.updateValue(youbikeStations, forKey: cellTag)
            checkOutYoubikeRoute(of: step, from: youbikeStart, to: youbikeEnd, withRouteIndex: index, atYoubikeRouteIndex: youbikeRouteIndex)
        }
    }

    func checkOutYoubikeRoute(of step: Step, from start: YoubikeStation?, to destination: YoubikeStation?, withRouteIndex index: Int, atYoubikeRouteIndex youbikeRouteIndex: Int) {
        let routeManager = RouteManager()
        routeManager.youbikeDelegate = self
        //取得附近 Youbike 路線
        if let youbikeStart = start, let youbikeEnd = destination, youbikeStart.name != youbikeEnd.name {
            guard let startYoubikeStationLatitude = Double(youbikeStart.latitude), let startYoubikeStationLongitude = Double(youbikeStart.longitude), let endYoubikeStationLatitude = Double(youbikeEnd.latitude), let endYoubikeStationLongitude = Double(youbikeEnd.longitude) else {
                return
            }
            //加入 Youbike 租借站做為中途點並取得新路線
            routeManager.requestYoubikeRoute(originLatitude: startYoubikeStationLatitude, originLongitude: startYoubikeStationLongitude, destinationLatitude: endYoubikeStationLatitude, destinationLongitude: endYoubikeStationLongitude, withRouteIndex: index, atYoubikeRouteIndex: youbikeRouteIndex)

        }
    }

    func manager(_ manager: RouteManager, didFailWith error: Error) {
        print("Found Error:\n\(error)\n")
        spinner.stopAnimating()
        showAlert(title: Constant.AlertMessage.routeNotFoundTitle, message: Constant.AlertMessage.routeNotFoundContent)
    }
}

extension RouteViewController: YoubikeRouteManagerDelegate {
    func youbikeManager(_ manager: RouteManager, didGet routes: [Route], atRouteIndex index: Int, atYoubikeRouteIndex youbikeRouteIndex: Int) {
        if routes.count > 0 {
            if let youbikeRoutes = routeDictionary[index] {
                self.youbikeRouteDictionary = youbikeRoutes
            }
            self.youbikeRouteDictionary.updateValue(routes[0], forKey: youbikeRouteIndex)
            self.routeDictionary.updateValue(self.youbikeRouteDictionary, forKey: index)
            self.youbikeRouteDictionary.removeAll()
            routeTableView.reloadData()
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

extension RouteViewController: GMSAutocompleteViewControllerDelegate {
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        dismiss(animated: true, completion: nil)
        targetButton.setTitle("  \(place.name)", for: .normal)
        if targetButton == destinationButton {
            destination = place
            destinationId = place.placeID
            destinationName = place.name
        } else if targetButton == originButton {
            origin = place
            originId = place.placeID
            originName = place.name
            originLatitude = place.coordinate.latitude
            originLongitude = place.coordinate.longitude
        }
        resetRoutes()
        routeTableView.reloadData()
        runSpinner(spinner, in: self.view)
        getRoutes()
    }

    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        print(Constant.ErrorMessage.errorPrefix, error.localizedDescription)
    }

    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
}

extension UIViewController {
    func runSpinner(_ spinner: UIActivityIndicatorView, in view: UIView) {
        spinner.center = view.center
        view.addSubview(spinner)
        spinner.startAnimating()
    }
}
