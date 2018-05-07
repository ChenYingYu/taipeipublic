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

class MapViewController: UIViewController {

    var destinationId = ""
    var destinationName = ""
    var routes = [Route]()
    var seletedRoute = Route(bounds: nil, legs: nil)
    @IBOutlet weak var searchButton: UIButton!
    // Present the Autocomplete view controller when the button is pressed.
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBAction func showRoute(_ sender: UIButton) {

    }
    @IBAction func autocompleteClicked(_ sender: UIButton) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.tintColor = .blue
        autocompleteController.delegate = self
        present(autocompleteController, animated: true, completion: nil)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let routeViewController = segue.destination as? RouteViewController {
            routeViewController.destinationName = destinationName
            routeViewController.destinationId = destinationId
            routeViewController.routes = routes
            routeViewController.passHandller = { [weak self] (route) in
                self?.seletedRoute = route
            }
        }
        self.infoView.isHidden = true
        self.searchButton.isHidden = true
    }
}

extension MapViewController: GMSAutocompleteViewControllerDelegate {

    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        print("Place name: \(place.name)")
        print("Place address: \(String(describing: place.formattedAddress))")
        print("Place attributions: \(String(describing: place.attributions))")
        dismiss(animated: true, completion: nil)
        let marker = GMSMarker(position: place.coordinate)
        marker.map = mapView
        mapView.camera = GMSCameraPosition.camera(withLatitude: place.coordinate.latitude, longitude: place.coordinate.longitude, zoom: 15.0)
        destinationId = place.placeID
        destinationName = place.name
        titleLabel.text = place.name
        searchButton.setTitle(place.name, for: UIControlState.normal)
        addressLabel.text = place.formattedAddress
        infoView.isHidden = false
        let routeManager = RouteManager()
        routeManager.delegate = self
        routeManager.requestRoute(originLatitude: getUserLatitude(), originLongitude: getUserLongitude(), destinationId: destinationId)

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
        guard let legs = self.seletedRoute.legs else {
            return
        }
        let path = GMSPath(fromEncodedPath: legs.points)
        let polyline = GMSPolyline(path: path)
        polyline.strokeColor = UIColor.blue
        polyline.strokeWidth = 6.0
        polyline.map = mapView
        for step in legs.steps {
            let position = CLLocationCoordinate2D(latitude: step.startLocation.lat, longitude: step.startLocation.lng)
            let marker = GMSMarker(position: position)
            marker.icon = UIImage(named: "icon_location")
            marker.title = step.instructions
            marker.map = mapView
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        infoView.isHidden = true
        setupButton()
        setupMap()
    }

    func setupMap() {
        mapView.camera = GMSCameraPosition.camera(withLatitude: getUserLatitude(), longitude: getUserLongitude(), zoom: 15.0)
        mapView.isMyLocationEnabled = true
        mapView.addSubview(searchButton)
        mapView.settings.myLocationButton = true
    }

    func setupButton() {
        searchButton.layer.shadowColor = UIColor(red: 100/255, green: 100/255, blue: 100/255, alpha: 1.0).cgColor
        searchButton.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        searchButton.layer.shadowRadius = 4.0
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

extension MapViewController: RouteManagerDelegate {
    func manager(_ manager: RouteManager, didGet routes: [Route]) {
        self.routes = routes
    }
    func manager(_ manager: RouteManager, didFailWith error: Error) {
        print("Found Error:\n\(error)\n")
    }
}
