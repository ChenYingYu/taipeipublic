//
//  Route.swift
//  taipeipublic
//
//  Created by ChenAlan on 2018/5/2.
//  Copyright © 2018年 ChenAlan. All rights reserved.
//

import Foundation

struct Root: Codable {
    let waypoints: [Waypoints]
    let routes: [Route]

    enum CodingKeys: String, CodingKey {
        case waypoints = "geocoded_waypoints"
        case routes
    }
}

struct Waypoints: Codable {
    let coderStatus: String
    let placeId: String
    let types: [String]

    enum CodingKeys: String, CodingKey {
        case coderStatus = "geocoder_status"
        case placeId = "place_id"
        case types = "types"
    }
}

struct Route: Codable {
    let bounds: Bounds?
    let legs: [Legs]?
    let polyline: Polyline

    enum CodingKeys: String, CodingKey {
        case bounds
        case legs
        case polyline = "overview_polyline"
    }
}

struct Bounds: Codable {
    let northeast: Location
    let southwest: Location

    enum CodingKeys: String, CodingKey {
        case northeast
        case southwest
    }
}

struct Location: Codable {
    let lat: Double
    let lng: Double

    enum CodingKeys: String, CodingKey {
        case lat
        case lng
    }
}

struct Legs: Codable {
    let arrivalTime: Time?
    let departureTime: Time?
    let distance: Distance?
    let duration: Duration?
    let endAddress: String
    let endLocation: Location
    let startAddress: String
    let startLocation: Location
    let steps: [Step]

    enum CodingKeys: String, CodingKey {
        case arrivalTime = "arrival_time"
        case departureTime = "departure_time"
        case distance
        case duration
        case endAddress = "end_address"
        case endLocation = "end_location"
        case startAddress = "start_address"
        case startLocation = "start_location"
        case steps
    }
}

struct Time: Codable {
    let timeText: String
    let timeZone: String
    let timeValue: Int

    enum CodingKeys: String, CodingKey {
        case timeText = "text"
        case timeZone = "time_zone"
        case timeValue = "value"
    }
}

struct Distance: Codable {
    let distanceText: String
    let distanceValue: Int

    enum CodingKeys: String, CodingKey {
        case distanceText = "text"
        case distanceValue = "value"
    }
}

struct Duration: Codable {
    let durationText: String
    let durationValue: Int

    enum CodingKeys: String, CodingKey {
        case durationText = "text"
        case durationValue = "value"
    }
}

struct Step: Codable {
    let distance: Distance
    let duration: Duration
    let endLocation: Location
    let instructions: String?
    let startLocation: Location
    let polyline: Polyline
    let walkingDetail: [Step]?
    let transitDetail: Transit?
    let travelMode: String

    enum CodingKeys: String, CodingKey {
        case distance
        case duration
        case endLocation = "end_location"
        case instructions = "html_instructions"
        case startLocation = "start_location"
        case polyline
        case walkingDetail = "steps"
        case transitDetail = "transit_details"
        case travelMode = "travel_mode"
    }
}

struct Polyline: Codable {
    let points: String

    enum CodingKeys: String, CodingKey {
        case points
    }
}

struct Travel {
    let walking: String
    let transit: String
    enum Mode: String {
        case walking = "WALKING"
        case transit = "TRANSIT"
    }
}

struct Transit: Codable {
    let arrivalStop: Stop
    let arrivalTime: Time
    let departureStop: Stop
    let departureTime: Time
    let lineDetails: Line
    let numberOfStops: Int

    enum CodingKeys: String, CodingKey {
        case arrivalStop = "arrival_stop"
        case arrivalTime = "arrival_time"
        case departureStop = "departure_stop"
        case departureTime = "departure_time"
        case lineDetails = "line"
        case numberOfStops = "num_stops"
    }
}

struct Stop: Codable {
    let location: Location
    let name: String

    enum CodingKeys: String, CodingKey {
        case location
        case name
    }
}

struct Line: Codable {
    let agencies: [Agency]
    let color: String?
    let name: String
    let shortName: String
    let textColor: String?
    let vehicle: Vehicle

    enum CodingKeys: String, CodingKey {
        case agencies
        case color
        case name
        case shortName = "short_name"
        case textColor = "text_color"
        case vehicle
    }
}

struct Agency: Codable {
    let name: String
    let agencyURL: String

    enum CodingKeys: String, CodingKey {
        case name
        case agencyURL = "url"
    }
}

struct Vehicle: Codable {
    let iconURL: String
    let localIconURL: String?
    let name: String
    let type: String

    enum CodingKeys: String, CodingKey {
        case iconURL = "icon"
        case localIconURL = "local_icon"
        case name
        case type
    }
}
