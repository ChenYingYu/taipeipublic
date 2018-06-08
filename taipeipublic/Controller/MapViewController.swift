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

class MapViewController: UIViewController {

    var isNavigationMode = false
    var isDestinationMode = false
    //搜尋目的地後使用的變數
    var destination: GMSPlace?
    var destinationId = Constant.DefaultValue.emptyString
    var destinationName = Constant.DefaultValue.emptyString
    //進行導航時使用的變數
    var routes = [Route]()
    var youbikeRoute: Route?
    var selectedRoute: Route?
    var selectedYoubikeRoutes: [Route]?
    var selectedYoubikeStation = [YoubikeStation]()
    // 紀錄公車班次時使用的變數
    var transitTag = Constant.DefaultValue.zero
    var transitInfoDictionary = [Int: [String: String]]()
    var initialCenter = CGPoint()

    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var destinationInfoView: DestinationInfoView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet var routeDetailTableView: UITableView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerButton: UIButton!
    @IBAction func showGoogleSearchController(_ sender: UIButton) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.tintColor = .blue
        autocompleteController.delegate = self
        present(autocompleteController, animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpMapView()
    }

    override func viewWillAppear(_ animated: Bool) {
        resetMapView()
        startNavigating()
    }

    func resetMapView() {
        mapView.clear()
        self.backButton.isHidden = true
        self.destinationInfoView.isHidden = true
        self.searchButton.isHidden = true
    }

    func startNavigating() {
        if isNavigationMode {
            showDestinationMarker()
            updateCameraToFitMapBounds()
            drawRoutePolyline()
            drawYoubikeRoutePolyline()
            setUpRouteDetailTableView()
            backButton.addTarget(self, action: #selector(showRoute), for: .touchUpInside)
            mapView.addSubview(backButton)
            self.backButton.isHidden = false
        } else if isDestinationMode {
            showDestinationMarker()
            routeDetailTableView.removeFromSuperview()
            destinationInfoView.showRouteButton.addTarget(self, action: #selector(showRoute), for: .touchUpInside)
            self.destinationInfoView.isHidden = false
            self.searchButton.isHidden = false
        } else {
            self.searchButton.isHidden = false
        }
        updateMapPadding()
    }

    func showDestinationMarker() {
        if let place = destination {
            let marker = GMSMarker(position: place.coordinate)
            marker.map = mapView
            mapView.camera = GMSCameraPosition.camera(withLatitude: place.coordinate.latitude, longitude: place.coordinate.longitude, zoom: 15.0)
        }
    }

    func updateCameraToFitMapBounds() {
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

    func drawRoutePolyline() {
        guard let legs = self.selectedRoute?.legs else {
            return
        }
        let leg = legs[0]
        for step in leg.steps {
            let marker = GMSMarker(position: CLLocationCoordinate2D(latitude: step.startLocation.lat, longitude: step.startLocation.lng))
            marker.title = step.instructions
            marker.icon = UIImage(named: Constant.Icon.location)
            marker.map = mapView
            drawPath(of: step.polyline.points, withColor: .blue)
        }
    }

    func drawYoubikeRoutePolyline() {
        guard let youbikeRoutes = self.selectedYoubikeRoutes else {
            return
        }
        for youbikeRoute in youbikeRoutes {
            drawPath(of: youbikeRoute.polyline.points, withColor: .yellow)
            showYoubikeStation()
        }
    }

    func showYoubikeStation() {
        let stations = selectedYoubikeStation
        for station in stations {
            addYoubikeMarker(of: station)
        }
    }

    func drawPath(of points: String, withColor color: UIColor) {
        let path = GMSPath(fromEncodedPath: points)
        let polyline = GMSPolyline(path: path)
        polyline.strokeColor = color
        polyline.strokeWidth = CGFloat(Constant.Polyline.width)
        polyline.map = mapView
    }

    func addYoubikeMarker(of station: YoubikeStation) {
        if let stationLatitude = Double(station.latitude), let stationLongitude = Double(station.longitude) {
            let position = CLLocationCoordinate2D(latitude: stationLatitude, longitude: stationLongitude)
            let marker = GMSMarker(position: position)
            marker.icon = UIImage(named: Constant.Icon.bicycle)
            marker.title = station.name
            marker.map = mapView
        }
    }

    func setUpMapView() {
        let locationManager = CLLocationManager()
        mapView.camera = GMSCameraPosition.camera(withLatitude: locationManager.getUserLatitude(), longitude: locationManager.getUserLongitude(), zoom: 15.0)
        mapView.isMyLocationEnabled = true
        mapView.addSubview(searchButton)
        mapView.settings.myLocationButton = true
        mapView.delegate = self
    }

    func setUpRouteDetailTableView() {
        transitTag = Constant.DefaultValue.zero
        routeDetailTableView.frame = CGRect(x: 0.0, y: view.bounds.height * 0.4, width: view.bounds.width, height: view.bounds.height)
        routeDetailTableView.delegate = self
        routeDetailTableView.dataSource = self
        let nib = UINib(nibName: String(describing: RouteDetailTableViewCell.self), bundle: nil)
        routeDetailTableView.register(nib, forCellReuseIdentifier: Constant.Identifier.cell)
        updateCameraToFitMapBounds()
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(showOrHideTableView))
        headerButton.addGestureRecognizer(panGesture)
        view.addSubview(routeDetailTableView)
        routeDetailTableView.reloadData()
    }

    func updateMapPadding() {
        mapView.padding = destinationInfoView.isHidden ? UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0) : UIEdgeInsets(top: 0, left: 0, bottom: destinationInfoView.bounds.height, right: 0)
        if isNavigationMode {
            mapView.padding = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        }
    }

    @objc func showRoute(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: Constant.Storyboard.main, bundle: nil)
        if let routeViewController = storyboard.instantiateViewController(withIdentifier: Constant.Identifier.routeViewController) as? RouteViewController {
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
            present(routeViewController, animated: true, completion: nil)
        }
    }
}

