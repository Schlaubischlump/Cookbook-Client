//
//  RecipesTableViewCell.swift
//  Cookbook
//
//  Created by David Klopp on 20.03.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation
import UIKit
import AlamofireImage

class RecipesTableViewCell: UITableViewCell {
    var imageLoadingRequestReceipt: RequestReceipt?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }

    func setup() {
        self.imageView?.image = #imageLiteral(resourceName: "placeholder_thumb")
    }
}
