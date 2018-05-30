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
    var busNumber = ""

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var busNumberLabel: UILabel!
    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    @IBOutlet weak var busStopInfoTableView: UITableView!
    @IBOutlet weak var titleView: UIView!
    @IBOutlet weak var directionSegmentedControl: UISegmentedControl!
    @IBAction func directionChange(_ sender: UISegmentedControl) {
        busStopInfoTableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        backButton.tintColor = UIColor.white
        busNumberLabel.text = busNumber
        titleView.addGradient()
        busStopInfoTableView.delegate = self
        busStopInfoTableView.dataSource = self
        let nib = UINib(nibName: "BusStopInfoTableViewCell", bundle: nil)
        busStopInfoTableView.register(nib, forCellReuseIdentifier: "Cell")
        let manager = RouteManager()
        manager.busDelegate = self
        manager.requestBusStopInfo(ofRouteName: busNumber)
    }
}

extension BusInfoViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let index = directionSegmentedControl.selectedSegmentIndex
        if busRoutes.count > index {
            return busRoutes[index].stops.count
        }
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as? BusStopInfoTableViewCell else {
            return UITableViewCell()
        }
        let index = directionSegmentedControl.selectedSegmentIndex
        if busRoutes.count > index, busRoutes[index].stops.count > indexPath.row {
            cell.stopNameLabel.text = busRoutes[index].stops[indexPath.row].name.tw
        }
        return cell
    }
}

extension BusInfoViewController: BusRouteManagerDelegate {
    func busManager(_ manager: RouteManager, didGet routes: [BusRoute]) {
        self.busRoutes = routes
        self.busStopInfoTableView.reloadData()
    }

    func busManager(_ manager: RouteManager, didFailWith error: Error) {
        print(error)
    }
}
