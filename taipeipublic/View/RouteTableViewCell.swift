//
//  RouteTableViewCell.swift
//  taipeipublic
//
//  Created by ChenAlan on 2018/5/15.
//  Copyright © 2018年 ChenAlan. All rights reserved.
//

import UIKit

class RouteTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var youbikeLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)  
        // Configure the view for the selected state
    }
}
