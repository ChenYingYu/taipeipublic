//
//  ViewController.swift
//  taipeipublic
//
//  Created by ChenAlan on 2018/4/30.
//  Copyright © 2018年 ChenAlan. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import Alamofire
import Foundation

class MapViewController: UIViewController {

    var isNavigationMode = false
    var isDestinationMode = false
    //搜尋目的地後使用的變數
    var destination: GMSPlace?
    var destinationId = ""
    var destinationName = ""
    //進行導航時使用的變數
    var routes = [Route]()
    var youbikeRoute: Route?
    var selectedRoute: Route?
    var selectedYoubikeRoutes: [Route]?
    var selectedYoubikeStation = [YoubikeStation]()
    var routeDetailTableView = UITableView()
    // 紀錄公車班次時使用的變數
    var transitTag = 0
    var transitInfoDictionary = [Int: [String: String]]()
    var initialCenter = CGPoint()

    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var destinationInfoView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var showRouteButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBAction func autocompleteClicked(_ sender: UIButton) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.tintColor = .blue
        autocompleteController.delegate = self
        present(autocompleteController, animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpView()
        setUpMap()
    }

    override func viewWillAppear(_ animated: Bool) {
        checkOutModeOfMap()
    }

    func checkOutModeOfMap() {
        mapView.clear()
        self.backButton.isHidden = true
        if isNavigationMode {
            self.destinationInfoView.isHidden = true
            self.searchButton.isHidden = true
            self.backButton.isHidden = false
            showDestination()
            updateCamera()
            showRoutePolyline()
            showYoubikeRoutePolyline()
            mapView.addSubview(backButton)
            setUpRouteDetailTableView()
        } else if isDestinationMode {
            routeDetailTableView.removeFromSuperview()
            self.destinationInfoView.isHidden = false
            self.searchButton.isHidden = false
            self.backButton.isHidden = true
            showDestination()
        }
        updateLocationButton()
    }

    func showDestination() {
        if let place = destination {
            let marker = GMSMarker(position: place.coordinate)
            marker.map = mapView
            mapView.camera = GMSCameraPosition.camera(withLatitude: place.coordinate.latitude, longitude: place.coordinate.longitude, zoom: 15.0)
        }
    }

    func updateCamera() {
        if let upperRight = selectedRoute?.bounds?.northeast, let bottomLeft = selectedRoute?.bounds?.southwest {
            let northeast = CLLocationCoordinate2DMake(upperRight.lat, upperRight.lng)
            let southwest = CLLocationCoordinate2DMake(bottomLeft.lat, bottomLeft.lng)
            let bounds = GMSCoordinateBounds(coordinate: northeast, coordinate: southwest)
            let update = GMSCameraUpdate.fit(bounds, with: UIEdgeInsets(top: 0, left: 0, bottom: self.view.frame.height - routeDetailTableView.frame.minY, right: 0))
            UIView.animate(withDuration: 2.0, animations: {
                self.mapView.moveCamera(update)
            })
        }
    }

    func showRoutePolyline() {
        guard let legs = self.selectedRoute?.legs else {
            return
        }
        for step in legs.steps {
            let marker = GMSMarker(position: CLLocationCoordinate2D(latitude: step.startLocation.lat, longitude: step.startLocation.lng))
            marker.title = step.instructions
            marker.icon = UIImage(named: "icon_location")
            marker.map = mapView
        }
        let path = GMSPath(fromEncodedPath: legs.points)
        let polyline = GMSPolyline(path: path)
        polyline.strokeColor = UIColor.blue
        polyline.strokeWidth = 6.0
        polyline.map = mapView
    }

    func showYoubikeRoutePolyline() {
        guard let youbikeRoutes = self.selectedYoubikeRoutes else {
            return
        }
        for youbikeRoute in youbikeRoutes {
            if let youbikeLegs = youbikeRoute.legs {
                let path = GMSPath(fromEncodedPath: youbikeLegs.points)
                let polyline = GMSPolyline(path: path)
                polyline.strokeColor = UIColor.yellow
                polyline.strokeWidth = 6.0
                polyline.map = mapView
                showYoubikeStation()
            }
        }
    }

    func showYoubikeStation() {
        let stations = selectedYoubikeStation
        for station in stations {
            addYoubikeMarker(of: station)
        }
    }

