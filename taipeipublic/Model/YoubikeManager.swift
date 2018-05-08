//
//  YoubikeManager.swift
//  taipeipublic
//
//  Created by ChenAlan on 2018/5/8.
//  Copyright © 2018年 ChenAlan. All rights reserved.
//

import Foundation

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
            print("=======Test Youbike======")
            print(error)
            print("=======Test Youbike======")
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
}

struct YoubikeMarker {
    
}
