//
//  Route.swift
//  taipeipublic
//
//  Created by ChenAlan on 2018/5/2.
//  Copyright © 2018年 ChenAlan. All rights reserved.
//

import Foundation

struct Route {
    let bounds: Bounds?
    let legs: Legs?
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
    let arrivalTime: String?
    let departureTime: String?
    let distance: String?
    let duration: String?
    let endAddress: String
    let endLocation: Location
    let startAddress: String
    let startLocation: Location
    let steps: [Step]
    let points: String
}

struct Step {
    let distance: String
    let duration: String
    let endLocation: Location
    let instructions: String
    let startLocation: Location
    let polyline: String
    let walkingDetail: [Step]?
    let transitDetail: [Transit]?
    let travelMode: String
}

struct Travel {
    let walking: String
    let transit: String
    enum Mode: String {
        case walking = "WALKING"
        case transit = "TRANSIT"
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
