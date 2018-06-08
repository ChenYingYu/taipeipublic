//
//  Constant.swift
//  taipeipublic
//
//  Created by ChenAlan on 2018/4/30.
//  Copyright © 2018年 ChenAlan. All rights reserved.
//

import Foundation

struct Constant {
    static let googleMapsAPIKey = "AIzaSyAGVKnhXAE-eiDJuTK3i-91rSnpngQAkHI"
    static let googlePlacesAPIKey = "AIzaSyC07iM6JrYRi4fvQVybWRLYQthE1f7ITf8"
    static let PTXAppID = "6682cd802e7f48cb903f21ed478943e1"
    static let PTXAppKey = "-Fjkt5T-AtetVWGUIC6F1ZSngmI"

    struct DefaultValue {
        static let emptyString = ""
        static let zero = 0
    }

    struct Identifier {
        static let routeTableViewCell = "RouteTableViewCell"
        static let cell = "Cell"
        static let gmt = "GMT"
        static let busInfoViewController = "BusInfoViewController"
        static let routeViewController = "RouteViewController"
    }

    struct Icon {
        static let location = "icon_location"
        static let bicycle = "icon_bicycle"
    }

    struct Polyline {
        static let width = 6.0
    }

    struct TravelMode {
        static let transit = "TRANSIT"
    }

    struct Vehicle {
        static let bus = "BUS"
    }

    struct BusInfoKey {
        static let busName = "name"
        static let departureStop = "departure"
        static let arrivalStop = "arrival"
    }

    struct Storyboard {
        static let main = "Main"
    }

    struct ErrorMessage {
        static let errorPrefix = "Error: "
        static let userLocationNotFound = "Cannot find user's location"
    }

    struct TransitMessage {
        static let take = "搭乘 ["
        static let from = "] 從 ["
        static let to = "] 到 ["
    }
}
