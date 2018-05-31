//
//  BusInfo.swift
//  taipeipublic
//
//  Created by ChenAlan on 2018/5/21.
//  Copyright © 2018年 ChenAlan. All rights reserved.
//

import Foundation

struct BusManager: Codable {
    let routes: [BusRoute]
    enum CodingKeys: String, CodingKey {
        case routes
    }
}

struct BusRoute: Codable {
    let uId: String
    let id: String
    let name: StopName
    let subRouteUId: String
    let subRouteId: String
    let subRouteName: RouteName
    let direction: Int
    let city: String
    let cityCode: String
    let updateTime: String
    let version: Int
    let stops: [BusStop]

    enum CodingKeys: String, CodingKey {
        case uId = "RouteUID"
        case id = "RouteID"
        case name = "RouteName"
        case subRouteUId = "SubRouteUID"
        case subRouteId = "SubRouteID"
        case subRouteName = "SubRouteName"
        case direction = "Direction"
        case city = "City"
        case cityCode = "CityCode"
        case updateTime = "UpdateTime"
        case version = "VersionID"
        case stops = "Stops"
    }
}

struct BusStop: Codable {
    let uId: String
    let id: String
    let name: StopName
    let boarding: Int
    let sequence: Int
    let position: Position
    let stationId: String
    let cityCode: String

    enum CodingKeys: String, CodingKey {
        case uId = "StopUID"
        case id = "StopID"
        case name = "StopName"
        case boarding = "StopBoarding"
        case sequence = "StopSequence"
        case position = "StopPosition"
        case stationId = "StationID"
        case cityCode = "LocationCityCode"
    }
}

struct StopName: Codable {
    let tw: String
    let en: String
    enum CodingKeys: String, CodingKey {
        case tw = "Zh_tw"
        case en = "En"
    }
}

struct RouteName: Codable {
    let tw: String
    let en: String
    enum CodingKeys: String, CodingKey {
        case tw = "Zh_tw"
        case en = "En"
    }
}

struct Position: Codable {
    let latitude: Double
    let longitude: Double
    enum CodingKeys: String, CodingKey {
        case latitude = "PositionLat"
        case longitude = "PositionLon"
    }
}

struct BusStatus: Codable {
    let uId: String
    let id: String
    let name: StopName
    let routeUID: String
    let routeID: String
    let routeName: RouteName
    let direction: Int
    let estimateTime: Int?
    let updateTime: String

    enum CodingKeys: String, CodingKey {
        case uId = "StopUID"
        case id = "StopID"
        case name = "StopName"
        case routeUID = "RouteUID"
        case routeID = "RouteID"
        case routeName = "RouteName"
        case direction = "Direction"
        case estimateTime = "EstimateTime"
        case updateTime = "UpdateTime"
    }
}
