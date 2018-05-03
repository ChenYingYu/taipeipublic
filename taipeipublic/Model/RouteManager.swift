//
//  RouteManager.swift
//  taipeipublic
//
//  Created by ChenAlan on 2018/5/2.
//  Copyright © 2018年 ChenAlan. All rights reserved.
//

import Foundation
import Alamofire

class RouteManager {
    func requestRoute(originLatitude: Double, originLongitude: Double, destinationId: String) {
        let urlString = "https://maps.googleapis.com/maps/api/directions/json?origin=\(originLatitude),\(originLongitude)&destination=place_id:\(destinationId)&mode=transit&key=\(Constant.googlePlacesAPIKey)&alternatives=true"

        Alamofire.request(urlString).validate().responseJSON { response in
            switch response.result {
            case .success:
                guard let dictionary = response.result.value as? [String: Any] else {
                    print("Cannot parse data as JSON: \(String(describing: response.result.value))")
                    return
                }
                guard let routes = dictionary["routes"] as? [[String: Any]] else {
                    print("Cannot find key 'routes' in data: \(dictionary)")
                    return
                }
                for route in routes {
                    guard let bounds = route["bounds"] as? [String: AnyObject], let northeast = bounds["northeast"] as? [String: Double], let northeastLat = northeast["lat"], let northeastLng = northeast["lng"], let southwest = bounds["southwest"] as? [String: Double], let southwestLat = southwest["lat"], let southwestLng = southwest["lng"] else {
                        print("Cannot find key 'bounds' in routes: \(routes)")
                        return
                    }
                    let newBounds = Bounds(northeast: Location(lat: northeastLat, lng: northeastLng), southwest: Location(lat: southwestLat, lng: southwestLng))
                    print("======================")
                    print(newBounds)
                    print("======================")
                    let routes = [Route]()
                    
                    guard let legs = route["legs"] as? [[String: AnyObject]], legs.count > 0 else {
                        print("Cannot find key 'legs' in routes: \(routes)")
                        return
                    }
                    guard let arrivalTime = legs[0]["arrival_time"] else {
                        return
                    }
                }
            case .failure(let error):
                print(error)
            }
        }
    }
}
