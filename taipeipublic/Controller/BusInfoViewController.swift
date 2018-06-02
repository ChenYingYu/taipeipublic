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
    var busStatus = [BusStatus]()
    var busInfoUpdateCounter = 20

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
    @IBOutlet weak var countdownLabel: UILabel!

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
        manager.busStatusDelegate = self
        manager.requestBusStopInfo(ofRouteName: busNumber)
        manager.requestBusStatus(ofRouteName: busNumber)
        runTimer()
    }

    override func viewWillDisappear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .default
    }

    func runTimer() {
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
    }

    @objc func updateTime() {
        countdownLabel.text = "\(busInfoUpdateCounter) 秒後更新"
        if busInfoUpdateCounter == 0 {
            busInfoUpdateCounter = 20
            let manager = RouteManager()
            manager.busDelegate = self
            manager.busStatusDelegate = self
            manager.requestBusStatus(ofRouteName: busNumber)
        } else {
            busInfoUpdateCounter -= 1
        }
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
        cell.reset()
        let index = directionSegmentedControl.selectedSegmentIndex
        if busRoutes.count > index, busRoutes[index].stops.count > indexPath.row {
            cell.stopNameLabel.text = busRoutes[index].stops[indexPath.row].name.tw
//            if cell.stopNameLabel.text == departureStopName {
//                cell.departureOrArrivalTagLabel.text = "本站上車"
//                cell.departureOrArrivalTagLabel.backgroundColor = cell.departureColor
//                cell.departureOrArrivalTagLabel.isHidden = false
//            } else if cell.stopNameLabel.text == arrivalStopName {
//                cell.departureOrArrivalTagLabel.text = "本站下車"
//                cell.departureOrArrivalTagLabel.backgroundColor = cell.arrivalColor
//                cell.departureOrArrivalTagLabel.isHidden = false
//            } else {
//                cell.departureOrArrivalTagLabel.isHidden = true
//            }
            for status in busStatus where status.direction == index && cell.stopNameLabel.text == status.name.tw {
                if let estimateTime = status.estimateTime {
                    switch estimateTime / 60 {
                    case let time where time < 2:
                        cell.estimateTimeLabel.text = "將到站"
                        cell.estimateTimeLabel.textColor = cell.comingTagColor
                        cell.tagImage.tintColor = cell.comingTagColor
                    default:
                        cell.tagImage.tintColor = cell.originalTagColor
                        cell.estimateTimeLabel.text = String(estimateTime/60) + " 分"
                    }
                } else {
                    cell.estimateTimeLabel.text = "未發車"
                }
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

extension BusInfoViewController: BusStatusManagerDelegate {
    func busStatusManager(_ manager: RouteManager, didGet status: [BusStatus]) {
        self.busStatus = status
        self.busStopInfoTableView.reloadData()
    }

    func busStatusManager(_ manager: RouteManager, didFailWith error: Error) {
        print(error)
    }
}
