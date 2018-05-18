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

    var navigationMode = false
    var destinationMode = false
    var destination: GMSPlace?
    var destinationId = ""
    var destinationName = ""
    var routes = [Route]()
    var youbikeRoute: Route?
    var seletedRoute: Route?
    var selectedYoubikeRoute: Route?
    var selectedYoubikeStation = [YoubikeStation]()
    var routeInfoTableView = UITableView()
    @IBOutlet weak var searchButton: UIButton!
    // Present the Autocomplete view controller when the button is pressed.
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var showRouteButton: UIButton!
    @IBAction func autocompleteClicked(_ sender: UIButton) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.tintColor = .blue
        autocompleteController.delegate = self
        present(autocompleteController, animated: true, completion: nil)
    }
    @IBOutlet weak var backButton: UIButton!
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let routeViewController = segue.destination as? RouteViewController {
            routeViewController.destinationName = destinationName
            routeViewController.destinationId = destinationId
            routeViewController.routes = routes
            routeViewController.passHandller = { [weak self] (route, youbikeRoute, youbikeStation, isNavigationMode) in
                    self?.seletedRoute = route
                    self?.selectedYoubikeRoute = youbikeRoute
                if let selectedYoubikeStation = youbikeStation {
                    self?.selectedYoubikeStation = selectedYoubikeStation
                }
                self?.navigationMode = isNavigationMode
            }
        }
    }
}

extension MapViewController: GMSAutocompleteViewControllerDelegate {

    // Handle the user's selection.
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
        destinationMode = true
        view.addSubview(infoView)
    }

    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        print("Error: ", error.localizedDescription)
    }

    // User canceled the operation.
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }

    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }

    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }

    override func viewWillAppear(_ animated: Bool) {
        if navigationMode {
            mapView.clear()
            if let place = destination {
                let marker = GMSMarker(position: place.coordinate)
                marker.map = mapView
                mapView.camera = GMSCameraPosition.camera(withLatitude: place.coordinate.latitude, longitude: place.coordinate.longitude, zoom: 15.0)
            }
            self.infoView.isHidden = true
            self.searchButton.isHidden = true
            guard let legs = self.seletedRoute?.legs else {
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
            if let youbikeLegs = self.selectedYoubikeRoute?.legs {
                let path = GMSPath(fromEncodedPath: youbikeLegs.points)
                let polyline = GMSPolyline(path: path)
                polyline.strokeColor = UIColor.yellow
                polyline.strokeWidth = 6.0
                polyline.map = mapView
            }
            let stations = selectedYoubikeStation
            for station in stations {
                addYoubikeMarker(of: station)
            }
            self.backButton.isHidden = false
            mapView.addSubview(backButton)
            setUpRouteInfoTableView()
        } else if destinationMode {
            self.infoView.isHidden = false
            self.searchButton.isHidden = false
            self.backButton.isHidden = true
            mapView.clear()
            if let place = destination {
                let marker = GMSMarker(position: place.coordinate)
                marker.map = mapView
                mapView.camera = GMSCameraPosition.camera(withLatitude: place.coordinate.latitude, longitude: place.coordinate.longitude, zoom: 15.0)
            }
        } else {
            mapView.clear()
            self.backButton.isHidden = true
        }
        updateLocationButton()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        infoView.isHidden = true
        setupView()
        setupMap()
    }
    func setupMap() {
        mapView.camera = GMSCameraPosition.camera(withLatitude: getUserLatitude(), longitude: getUserLongitude(), zoom: 15.0)
        mapView.isMyLocationEnabled = true
        mapView.addSubview(searchButton)
        mapView.settings.myLocationButton = true
        mapView.delegate = self
    }
    func setupView() {
        searchButton.layer.shadowColor = UIColor(red: 100.0/255.0, green: 100.0/255.0, blue: 100.0/255.0, alpha: 1.0).cgColor
        searchButton.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        searchButton.layer.shadowRadius = 4.0
        searchButton.layer.shadowOpacity = 1.0
        backButton.tintColor = UIColor.gray
        backButton.backgroundColor = UIColor.white
        backButton.layer.cornerRadius = backButton.bounds.width / 2
        showRouteButton.layer.cornerRadius = showRouteButton.bounds.height / 2
        infoView.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        infoView.layer.shadowRadius = 4.0
        infoView.layer.shadowOpacity = 1.0
    }
    func setUpRouteInfoTableView() {
        routeInfoTableView.removeFromSuperview()
        routeInfoTableView = UITableView(frame: CGRect(x: 0.0, y: view.bounds.height * 0.4, width: view.bounds.width, height: view.bounds.height * 0.6))
        routeInfoTableView.backgroundColor = UIColor(red: 4.0/255.0, green: 52.0/255.0, blue: 76.0/255.0, alpha: 1.0)
        routeInfoTableView.delegate = self
        routeInfoTableView.dataSource = self
        routeInfoTableView.isScrollEnabled = false
        view.addSubview(routeInfoTableView)
        routeInfoTableView.reloadData()
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
    mapView.padding = infoView.isHidden ? UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0) : UIEdgeInsets(top: 0, left: 0, bottom: infoView.bounds.height, right: 0)
    }
}

extension MapViewController: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        if destinationMode && !navigationMode {
            infoView.isHidden = infoView.isHidden ? false : true
            updateLocationButton()
        }
    }
}

extension MapViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return seletedRoute?.legs?.steps.count ?? 2
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.backgroundColor = UIColor(red: 47.0/255.0, green: 67.0/255.0, blue: 76.0/255.0, alpha: 1.0)
        cell.textLabel?.text = seletedRoute?.legs?.steps[indexPath.row].instructions
        cell.textLabel?.textColor = UIColor.white
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
        headerView.frame = CGRect(x: 0, y: 0, width: routeInfoTableView.bounds.width, height: 30)
        let headerButton = UIButton()
        headerButton.frame = headerView.bounds
        headerButton.layer.backgroundColor = UIColor(red: 8.0/255.0, green: 105.0/255.0, blue: 153.0/255.0, alpha: 1.0).cgColor
        headerButton.addTarget(self, action: #selector(showOrHideTableView), for: .touchUpInside)
        headerView.addSubview(headerButton)
        return headerView
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        showOrHideTableView()
    }
    @objc func showOrHideTableView() {
        let normalState = CGRect(x: 0, y: view.bounds.height * 0.4, width: view.bounds.width, height: view.bounds.height * 0.6)
        let hiddenState = CGRect(x: 0, y: view.bounds.height - 30, width: view.bounds.width, height: 30)
        routeInfoTableView.frame = routeInfoTableView.frame.height == 30 ? normalState : hiddenState
    }
}
