//
//  EnumerationTableCell.swift
//  Cookbook
//
//  Created by David Klopp on 22.03.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation
import UIKit

/**
 This class implements a tableView cell with no selection highlight and some
 additional properties.
 */
class EnumerationCell: UITableViewCell {
    static let identifier = "EnumerationCell"

    var textChanged: ((String) -> Void)?

    var deleteAccessoryAction: (() -> Void)?

    lazy var textView: UITextView = {
        let textView = UITextView(frame: .zero)
        textView.font = .systemFont(ofSize: UIFont.labelFontSize)
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.dataDetectorTypes = .link
        return textView
    }()

    lazy var detailLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .systemFont(ofSize: UIFont.labelFontSize, weight: .semibold)
        label.backgroundColor = .clear
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)

        self.selectionStyle = .none
        self.backgroundColor = .clear
        self.contentView.backgroundColor = .clear

        self.contentView.addSubview(self.detailLabel)
        self.contentView.addSubview(self.textView)

        // Add a delete button to the right side of the view in edit mode.
        let image = UIImage(systemName: "trash")!
        let deleteButton = UIButton(frame: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        deleteButton.setImage(image, for: .normal)
        deleteButton.addTarget(self, action: #selector(self.deleteAccessoryTapped), for: .touchUpInside)

        if #available(iOS 13.4, *) {
            let pointerInteraction = UIPointerInteraction(delegate: self)
            deleteButton.addInteraction(pointerInteraction)
        }

        self.editingAccessoryView = deleteButton

        // Add the textView.
        self.textView.delegate = self

        self.textView.translatesAutoresizingMaskIntoConstraints = false
        let leadingConstraint = NSLayoutConstraint(item: self.textView, attribute: .leading, relatedBy: .equal,
                                                   toItem: self.detailLabel, attribute: .trailing, multiplier: 1,
                                                   constant: 5)
        let trailingConstraint = NSLayoutConstraint(item: self.textView, attribute: .trailing, relatedBy: .equal,
                                                    toItem: self.contentView, attribute: .trailing, multiplier: 1,
                                                    constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: self.textView, attribute: .bottom, relatedBy: .equal,
                                                  toItem: self.contentView, attribute: .bottom, multiplier: 1,
                                                  constant: 0)
        let topConstraint = NSLayoutConstraint(item: self.textView, attribute: .top, relatedBy: .equal,
                                               toItem: self.contentView, attribute: .top, multiplier: 1, constant: 0)
        self.contentView.addConstraints([leadingConstraint, trailingConstraint, bottomConstraint, topConstraint])
    }

    override open func layoutSubviews() {
        super.layoutSubviews()

        self.detailLabel.sizeToFit()
        var frame = self.detailLabel.frame
        frame.size.width = self.detailLabel.frame.width
        frame.origin.x = self.separatorInset.left
        frame.origin.y = self.textView.textContainerInset.top
        self.detailLabel.frame = frame
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func deleteAccessoryTapped(sender: Any) {
        self.deleteAccessoryAction?()
    }
}

// MARK: - TextView delegate
extension EnumerationCell: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        self.textChanged?(textView.attributedText.string)
    }
}

extension EnumerationCell: UIPointerInteractionDelegate {
    @available(iOS 13.4, *)
    func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
        var pointerStyle: UIPointerStyle?

        guard self.isEditing else { return nil }

        // Add a custom highlight to the edit accessory view.
        if let trashButton = interaction.view {
            let targetedPreview = UITargetedPreview(view: trashButton)
            let pointerRect = CGRect(rect: trashButton.frame, padding: 5)
            let pointerShape: UIPointerShape = .roundedRect(pointerRect)
            pointerStyle = UIPointerStyle.init(effect: .highlight(targetedPreview), shape: pointerShape)
        }
        return pointerStyle
    }
}
