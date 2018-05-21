//
//  RouteTableViewCell.swift
//  taipeipublic
//
//  Created by ChenAlan on 2018/5/15.
//  Copyright © 2018年 ChenAlan. All rights reserved.
//

import UIKit

class RouteTableViewCell: UITableViewCell {

    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var youbikeLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        youbikeLabel.isHidden = true
    }
}
