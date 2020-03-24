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
    /// Possible active download request to update the `imageView.image` property.
    var imageLoadingRequestReceipt: RequestReceipt?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }

    /**
     Perform the basic cell setup operations.
     */
    func setup() {
        self.imageView?.image = #imageLiteral(resourceName: "placeholder_thumb")
        self.selectionStyle = .blue
    }
}
