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
//        let urlString = "https://maps.googleapis.com/maps/api/directions/json"
//        let headers: HTTPHeaders = [
//            "Content-Type": "application/json"
//            ]
//        let parameters: Parameters = [
//            "origin": "\(originLatitude),\(originLongitude)", "destination": "place_id:\(destinationId)", "mode": "transit", "key": Constant.googlePlacesAPIKey, "alternatives": "true"
//        ]

        Alamofire.request(urlString).validate().responseJSON { response in
            switch response.result {
            case .success:
                print("=============")
                print(response)
                print("=============")
            case .failure(let error):
                print(error)
            }
        }
    }
}
