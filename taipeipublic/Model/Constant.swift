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
    }

    struct Icon {
        static let location = "icon_location"
        static let bicycle = "icon_bicycle"
    }

    struct Polyline {
        static let width = 6.0
    }

    struct City {
        static let taipei = "Taipei"
        static let newTaipei = "NewTaipei"
    }
}
