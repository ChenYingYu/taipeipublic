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
    func youbikeManager(_ manager: RouteManager, didGet routes: [Route], atRouteIndex index: Int)
    func youbikeManager(_ manager: RouteManager, didFailWith error: Error)
}

protocol BusRouteManagerDelegate: class {
    func busManager(_ manager: RouteManager, didGet routes: [BusRoute])
    func busManager(_ manager: RouteManager, didFailWith error: Error)
}

protocol BusStatusManagerDelegate: class {
    func busStatusManager(_ manager: RouteManager, didGet status: [BusStatus])
    func busStatusManager(_ manager: RouteManager, didFailWith error: Error)
}

class RouteManager {
    weak var delegate: RouteManagerDelegate?
    weak var youbikeDelegate: YoubikeRouteManagerDelegate?
    weak var busDelegate: BusRouteManagerDelegate?
    weak var busStatusDelegate: BusStatusManagerDelegate?
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
                    var arrival = ""
                    var departure = ""
                    if let newArrival = leg["arrival_time"] as? [String: AnyObject], let arrivalTime = newArrival["text"] as? String, let newDeparture = leg["departure_time"] as? [String: AnyObject], let departureTime = newDeparture["text"] as? String {
                        arrival = arrivalTime
                        departure = departureTime
                    }
                    guard let distance = leg["distance"] as? [String: AnyObject], let distanceText = distance["text"] as? String, let duration = leg["duration"] as? [String: AnyObject], let durationText = duration["text"] as? String else {
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
                var transitDetail = [Transit]()
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
                    let walkingDetail = [Step]()
                    var transit: Transit?
                    if travelMode == "WALKING" {

                    } else if travelMode == "TRANSIT" {
                        if let transitDetails = step["transit_details"] as? [String: AnyObject] {
                            if let arrivalStop = transitDetails["arrival_stop"] as? [String: AnyObject], let arrivalLocation = arrivalStop["location"] as? [String: Double], let arrivalLatitude = arrivalLocation["lat"], let arrivalLongitude = arrivalLocation["lng"], let arricalName  = arrivalStop["name"] as? String {
                                if let departureStop = transitDetails["departure_stop"] as? [String: AnyObject], let departureLocation = departureStop["location"] as? [String: Double], let departureLatitude = departureLocation["lat"], let departureLongitude = departureLocation["lng"], let departureName = departureStop["name"] as? String {
                                    if let arrivalTimeDict = transitDetails["arrival_time"] as? [String: AnyObject], let arrivalTime = arrivalTimeDict["text"] as? String, let departureTimeDict = transitDetails["departure_time"] as? [String: AnyObject], let departureTime = departureTimeDict["text"] as? String, let line = transitDetails["line"] as? [String: AnyObject], let lineName = line["short_name"] as? String {
                                        transit = Transit(arrivalStop: Stop(location: Location(lat: arrivalLatitude, lng: arrivalLongitude), name: arricalName), arrivalTime: arrivalTime, departureStop: Stop(location: Location(lat: departureLatitude, lng: departureLongitude), name: departureName), departureTime: departureTime, lineName: lineName)
                                        if let newTransit = transit {
                                            transitDetail.append(newTransit)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    let newStep = Step(distance: distanceText, duration: durationText, endLocation: newEndLocation, instructions: instructions, startLocation: newStartLocation, polyline: points, walkingDetail: walkingDetail, transitDetail: transitDetail, travelMode: travelMode)
                    newSteps.append(newStep)
                }
                guard let polyline = route["overview_polyline"] as? [String: String], let points = polyline["points"] else {
                    return
                }
                let newLegs = Legs(arrivalTime: arrival, departureTime: departure, distance: distanceText, duration: durationText, endAddress: endAddress, endLocation: newEndLocation, startAddress: startAddress, startLocation: newStartLocation, steps: newSteps, points: points)
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

    func requestYoubikeRoute(originLatitude: Double, originLongitude: Double, destinationLatitude: Double, destinationLongitude: Double, through startYoubikeStation: YoubikeStation, and endYoubikeStation: YoubikeStation, withRouteIndex index: Int) {
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
                        let walkingDetail = [Step]()
                        let transitDetail = [Transit]()
                        let newStep = Step(distance: distanceText, duration: durationText, endLocation: newEndLocation, instructions: instructions, startLocation: newStartLocation, polyline: points, walkingDetail: walkingDetail, transitDetail: transitDetail, travelMode: travelMode)
                        newSteps.append(newStep)
                    }
                    guard let polyline = route["overview_polyline"] as? [String: String], let points = polyline["points"] else {
                        return
                    }
                    let newLegs = Legs(arrivalTime: nil, departureTime: nil, distance: nil, duration: nil, endAddress: endAddress, endLocation: newEndLocation, startAddress: startAddress, startLocation: newStartLocation, steps: newSteps, points: points)
                    let myRoute = Route(bounds: newBounds, legs: newLegs)
                    self.myRoutes.append(myRoute)
                    DispatchQueue.main.async {
                        self.youbikeDelegate?.youbikeManager(self, didGet: self.myRoutes, atRouteIndex: index)
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.youbikeDelegate?.youbikeManager(self, didFailWith: error)
                }
            }
        }
    }

    func requestBusStopInfo(ofRouteName routeName: String) {
        let dateFormater = DateFormatter()
        dateFormater.dateFormat = "EE, dd MMM YYYY HH:mm:ss zzz"
        dateFormater.timeZone = TimeZone(identifier: "GMT")
        let currentDate = Date()
        let customDate = dateFormater.string(from: currentDate)
        let base64String = "x-date: \(customDate)".hmac(algorithm: HMACAlgorithm.SHA1, key: Constant.PTXAppKey)

        let headers = [
            "Authorization": "hmac username=\"\(Constant.PTXAppID)\", algorithm=\"hmac-sha1\", headers=\"x-date\", signature=\"\(base64String)\"",
            "x-date": customDate
            ]

        let urlParams = [
            "$format": "JSON"
            ]

        let urlString = "http://ptx.transportdata.tw/MOTC/v2/Bus/StopOfRoute/City/Taipei/\(routeName)"

        guard let URL = NSURL(string: urlString.addingPercentEncoding(withAllowedCharacters: (NSCharacterSet.urlQueryAllowed))!) else {
            print("URL Encoding Fail")
            return
        }

        Alamofire.request(URL.relativeString, method: .get, parameters: urlParams, headers: headers)
            .validate()
            .responseJSON { response in
                if response.result.error == nil {

                    guard let value = response.result.value else {
                        print("Value Not Found")
                        return
                    }

                    guard let data = try? JSONSerialization.data(withJSONObject: value) else {
                        print("Cannot parse data as JSON")
                        return
                    }

                    do {
                        let busRoutes = try JSONDecoder().decode([BusRoute].self, from: data)
                        self.busDelegate?.busManager(self, didGet: busRoutes)
                    } catch let error {
                        self.busDelegate?.busManager(self, didFailWith: error)
                    }
                } else {
                    self.busDelegate?.busManager(self, didFailWith: response.result.error!)
                }
        }
    }

    func requestBusStatus(ofRouteName routeName: String) {

        let dateFormater = DateFormatter()
        dateFormater.dateFormat = "EE, dd MMM YYYY HH:mm:ss zzz"
        dateFormater.timeZone = TimeZone(identifier: "GMT")
        let currentDate = Date()
        let customDate = dateFormater.string(from: currentDate)
        let base64String = "x-date: \(customDate)".hmac(algorithm: HMACAlgorithm.SHA1, key: Constant.PTXAppKey)
        let headers = [
            "Authorization": "hmac username=\"\(Constant.PTXAppID)\", algorithm=\"hmac-sha1\", headers=\"x-date\", signature=\"\(base64String)\"",
            "x-date": customDate
            ]

        let urlParams = [
            "$format": "JSON"
            ]

        let urlString = "http://ptx.transportdata.tw/MOTC/v2/Bus/EstimatedTimeOfArrival/City/Taipei/\(routeName)"

        guard let URL = NSURL(string: urlString.addingPercentEncoding(withAllowedCharacters: (NSCharacterSet.urlQueryAllowed))!) else {
            print("URL Encoding Fail")
            return
        }

        Alamofire.request(URL.relativeString, method: .get, parameters: urlParams, headers: headers)
            .validate(statusCode: 200..<300)
            .responseJSON { response in
                if response.result.error == nil {

                    guard let value = response.result.value else {
                        print("Value Not Found")
                        return
                    }

                    guard let data = try? JSONSerialization.data(withJSONObject: value) else {
                        print("Cannot parse data as JSON")
                        return
                    }

                    do {
                        let busStatus = try JSONDecoder().decode([BusStatus].self, from: data)
                        self.busStatusDelegate?.busStatusManager(self, didGet: busStatus)
                    } catch let error {
                        self.busStatusDelegate?.busStatusManager(self, didFailWith: error)
                    }
                } else {
                    self.busStatusDelegate?.busStatusManager(self, didFailWith: response.result.error!)
                }
        }
    }
}

enum HMACAlgorithm {
    case MD5, SHA1, SHA224, SHA256, SHA384, SHA512

    func toCCHmacAlgorithm() -> CCHmacAlgorithm {
        var result: Int = 0
        switch self {
        case .MD5:
            result = kCCHmacAlgMD5
        case .SHA1:
            result = kCCHmacAlgSHA1
        case .SHA224:
            result = kCCHmacAlgSHA224
        case .SHA256:
            result = kCCHmacAlgSHA256
        case .SHA384:
            result = kCCHmacAlgSHA384
        case .SHA512:
            result = kCCHmacAlgSHA512
        }
        return CCHmacAlgorithm(result)
    }

    func digestLength() -> Int {
        var result: CInt = 0
        switch self {
        case .MD5:
            result = CC_MD5_DIGEST_LENGTH
        case .SHA1:
            result = CC_SHA1_DIGEST_LENGTH
        case .SHA224:
            result = CC_SHA224_DIGEST_LENGTH
        case .SHA256:
            result = CC_SHA256_DIGEST_LENGTH
        case .SHA384:
            result = CC_SHA384_DIGEST_LENGTH
        case .SHA512:
            result = CC_SHA512_DIGEST_LENGTH
        }
        return Int(result)
    }
}

extension String {
    func hmac(algorithm: HMACAlgorithm, key: String) -> String {
        let cKey = key.cString(using: String.Encoding.utf8)
        let cData = self.cString(using: String.Encoding.utf8)
        var result = [CUnsignedChar](repeating: 0, count: Int(algorithm.digestLength()))
        CCHmac(algorithm.toCCHmacAlgorithm(), cKey!, Int(strlen(cKey!)), cData!, Int(strlen(cData!)), &result)
        let hmacData: NSData = NSData(bytes: result, length: (Int(algorithm.digestLength())))
        let hmacBase64 = hmacData.base64EncodedString(options: NSData.Base64EncodingOptions.lineLength76Characters)
        return String(hmacBase64)
    }
}
