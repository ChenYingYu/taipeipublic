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
    @IBOutlet weak var searchButton: UIButton!
    // Present the Autocomplete view controller when the button is pressed.
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBAction func showRoute(_ sender: UIButton) {
        let routeManager = RouteManager()
        routeManager.requestRoute(originLatitude: getUserLatitude(), originLongitude: getUserLongitude(), destinationId: destinationId)
    }
    @IBAction func autocompleteClicked(_ sender: UIButton) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.tintColor = .blue
        autocompleteController.delegate = self
        present(autocompleteController, animated: true, completion: nil)
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
        titleLabel.text = place.name
        addressLabel.text = place.formattedAddress
        infoView.isHidden = false

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
