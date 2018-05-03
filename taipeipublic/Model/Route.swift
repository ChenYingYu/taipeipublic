//
//  Route.swift
//  taipeipublic
//
//  Created by ChenAlan on 2018/5/2.
//  Copyright © 2018年 ChenAlan. All rights reserved.
//

import Foundation

struct Route {
    let bounds: Bounds
    let legs: Legs
}

struct Bounds {
    let northeast: Location
    let southwest: Location
}

struct Location {
    let lat: Double
    let lng: Double
}

struct Legs {
    let arrivalTime: String
    let depatureTime: String
    let distance: String
    let duration: String
    let endAddress: String
    let endLocation: String
    let startAddress: String
    let startLocation: String
    let steps: [Step]
    let travelMode: Travel.Mode
}

struct Step {
    let distance: String
    let duration: String
    let endLocation: Location
    let instrction: String
    let startLocation: Location
    let polyline: String
    let walkingDetail: [Step]
    let transitDetail: [Transit]
    let travelMode: Travel.Mode
}

struct Travel {
    let walking: String
    let transit: String
    enum Mode: String {
        case walking = "Walking"
        case transit = "Transit"
    }
}

struct Transit {
    let arrivalStop: Stop
    let arrivalTime: String
    let departureStrop: Stop
    let departureTime: String
    let line: Line
}

struct Stop {
    let location: Location
    let name: String
}

struct Line {
    let color: String
    let name: String
    let textColor: String
    let icon: String
}