// Google 搜尋自動完成
extension MapViewController: GMSAutocompleteViewControllerDelegate {

    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        dismiss(animated: true, completion: nil)
        destination = place
        destinationId = place.placeID
        destinationName = place.name
        destinationInfoView.titleLabel.text = place.name
        searchButton.setTitle("  \(place.name)", for: UIControlState.normal)
        destinationInfoView.addressLabel.text = place.formattedAddress
        isDestinationMode = true
        view.addSubview(destinationInfoView)
    }

    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        print(Constant.ErrorMessage.errorPrefix, error.localizedDescription)
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
            updateMapPadding()
        }
    }
}

extension MapViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectedRoute?.legs?[0].steps.count ?? 2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Constant.Identifier.cell) as? RouteDetailTableViewCell else {
            return UITableViewCell()
        }
        cell.isUserInteractionEnabled = false
        if let legs = selectedRoute?.legs {
            let leg = legs[0]
            let step = leg.steps[indexPath.row]
            //顯示公車或捷運班次及起迄站
            if step.travelMode == Constant.TravelMode.transit, let transitDetail = step.transitDetail {
                let lineName = transitDetail.lineDetails.shortName
                let transitMessage = Constant.TransitMessage.take + lineName + Constant.TransitMessage.from + transitDetail.departureStop.name + Constant.TransitMessage.to + transitDetail.arrivalStop.name + "]"
                cell.routeDetailLabel.text = transitMessage
                transitTag += 1
                if transitDetail.lineDetails.vehicle.type == Constant.Vehicle.bus {
                    cell.busInfoButton.isHidden = false
                } else {
                    cell.busInfoButton.isHidden = true
                }
                cell.isUserInteractionEnabled = true
                cell.busInfoButton.tag = indexPath.row
                cell.busInfoButton.addTarget(self, action: #selector(showBusInfo), for: .touchUpInside)
                var dictionary = [String: String]()
                dictionary.updateValue(lineName, forKey: Constant.BusInfoKey.busName)
                dictionary.updateValue(transitDetail.departureStop.name, forKey: Constant.BusInfoKey.departureStop)
                dictionary.updateValue(transitDetail.arrivalStop.name, forKey: Constant.BusInfoKey.arrivalStop)
                transitInfoDictionary.updateValue(dictionary, forKey: indexPath.row)
            } else {
                cell.routeDetailLabel.text = selectedRoute?.legs?[0].steps[indexPath.row].instructions
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Constant.Identifier.cell) as? RouteDetailTableViewCell else {
            return
        }
        cell.busInfoButton.isHidden = true
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }

    @objc func showOrHideTableView(_ gestureRecognizer: UIPanGestureRecognizer) {
        let normalState = CGRect(x: 0, y: view.bounds.height * 0.4, width: view.bounds.width, height: view.bounds.height)
        let hiddenState = CGRect(x: 0, y: view.bounds.height - 50, width: view.bounds.width, height: view.bounds.height)
        guard gestureRecognizer.view != nil else {return}
        let piece = routeDetailTableView
        let translation = gestureRecognizer.translation(in: piece?.superview)
        // 根據手勢拖動情形，更改 routeDetailTableView 垂直位置
        if gestureRecognizer.state == .began {
            if let center = piece?.center {
                initialCenter = center
            }
        }
        if gestureRecognizer.state != .cancelled {
            let newCenter = CGPoint(x: initialCenter.x + translation.x, y: initialCenter.y + translation.y)
            if let minY = piece?.frame.minY {
                if minY >= normalState.minY - 0.0000001 {
                    piece?.center.y = newCenter.y
                }
            }
        }
        if gestureRecognizer.state == .ended {
            if let centerY = piece?.center.y {
                if centerY > initialCenter.y {
                    UIView.animate(withDuration: 0.5, animations: {
                        self.view.layoutIfNeeded()
                        piece?.frame = hiddenState
                    })
                } else {
                    UIView.animate(withDuration: 0.5, animations: {
                        self.view.layoutIfNeeded()
                        piece?.frame = normalState
                    })
                }
                updateCameraToFitMapBounds()
            }
        }
    }

    @objc func showBusInfo(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: Constant.Storyboard.main, bundle: nil)
        if let busInfoViewController = storyboard.instantiateViewController(withIdentifier: Constant.Identifier.busInfoViewController) as? BusInfoViewController {
            if let dictionary = transitInfoDictionary[sender.tag], let busName = dictionary[Constant.BusInfoKey.busName], let departure = dictionary[Constant.BusInfoKey.departureStop], let arrival = dictionary[Constant.BusInfoKey.arrivalStop] {
                busInfoViewController.busName = busName
                busInfoViewController.departureStopName = departure
                busInfoViewController.arrivalStopName = arrival
            }
            present(busInfoViewController, animated: true, completion: nil)
        }
    }
}

extension CLLocationManager {

    func getUserLatitude() -> Double {
        guard let userLatitude = self.location?.coordinate.latitude else {
            print(Constant.ErrorMessage.userLocationNotFound)
            return 25.042416
        }
        return userLatitude
    }

    func getUserLongitude() -> Double {
        guard let userLongitude = self.location?.coordinate.longitude else {
            print(Constant.ErrorMessage.userLocationNotFound)
            return 121.564793
        }
        return userLongitude
    }
}