    func setUpView() {
        destinationInfoView.isHidden = true
        destinationInfoView.layer.cornerRadius = 10.0
        destinationInfoView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        searchButton.layer.shadowColor = UIColor(red: 100.0/255.0, green: 100.0/255.0, blue: 100.0/255.0, alpha: 1.0).cgColor
        searchButton.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        searchButton.layer.shadowRadius = 4.0
        searchButton.layer.shadowOpacity = 1.0
        backButton.tintColor = UIColor.gray
        backButton.backgroundColor = UIColor.white
        backButton.layer.cornerRadius = backButton.bounds.width / 2
        showRouteButton.layer.cornerRadius = showRouteButton.bounds.height / 2
        destinationInfoView.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        destinationInfoView.layer.shadowRadius = 4.0
        destinationInfoView.layer.shadowOpacity = 1.0
        destinationInfoView.backgroundColor = UIColor(red: 47.0/255.0, green: 67.0/255.0, blue: 76.0/255.0, alpha: 1.0)
        titleLabel.textColor = .white
        addressLabel.textColor = .white
    }

    func setUpMap() {
        mapView.camera = GMSCameraPosition.camera(withLatitude: getUserLatitude(), longitude: getUserLongitude(), zoom: 15.0)
        mapView.isMyLocationEnabled = true
        mapView.addSubview(searchButton)
        mapView.settings.myLocationButton = true
        mapView.delegate = self
    }

    func setUpRouteDetailTableView() {
        transitTag = 0
        routeDetailTableView.removeFromSuperview()
        routeDetailTableView = UITableView(frame: CGRect(x: 0.0, y: view.bounds.height * 0.4, width: view.bounds.width, height: view.bounds.height * 0.6))
        routeDetailTableView.backgroundColor = UIColor(red: 4.0/255.0, green: 52.0/255.0, blue: 76.0/255.0, alpha: 1.0)
        routeDetailTableView.clipsToBounds = true
        routeDetailTableView.layer.cornerRadius = 20.0
        routeDetailTableView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        routeDetailTableView.separatorStyle = .none
        routeDetailTableView.delegate = self
        routeDetailTableView.dataSource = self
        let nib = UINib(nibName: "RouteDetailTableViewCell", bundle: nil)
        routeDetailTableView.register(nib, forCellReuseIdentifier: "Cell")
        updateCamera()
        view.addSubview(routeDetailTableView)
        routeDetailTableView.reloadData()
    }

    func addYoubikeMarker(of station: YoubikeStation) {
        if let stationLatitude = Double(station.latitude), let stationLongitude = Double(station.longitude) {
            let position = CLLocationCoordinate2D(latitude: stationLatitude, longitude: stationLongitude)
            let marker = GMSMarker(position: position)
            marker.icon = UIImage(named: "icon_bicycle")
            marker.title = station.name
            marker.map = mapView
        }
    }

    func getUserLatitude() -> Double {
        let locationManager = CLLocationManager()
        guard let userLatitude = locationManager.location?.coordinate.latitude else {
            print("Cannot find user's location")
            return 25.042416
        }
        return userLatitude
    }

    func getUserLongitude() -> Double {
        let locationManager = CLLocationManager()
        guard let userLongitude = locationManager.location?.coordinate.longitude else {
            print("Cannot find user's location")
            return 121.564793
        }
        return userLongitude
    }

    func updateLocationButton() {
        mapView.padding = destinationInfoView.isHidden ? UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0) : UIEdgeInsets(top: 0, left: 0, bottom: destinationInfoView.bounds.height, right: 0)
        if isNavigationMode {
            mapView.padding = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let routeViewController = segue.destination as? RouteViewController {
            routeViewController.destinationName = destinationName
            routeViewController.destinationId = destinationId
            routeViewController.routes = routes
            routeViewController.passHandller = { [weak self] (route, youbikeRoute, youbikeStation, isNavigationMode) in
                    self?.selectedRoute = route
                    self?.selectedYoubikeRoutes = youbikeRoute
                if let selectedYoubikeStation = youbikeStation {
                    self?.selectedYoubikeStation = selectedYoubikeStation
                }
                self?.isNavigationMode = isNavigationMode
            }
        }
    }
}

// Google搜尋自動完成
extension MapViewController: GMSAutocompleteViewControllerDelegate {

    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        print("Place name: \(place.name)")
        print("Place address: \(String(describing: place.formattedAddress))")
        print("Place attributions: \(String(describing: place.attributions))")
        dismiss(animated: true, completion: nil)
        destination = place
        destinationId = place.placeID
        destinationName = place.name
        titleLabel.text = place.name
        searchButton.setTitle("  \(place.name)", for: UIControlState.normal)
        addressLabel.text = place.formattedAddress
        isDestinationMode = true
        view.addSubview(destinationInfoView)
    }

    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        print("Error: ", error.localizedDescription)
    }

    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }

    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }

    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}

