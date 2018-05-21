//
//  RouteDetailTableViewCell.swift
//  taipeipublic
//
//  Created by ChenAlan on 2018/5/18.
//  Copyright © 2018年 ChenAlan. All rights reserved.
//

import UIKit

class RouteDetailTableViewCell: UITableViewCell {

    @IBOutlet weak var routeDetailLabel: UILabel!
    @IBOutlet weak var busInfoButton: UIButton!
    @IBAction func busInfoButtonPress(_ sender: UIButton) {
        busInfoButton.setTitleColor(UIColor.white, for: .normal)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        setUpBusInfoButton()
    }

    func setUpBusInfoButton() {
        busInfoButton.layer.cornerRadius = busInfoButton.bounds.height / 2
        busInfoButton.layer.borderColor = busInfoButton.currentTitleColor.cgColor
        busInfoButton.layer.borderWidth = 2.0
        busInfoButton.isHidden = true
    }
}
