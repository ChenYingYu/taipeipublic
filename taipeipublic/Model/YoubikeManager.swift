//
//  YoubikeManager.swift
//  taipeipublic
//
//  Created by ChenAlan on 2018/5/8.
//  Copyright © 2018年 ChenAlan. All rights reserved.
//

import Foundation
import GoogleMaps

struct YoubikeStation: Codable {

    let name: String
    let latitude: String
    let longitude: String
    enum CodingKeys: String, CodingKey {
        case name = "sna"
        case longitude = "lng"
        case latitude = "lat"
    }
}

struct YoubikeManager: Codable {

    var stations: [YoubikeStation]
    enum CodingKeys: String, CodingKey {
        case stations = "stations"
    }

    static func getStationInfo() -> YoubikeManager? {

        guard let path = Bundle.main.path(forResource: "YouBikeStations", ofType: "json") else {
            return nil
        }

        let url = URL(fileURLWithPath: path)
        do {
            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            let youbikeManager = try JSONDecoder().decode(YoubikeManager.self, from: data)
            return youbikeManager
        } catch let error {
            print(error)
            return nil
        }
    }

    func getYoubikeLocation() -> [YoubikeStation]? {

        guard let manager = YoubikeManager.getStationInfo(), manager.stations.count > 0 else {
            return nil
        }

        var stations = [YoubikeStation]()
        for station in manager.stations {
            stations.append(station)
        }
        return stations
    }

    func checkNearbyStation(position: CLLocationCoordinate2D) -> [YoubikeStation] {

        var nearbyStations = [YoubikeStation]()
        if let youbikeManager = YoubikeManager.getStationInfo(), let stations = youbikeManager.getYoubikeLocation() {
            for index in stations.indices {
                if let latitude = Double(stations[index].latitude), let longitude = Double(stations[index].longitude) {
                    //尋找附近 300 公尺內 Youbike 站點
                    if self.getdistance(lng1: position.longitude, lat1: position.latitude, lng2: Double(longitude), lat2: Double(latitude)) < 300.0 {
                        nearbyStations.append(stations[index])
                    }
                } else {
                    print("===============")
                    print("ERROR Number: \(index)")
                    print("ERROR Latitude: \(stations[index].latitude)")
                    print("ERROR Longitude: \(stations[index].longitude)")
                    print("===============")
                }
            }
        }
        return nearbyStations
    }

    func getdistance(lng1: Double, lat1: Double, lng2: Double, lat2: Double) -> Double {
        //將角度轉為弧度
        let radLat1 = lat1 * Double.pi / 180
        let radLat2 = lat2 * Double.pi / 180
        let radLng1 = lng1 * Double.pi / 180
        let radLng2 = lng2 * Double.pi / 180
        let tmp1 = radLat1 - radLat2
        let tmp2 = radLng1 - radLng2
        //計算公式
        let distance = 2 * asin(sqrt(pow(sin(tmp1 / 2), 2)+cos(radLat1) * cos(radLat2) * pow(sin(tmp2 / 2), 2))) * 6378.137 * 1000
        //單位公尺
        return distance
    }
}
