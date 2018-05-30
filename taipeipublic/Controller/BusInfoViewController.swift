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
    var departureStopName = ""
    var arrivalStopName = ""

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

        UIApplication.shared.statusBarStyle = .lightContent
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

    override func viewWillDisappear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .default
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
        cell.isUserInteractionEnabled = false
        let index = directionSegmentedControl.selectedSegmentIndex
        if busRoutes.count > index, busRoutes[index].stops.count > indexPath.row {
            cell.stopNameLabel.text = busRoutes[index].stops[indexPath.row].name.tw
            if cell.stopNameLabel.text == departureStopName {
                cell.departureOrArrivalTagLabel.text = "~搭車起點~"
                cell.departureOrArrivalTagLabel.backgroundColor = cell.departureColor
                cell.departureOrArrivalTagLabel.isHidden = false
            } else if cell.stopNameLabel.text == arrivalStopName {
                cell.departureOrArrivalTagLabel.text = "~搭車終點~"
                cell.departureOrArrivalTagLabel.backgroundColor = cell.arrivalColor
                cell.departureOrArrivalTagLabel.isHidden = false
            } else {
                cell.departureOrArrivalTagLabel.isHidden = true
            }
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
