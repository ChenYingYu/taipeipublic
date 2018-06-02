//
//  BusStopInfoTableViewCell.swift
//  taipeipublic
//
//  Created by ChenAlan on 2018/5/30.
//  Copyright © 2018年 ChenAlan. All rights reserved.
//

import UIKit

class BusStopInfoTableViewCell: UITableViewCell {

    @IBOutlet weak var stopNameLabel: UILabel!
    @IBOutlet weak var departureOrArrivalTagLabel: UILabel!
    @IBOutlet weak var estimateTimeLabel: UILabel!
    @IBOutlet weak var tagImage: UIImageView!

    let departureColor = UIColor(red: 10.0/255.0, green: 140.0/255.0, blue: 204.0/255.0, alpha: 1.0)
    let arrivalColor = UIColor(red: 4.0/255.0, green: 52.0/255.0, blue: 76.0/255.0, alpha: 1.0)
    let originalTagColor = UIColor.white
    let comingTagColor = UIColor(red: 10.0/255.0, green: 140.0/255.0, blue: 204.0/255.0, alpha: 1.0)
    let arrivingTagColor = UIColor(red: 178.0/255.0, green: 0.0/255.0, blue: 19.0/255.0, alpha: 1.0)

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        departureOrArrivalTagLabel.isHidden = true
    }

    func reset() {
        tagImage.tintColor = originalTagColor
        estimateTimeLabel.text = "3 分"
        estimateTimeLabel.textColor = originalTagColor
    }
}
