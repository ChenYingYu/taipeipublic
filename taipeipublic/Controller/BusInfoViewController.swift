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
    var busName = Constant.DefaultValue.emptyString
    var departureStopName = Constant.DefaultValue.emptyString
    var arrivalStopName = Constant.DefaultValue.emptyString
    var busStatus = [BusStatus]()
    var busInfoUpdateCounter = 20
    var timer = Timer()
    let spinner = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))

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
        busNumberLabel.text = busName
        titleView.addGradient()
        busStopInfoTableView.delegate = self
        busStopInfoTableView.dataSource = self
        let nib = UINib(nibName: "BusStopInfoTableViewCell", bundle: nil)
        busStopInfoTableView.register(nib, forCellReuseIdentifier: Constant.Identifier.cell)
        let manager = RouteManager()
        manager.busDelegate = self
        manager.busStatusDelegate = self
        manager.requestBusStopInfo(inCity: Constant.City.taipei, ofRouteName: busName)
        manager.requestBusStopInfo(inCity: Constant.City.newTaipei, ofRouteName: busName)
        manager.requestBusStatus(inCity: Constant.City.taipei, ofRouteName: busName)
        manager.requestBusStatus(inCity: Constant.City.newTaipei, ofRouteName: busName)
        runSpinner(spinner, in: self.view)
    }

    override func viewWillDisappear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .default
        timer.invalidate()
    }

    func runTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
    }

    @objc func updateTime() {
        countdownLabel.text = "\(busInfoUpdateCounter) 秒後更新"
        if busInfoUpdateCounter == 0 {
            busInfoUpdateCounter = 20
            let manager = RouteManager()
            manager.busDelegate = self
            manager.busStatusDelegate = self
            manager.requestBusStatus(inCity: Constant.City.taipei, ofRouteName: busName)
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
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Constant.Identifier.cell) as? BusStopInfoTableViewCell else {
            return UITableViewCell()
        }
        cell.isUserInteractionEnabled = false
        cell.reset()
        let index = directionSegmentedControl.selectedSegmentIndex
        if busRoutes.count > index, busRoutes[index].stops.count > indexPath.row {
            cell.stopNameLabel.text = busRoutes[index].stops[indexPath.row].name.tw
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

    func busInfoNotFoundAlert() {
        showAlert(title: Constant.AlertMessage.dataNotFound, message: Constant.AlertMessage.busInfoNotFound)
    }
}

extension BusInfoViewController: BusRouteManagerDelegate {
    func busManager(_ manager: RouteManager, didGet routes: [BusRoute]) {
        if routes.count != 0 {
            self.busRoutes = routes
            self.busStopInfoTableView.reloadData()
            runTimer()
            return
        }
    }

    func busManager(_ manager: RouteManager, didFailWith error: Error) {
        print(error)
    }
}

extension BusInfoViewController: BusStatusManagerDelegate {
    func busStatusManager(_ manager: RouteManager, didGet status: [BusStatus]) {
        if status.count != 0 {
            self.busStatus = status
            self.busStopInfoTableView.reloadData()
        }
        spinner.stopAnimating()
    }

    func busStatusManager(_ manager: RouteManager, didFailWith error: Error) {
        print(error)
        spinner.stopAnimating()
    }
}

extension UIViewController {
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: Constant.AlertMessage.okTitle, style: .default)
        alertController.addAction(okAction)

        self.present(alertController, animated: true)
    }
}
