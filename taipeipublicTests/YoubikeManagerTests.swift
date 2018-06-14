//
//  YoubikeManagerTests.swift
//  taipeipublicTests
//
//  Created by ChenAlan on 2018/6/14.
//  Copyright © 2018年 ChenAlan. All rights reserved.
//

import XCTest
@testable import taipeipublic
import GoogleMaps

class YoubikeManagerTests: XCTestCase {
    var youbikeManagerTest: YoubikeManager!

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        youbikeManagerTest = YoubikeManager.getStationInfo()
    }

    override func tearDown() {
        youbikeManagerTest = nil
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func test_GetYoubikeLocation_isAccurateLocation() {
        // 1. given
        let position = CLLocationCoordinate2D(latitude: 25.024855, longitude: 121.510975)

        // 2. when
        guard let station = youbikeManagerTest.checkNearbyStation(position: position) else {
            return
        }

        // 3. then
        XCTAssertEqual(station, YoubikeStation(name: "古亭國中", latitude: "25.024487", longitude: "121.510570"), "Complete")
    }
}

extension YoubikeStation: Equatable {
    public static func == (lhs: YoubikeStation, rhs: YoubikeStation) -> Bool {
        return
            lhs.name == rhs.name &&
                lhs.latitude == rhs.latitude &&
                lhs.longitude == rhs.longitude
    }
}
