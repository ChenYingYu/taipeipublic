//
//  RouteManager.swift
//  taipeipublic
//
//  Created by ChenAlan on 2018/5/2.
//  Copyright © 2018年 ChenAlan. All rights reserved.
//

import Foundation
import Alamofire

protocol RouteManagerDelegate: class {
    func manager(_ manager: RouteManager, didGet routes: [Route])
    func manager(_ manager: RouteManager, didFailWith error: Error)
}

protocol YoubikeRouteManagerDelegate: class {
    func youbikeManager(_ manager: RouteManager, didGet routes: [Route])
    func youbikeManager(_ manager: RouteManager, didFailWith error: Error)
}

class RouteManager {
    weak var delegate: RouteManagerDelegate?
    weak var youbikeDelegate: YoubikeRouteManagerDelegate?
    var myRoutes = [Route]()
    func requestRoute(originLatitude: Double, originLongitude: Double, destinationId: String) {
        let urlString = "https://maps.googleapis.com/maps/api/directions/json?origin=\(originLatitude),\(originLongitude)&destination=place_id:\(destinationId)&mode=transit&key=\(Constant.googlePlacesAPIKey)&alternatives=true"
        Alamofire.request(urlString).validate().responseJSON { response in
            switch response.result {
            case .success:
                self.myRoutes = [Route]()
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
                    guard let legs = route["legs"] as? [[String: AnyObject]], legs.count > 0 else {
                        print("Cannot find key 'legs' in routes: \(routes)")
                        return
                    }
                    let leg = legs[0]
                    guard let arrival = leg["arrival_time"] as? [String: AnyObject], let arrivalTime = arrival["text"] as? String, let departure = leg["departure_time"] as? [String: AnyObject], let departureTime = departure["text"] as? String, let distance = leg["distance"] as? [String: AnyObject], let distanceText = distance["text"] as? String, let duration = leg["duration"] as? [String: AnyObject], let durationText = duration["text"] as? String else {
                        return
                    }
                    guard let endAddress = leg["end_address"] as? String, let endLocation = leg["end_location"] as? [String: AnyObject], let endLocationlat = endLocation["lat"] as? Double, let endLocationLng = endLocation["lng"] as? Double, let startAddress = leg["start_address"] as? String, let startLocation = leg["start_location"] as? [String: AnyObject], let startLocationlat = startLocation["lat"] as? Double, let startLocationLng = startLocation["lng"] as? Double else {
                        return
                    }
                    let newEndLocation = Location(lat: endLocationlat, lng: endLocationLng)
                    let newStartLocation = Location(lat: startLocationlat, lng: startLocationLng)
                var newSteps = [Step]()
                    guard let steps = leg["steps"] as? [[String: AnyObject]] else {
                        return
                    }
                for step in steps {
                    guard let distance = step["distance"] as? [String: AnyObject], let distanceText = distance["text"] as? String, let duration = step["duration"] as? [String: AnyObject], let durationText = duration["text"] as? String else {
                        return
                    }
                    guard let endLocation = step["end_location"] as? [String: AnyObject], let endLocationlat = endLocation["lat"] as? Double, let endLocationLng = endLocation["lng"] as? Double, let startLocation = step["start_location"] as? [String: AnyObject], let startLocationlat = startLocation["lat"] as? Double, let startLocationLng = startLocation["lng"] as? Double else {
                        return
                    }
                    let newEndLocation = Location(lat: endLocationlat, lng: endLocationLng)
                    let newStartLocation = Location(lat: startLocationlat, lng: startLocationLng)
                    guard let instructions = step["html_instructions"] as? String, let polyline = step["polyline"] as? [String: AnyObject], let points = polyline["points"] as? String else {
                        return
                    }
                    guard let travelMode = step["travel_mode"] as? String else {
                        return
                    }
                    var walkingDetail = [Step]()
                    var transitDetail = [Transit]()
                    if travelMode == "WALKING" {
                        
                    } else if travelMode == "TRANSIT" {
                        
                    }
                    let newStep = Step(distance: distanceText, duration: durationText, endLocation: newEndLocation, instructions: instructions, startLocation: newStartLocation, polyline: points, walkingDetail: walkingDetail, transitDetail: transitDetail, travelMode: travelMode)
                    newSteps.append(newStep)
                }
                guard let polyline = route["overview_polyline"] as? [String: String], let points = polyline["points"] else {
                    return
                }
                let newLegs = Legs(arrivalTime: arrivalTime, departureTime: departureTime, distance: distanceText, duration: durationText, endAddress: endAddress, endLocation: newEndLocation, startAddress: startAddress, startLocation: newStartLocation, steps: newSteps, points: points)
                print("======================")
                print(newLegs)
                print("======================")
                let myRoute = Route(bounds: newBounds, legs: newLegs)
                    self.myRoutes.append(myRoute)
                }
                DispatchQueue.main.async {
                    self.delegate?.manager(self, didGet: self.myRoutes)
                }
            case .failure(let error):
                self.delegate?.manager(self, didFailWith: error)
            }
        }
    }
    func requestYoubikeRoute(originLatitude: Double, originLongitude: Double, destinationLatitude: Double, destinationLongitude: Double, through startYoubikeStation: YoubikeStation, and endYoubikeStation: YoubikeStation) {
        let urlString = "https://maps.googleapis.com/maps/api/directions/json?origin=\(originLatitude),\(originLongitude)&destination=\(destinationLatitude),\(destinationLongitude)&waypoints=via:\(startYoubikeStation.latitude)%2C\(startYoubikeStation.longitude)%7Cvia:\(endYoubikeStation.latitude)%2C\(endYoubikeStation.longitude)&mode=walking&key=\(Constant.googlePlacesAPIKey)"
        Alamofire.request(urlString).validate().responseJSON { response in
            switch response.result {
            case .success:
                self.myRoutes = [Route]()
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
                    guard let legs = route["legs"] as? [[String: AnyObject]], legs.count > 0 else {
                        print("Cannot find key 'legs' in routes: \(routes)")
                        return
                    }
                    let leg = legs[0]
                    guard let endAddress = leg["end_address"] as? String, let endLocation = leg["end_location"] as? [String: AnyObject], let endLocationlat = endLocation["lat"] as? Double, let endLocationLng = endLocation["lng"] as? Double, let startAddress = leg["start_address"] as? String, let startLocation = leg["start_location"] as? [String: AnyObject], let startLocationlat = startLocation["lat"] as? Double, let startLocationLng = startLocation["lng"] as? Double else {
                        return
                    }
                    let newEndLocation = Location(lat: endLocationlat, lng: endLocationLng)
                    let newStartLocation = Location(lat: startLocationlat, lng: startLocationLng)
                    var newSteps = [Step]()
                    guard let steps = leg["steps"] as? [[String: AnyObject]] else {
                        return
                    }
                    for step in steps {
                        guard let distance = step["distance"] as? [String: AnyObject], let distanceText = distance["text"] as? String, let duration = step["duration"] as? [String: AnyObject], let durationText = duration["text"] as? String else {
                            return
                        }
                        guard let endLocation = step["end_location"] as? [String: AnyObject], let endLocationlat = endLocation["lat"] as? Double, let endLocationLng = endLocation["lng"] as? Double, let startLocation = step["start_location"] as? [String: AnyObject], let startLocationlat = startLocation["lat"] as? Double, let startLocationLng = startLocation["lng"] as? Double else {
                            return
                        }
                        let newEndLocation = Location(lat: endLocationlat, lng: endLocationLng)
                        let newStartLocation = Location(lat: startLocationlat, lng: startLocationLng)
                        guard let instructions = step["html_instructions"] as? String, let polyline = step["polyline"] as? [String: AnyObject], let points = polyline["points"] as? String else {
                            return
                        }
                        guard let travelMode = step["travel_mode"] as? String else {
                            return
                        }
                        var walkingDetail = [Step]()
                        var transitDetail = [Transit]()
                        let newStep = Step(distance: distanceText, duration: durationText, endLocation: newEndLocation, instructions: instructions, startLocation: newStartLocation, polyline: points, walkingDetail: walkingDetail, transitDetail: transitDetail, travelMode: travelMode)
                        newSteps.append(newStep)
                    }
                    guard let polyline = route["overview_polyline"] as? [String: String], let points = polyline["points"] else {
                        return
                    }
                    let newLegs = Legs(arrivalTime: nil, departureTime: nil, distance: nil, duration: nil, endAddress: endAddress, endLocation: newEndLocation, startAddress: startAddress, startLocation: newStartLocation, steps: newSteps, points: points)
                    print("======================")
                    print(newLegs)
                    print("======================")
                    let myRoute = Route(bounds: newBounds, legs: newLegs)
                    self.myRoutes.append(myRoute)
                }
                DispatchQueue.main.async {
                    self.youbikeDelegate?.youbikeManager(self, didGet: self.myRoutes)
                }
            case .failure(let error):
                self.youbikeDelegate?.youbikeManager(self, didFailWith: error)
            }
        }
    }
}
