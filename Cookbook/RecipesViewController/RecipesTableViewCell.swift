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
    /// Recipe imageView.
    @IBOutlet var thumbnail: UIImageView!

    /// Textlabel.
    @IBOutlet var label: UILabel!

    /// Custom line separator.
    @IBOutlet var lineSeparator: UIView!

    /// Possible active download request to update the `imageView.image` property.
    var imageLoadingRequestReceipt: RequestReceipt?

    /// Hide / show the line separator.
    var showLineSeparator: Bool = true

    /// Color when the cell is selected.
    var selectedColor: UIColor? {
        get {
            return self.selectedBackgroundView?.backgroundColor
        }
        set(color) {
            self.selectedBackgroundView?.backgroundColor = color
        }
    }

    // MARK: - Constructor

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
        //self.selectionStyle = .none
        let bgView = UIView()
        bgView.backgroundColor = .clear
        self.selectedBackgroundView = bgView
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.label.text = nil
        self.thumbnail.image = #imageLiteral(resourceName: "placeholder_thumb").af_imageRounded(withCornerRadius: 5)
        self.selectionStyle = .blue
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.lineSeparator.isHidden = !self.showLineSeparator || selected
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        self.lineSeparator.isHidden = !self.showLineSeparator || highlighted
    }
}
