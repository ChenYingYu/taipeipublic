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

            let urlParams = [
                "origin": "\(originLatitude),\(originLongitude)",
                "destination": "place_id:\(destinationId)",
                "mode": "transit",
                "key": Constant.googlePlacesAPIKey,
                "alternatives": "true"
                ]

            Alamofire.request("https://maps.googleapis.com/maps/api/directions/json", method: .get, parameters: urlParams)
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
                            let root = try JSONDecoder().decode(Root.self, from: data)
                            let routes = root.routes
                            self.delegate?.manager(self, didGet: routes)
                        } catch let error {
                            self.delegate?.manager(self, didFailWith: error)
                        }
                    } else {
                        self.delegate?.manager(self, didFailWith: response.result.error!)
                    }
            }
    }

    func requestYoubikeRoute(originLatitude: Double, originLongitude: Double, destinationLatitude: Double, destinationLongitude: Double, through startYoubikeStation: YoubikeStation, and endYoubikeStation: YoubikeStation, withRouteIndex index: Int) {

        let urlParams = [
            "origin": "\(originLatitude),\(originLongitude)",
            "mode": "walking",
            "key": Constant.googlePlacesAPIKey,
            "alternatives": "true",
            "destination": "\(destinationLatitude),\(destinationLongitude)",
            "waypoints": "via:\(startYoubikeStation.latitude),\(startYoubikeStation.longitude)|via:\(endYoubikeStation.latitude),\(endYoubikeStation.longitude)"
            ]

        Alamofire.request("https://maps.googleapis.com/maps/api/directions/json", method: .get, parameters: urlParams)
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
                        let root = try JSONDecoder().decode(Root.self, from: data)
                        let youbikeRoutes = root.routes
                        self.youbikeDelegate?.youbikeManager(self, didGet: youbikeRoutes, atRouteIndex: index)
                    } catch let error {
                        self.youbikeDelegate?.youbikeManager(self, didFailWith: error)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.youbikeDelegate?.youbikeManager(self, didFailWith: response.result.error!)
                    }
                }
        }
    }

    func requestBusStopInfo(inCity city: String, ofRouteName routeName: String) {
        let dateFormater = DateFormatter()
        dateFormater.dateFormat = "EE, dd MMM YYYY HH:mm:ss zzz"
        dateFormater.timeZone = TimeZone(identifier: Constant.Identifier.gmt)
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

        let urlString = "http://ptx.transportdata.tw/MOTC/v2/Bus/StopOfRoute/City/\(city)/\(routeName)"

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

    func requestBusStatus(inCity city: String, ofRouteName routeName: String) {

        let dateFormater = DateFormatter()
        dateFormater.dateFormat = "EE, dd MMM YYYY HH:mm:ss zzz"
        dateFormater.timeZone = TimeZone(identifier: Constant.Identifier.gmt)
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

        let urlString = "http://ptx.transportdata.tw/MOTC/v2/Bus/EstimatedTimeOfArrival/City/\(city)/\(routeName)"

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
