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

    struct AlertMessage {
        static let dataNotFound = "找不到資料"
        static let busInfoNotFound = "抱歉，未找到該班公車的詳細資訊\n請將螢幕截圖並寄至\n\"alan831007@gmail.com\"\n我們會盡快找出原因並處理"
        static let okTitle = "好的"
    }
}
