//
//  DestinationInfoView.swift
//  taipeipublic
//
//  Created by ChenAlan on 2018/6/7.
//  Copyright © 2018年 ChenAlan. All rights reserved.
//

import UIKit

class DestinationInfoView: UIView {

    var view = UIView()

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var showRouteButton: UIButton!

    override init(frame: CGRect) {
        super.init(frame: frame)

        setUp()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setUp()
    }

    private func setUp() {
        guard let view = Bundle.main.loadNibNamed("DestinationInfoView", owner: self, options: nil)?.first as? UIView else {
            return
        }
        view.frame = self.bounds
        view.translatesAutoresizingMaskIntoConstraints = true
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addSubview(view)
        self.view = view
    }
}
