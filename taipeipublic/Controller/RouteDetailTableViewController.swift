//
//  RouteDetailTableViewController.swift
//  taipeipublic
//
//  Created by ChenAlan on 2018/6/8.
//  Copyright © 2018年 ChenAlan. All rights reserved.
//

import UIKit

class RouteDetailTableViewController: UITableViewController {

    var selectedRoute: Route?
    var transitTag = Constant.DefaultValue.zero
    var transitInfoDictionary = [Int: [String: String]]()

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return selectedRoute?.legs?[0].steps.count ?? 2
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Constant.Identifier.cell) as? RouteDetailTableViewCell else {
            return UITableViewCell()
        }
        cell.isUserInteractionEnabled = false
        if let legs = selectedRoute?.legs {
            let leg = legs[0]
            let step = leg.steps[indexPath.row]
            //顯示公車或捷運班次及起迄站
            if step.travelMode == Constant.TravelMode.transit, let transitDetail = step.transitDetail {
                let lineName = transitDetail.lineDetails.shortName
                let transitMessage = Constant.TransitMessage.take + lineName + Constant.TransitMessage.from + transitDetail.departureStop.name + Constant.TransitMessage.to + transitDetail.arrivalStop.name + "]"
                cell.routeDetailLabel.text = transitMessage
                transitTag += 1
                if transitDetail.lineDetails.vehicle.type == Constant.Vehicle.bus {
                    cell.busInfoButton.isHidden = false
                } else {
                    cell.busInfoButton.isHidden = true
                }
                cell.isUserInteractionEnabled = true
                cell.busInfoButton.tag = indexPath.row
                cell.busInfoButton.addTarget(self, action: #selector(showBusInfo), for: .touchUpInside)
                var dictionary = [String: String]()
                dictionary.updateValue(lineName, forKey: Constant.BusInfoKey.busName)
                dictionary.updateValue(transitDetail.departureStop.name, forKey: Constant.BusInfoKey.departureStop)
                dictionary.updateValue(transitDetail.arrivalStop.name, forKey: Constant.BusInfoKey.arrivalStop)
                transitInfoDictionary.updateValue(dictionary, forKey: indexPath.row)
            } else {
                cell.routeDetailLabel.text = selectedRoute?.legs?[0].steps[indexPath.row].instructions
            }
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Constant.Identifier.cell) as? RouteDetailTableViewCell else {
            return
        }
        cell.busInfoButton.isHidden = true
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }

    @objc func showBusInfo(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: Constant.Storyboard.main, bundle: nil)
        if let busInfoViewController = storyboard.instantiateViewController(withIdentifier: Constant.Identifier.busInfoViewController) as? BusInfoViewController {
            if let dictionary = transitInfoDictionary[sender.tag], let busName = dictionary[Constant.BusInfoKey.busName], let departure = dictionary[Constant.BusInfoKey.departureStop], let arrival = dictionary[Constant.BusInfoKey.arrivalStop] {
                busInfoViewController.busName = busName
                busInfoViewController.departureStopName = departure
                busInfoViewController.arrivalStopName = arrival
            }
            present(busInfoViewController, animated: true, completion: nil)
        }
    }
}
