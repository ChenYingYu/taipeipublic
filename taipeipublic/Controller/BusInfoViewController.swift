//
//  BusInfoViewController.swift
//  taipeipublic
//
//  Created by ChenAlan on 2018/5/21.
//  Copyright © 2018年 ChenAlan. All rights reserved.
//

import UIKit

class BusInfoViewController: UIViewController {

    var busRoutes = [BusRoute]()

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var busNumberLabel: UILabel!
    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    @IBOutlet weak var busInfoTableView: UITableView!

    var busNumber = ""
    override func viewDidLoad() {
        super.viewDidLoad()

        backButton.tintColor = UIColor.white
        busNumberLabel.text = busNumber
        busInfoTableView.delegate = self
        busInfoTableView.dataSource = self
        let manager = RouteManager()
        manager.busDelegate = self
        manager.requestBusStopInfo(ofRouteName: busNumber)
    }
}

extension BusInfoViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 40
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        if busRoutes.count > 0, busRoutes[0].stops.count > indexPath.row {
            cell.textLabel?.text = busRoutes[0].stops[indexPath.row].name.tw
            cell.backgroundColor = .white
        }
        return cell
    }
}

extension BusInfoViewController: BusRouteManagerDelegate {
    func busManager(_ manager: RouteManager, didGet routes: [BusRoute]) {
        self.busRoutes = routes
        self.busInfoTableView.reloadData()
    }

    func busManager(_ manager: RouteManager, didFailWith error: Error) {
        print(error)
    }
}