extension MapViewController: GMSMapViewDelegate {
    // 當點擊地圖其他地方時，隱藏下方資料
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        if isDestinationMode && !isNavigationMode {
            destinationInfoView.isHidden = destinationInfoView.isHidden ? false : true
            updateLocationButton()
        }
    }
}

extension MapViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectedRoute?.legs?.steps.count ?? 2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as? RouteDetailTableViewCell else {
            return UITableViewCell()
        }
        cell.isUserInteractionEnabled = false
        if let step = selectedRoute?.legs?.steps[indexPath.row] {
            //顯示公車或捷運班次及起迄站
            if step.travelMode == "TRANSIT", let transitDetails = step.transitDetail {
                transitTag = transitTag < transitDetails.count ? transitTag : 0
                let transitDetail = transitDetails[transitTag]
                cell.routeDetailLabel.text = "搭乘 [\(transitDetail.lineName)] 從 [\(transitDetail.departureStop.name)] 到 [\(transitDetail.arrivalStop.name)]"
                transitTag += 1
                if transitDetail.lineName != "板南線", transitDetail.lineName != "淡水信義線", transitDetail.lineName != "松山新店線", transitDetail.lineName != "文湖線", transitDetail.lineName != "中和新蘆線" {
                    cell.busInfoButton.isHidden = false
                }
                cell.isUserInteractionEnabled = true
                cell.busInfoButton.tag = indexPath.row
                cell.busInfoButton.addTarget(self, action: #selector(showBusInfo), for: .touchUpInside)
                var dictionary = [String: String]()
                dictionary.updateValue(transitDetail.lineName, forKey: "number")
                dictionary.updateValue(transitDetail.departureStop.name, forKey: "departure")
                dictionary.updateValue(transitDetail.arrivalStop.name, forKey: "arrival")
                transitInfoDictionary.updateValue(dictionary, forKey: indexPath.row)
            } else {
                cell.routeDetailLabel.text  = selectedRoute?.legs?.steps[indexPath.row].instructions
            }
        }

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UITableViewHeaderFooterView()
        headerView.frame = CGRect(x: 0, y: 0, width: routeDetailTableView.bounds.width, height: 30)
        let headerButton = UIButton()
        headerButton.frame = headerView.bounds
        headerButton.layer.backgroundColor = UIColor(red: 8.0/255.0, green: 105.0/255.0, blue: 153.0/255.0, alpha: 1.0).cgColor
        let image = UIImage(named: "icon_roundedRectangle")
        headerButton.setImage(image, for: .normal)
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(showOrHideTableView))
        headerButton.addGestureRecognizer(panGesture)
        headerView.addSubview(headerButton)
        return headerView
    }

    @objc func showOrHideTableView(_ gestureRecognizer: UIPanGestureRecognizer) {
        let normalState = CGRect(x: 0, y: view.bounds.height * 0.4, width: view.bounds.width, height: view.bounds.height)
        let hiddenState = CGRect(x: 0, y: view.bounds.height - 50, width: view.bounds.width, height: view.bounds.height)
        guard gestureRecognizer.view != nil else {return}
        let piece = routeDetailTableView
        let translation = gestureRecognizer.translation(in: piece.superview)
        // 根據手勢拖動情形，更改tableView位置
        if gestureRecognizer.state == .began {
            initialCenter = piece.center
        }
        if gestureRecognizer.state != .cancelled {
            let newCenter = CGPoint(x: initialCenter.x + translation.x, y: initialCenter.y + translation.y)
            if piece.frame.minY >= normalState.minY - 0.0000001 {
                piece.center.y = newCenter.y
            }
        }
        if gestureRecognizer.state == .ended {
            if piece.center.y > initialCenter.y {
                UIView.animate(withDuration: 0.5, animations: {
                    self.view.layoutIfNeeded()
                    piece.frame = hiddenState
                })
            } else {
                UIView.animate(withDuration: 0.5, animations: {
                    self.view.layoutIfNeeded()
                    piece.frame = normalState
                })
            }
            updateCamera()
        }
    }

    @objc func showBusInfo(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let busInfoViewController = storyboard.instantiateViewController(withIdentifier: "BusInfoViewController") as? BusInfoViewController {
            if let dictionary = transitInfoDictionary[sender.tag], let busNumber = dictionary["number"], let departure = dictionary["departure"], let arrival = dictionary["arrival"] {
                busInfoViewController.busNumber = busNumber
                busInfoViewController.departureStopName = departure
                busInfoViewController.arrivalStopName = arrival
            }
            present(busInfoViewController, animated: true, completion: nil)
        }
    }
}
