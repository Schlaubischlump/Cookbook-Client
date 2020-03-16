//
//  EnumerationCell.swift
//  Cookbook
//
//  Created by David Klopp on 23.12.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//

import Foundation
import UIKit

/**
 The enumeration style to use inside for the EnumerationList class.
 */
enum EnumerationType {
    /// Lorem ipsum dolor sit amet
    case none
    /// **1.** Lorem ipsum dolor sit amet
    case number
    /// **•** Lorem ipsum dolor sit amet
    case bullet(_ char: Character = "•")
    /// **Description:** Lorem ipsum dolor sit amet
    case string(_ keys: [String])
}

/**
 This class implements a tableView cell with no selection highlight and some
 additional properties.
 */
open class EnumerationCell: UITableViewCell {
    static let identifier = "EnumerationCell"

    fileprivate var referencedURL: URL?

    lazy var textView: UITextView = {
        let textView = UITextView(frame: .zero)
        textView.font = .systemFont(ofSize: UIFont.labelFontSize)
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
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

        self.textView.translatesAutoresizingMaskIntoConstraints = false
        let leadingConstraint = NSLayoutConstraint(item: self.textView,
                                                   attribute: NSLayoutConstraint.Attribute.leading,
                                                   relatedBy: NSLayoutConstraint.Relation.equal,
                                                   toItem: self.detailLabel,
                                                   attribute: NSLayoutConstraint.Attribute.trailing,
                                                   multiplier: 1,
                                                   constant: 5)
        let trailingConstraint = NSLayoutConstraint(item: self.textView,
                                                    attribute: NSLayoutConstraint.Attribute.trailing,
                                                    relatedBy: NSLayoutConstraint.Relation.equal,
                                                    toItem: self.contentView,
                                                    attribute: NSLayoutConstraint.Attribute.trailing,
                                                    multiplier: 1,
                                                    constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: self.textView,
                                                  attribute: NSLayoutConstraint.Attribute.bottom,
                                                  relatedBy: NSLayoutConstraint.Relation.equal,
                                                  toItem: self.contentView,
                                                  attribute: NSLayoutConstraint.Attribute.bottom,
                                                  multiplier: 1,
                                                  constant: 0)
        let topConstraint = NSLayoutConstraint(item: self.textView,
                                               attribute: NSLayoutConstraint.Attribute.top,
                                               relatedBy: NSLayoutConstraint.Relation.equal,
                                               toItem: self.contentView,
                                               attribute: NSLayoutConstraint.Attribute.top,
                                               multiplier: 1,
                                               constant: 0)

        self.contentView.addConstraints([leadingConstraint, trailingConstraint, bottomConstraint, topConstraint])
    }

    override open func layoutSubviews() {
        super.layoutSubviews()

        //let width = self.contentView.frame.width

        self.detailLabel.sizeToFit()
        var frame = detailLabel.frame
        frame.size.width = self.detailLabel.frame.width //min(width*0.2, self.detailLabel.frame.width)
        frame.origin.x = self.separatorInset.left
        frame.origin.y = self.textView.textContainerInset.top
        self.detailLabel.frame = frame
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/**
 This class implements a simplified list with different styles.
 */
class EnumerationList: UITableView {
    /// Enumeration display style.
    var enumerationStyle: EnumerationType = .none

    /// List title.
    var title: String? = nil {
        didSet {
            self.reloadData()
        }
    }

    /// List data to display.
    var data: [String] = [] {
        didSet {
            let numItems: Int = self.data.count

            // Make sure that the number of prefixes matches the number of data points.
            switch self.enumerationStyle {
            case .string(let keys):
                if numItems > keys.count {
                    fatalError("Number of keys must not be smaller then the number of data points!")
                }
            default:
                break
            }

            self.reloadData()
            self.layoutIfNeeded()
        }
    }

    // MARK: - Init
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        self.setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }

    private func setup() {
        self.rowHeight = UITableView.automaticDimension
        self.estimatedRowHeight = 44.0

        self.register(EnumerationCell.self, forCellReuseIdentifier: EnumerationCell.identifier)

        // Configure the view.
        self.isScrollEnabled = false
        //self.isUserInteractionEnabled = false

        self.dataSource = self
        self.delegate = self
    }

    // MARK: - Helper

    func prefix(_ row: Int) -> String {
        switch self.enumerationStyle {
        case .none:
            return ""
        case .number:
            return "\(row+1)."
        case .bullet(let char):
            return "\(char) "
        case .string(let keys):
            return "\(keys[row]): "
        }
    }

    // MARK: - Autoheight

    override var intrinsicContentSize: CGSize {
        self.layoutIfNeeded()
        return self.contentSize
    }

    override var contentSize: CGSize {
        didSet {
            self.invalidateIntrinsicContentSize()
        }
    }

    override func reloadData() {
        super.reloadData()
        self.invalidateIntrinsicContentSize()
    }
}

// MARK: - UITableViewDataSource

extension EnumerationList: UITableViewDataSource {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.title
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: EnumerationCell.identifier, for: indexPath)

        let prefix = self.prefix(indexPath.row)
        let data = self.data[indexPath.row]

        if let myCell = cell as? EnumerationCell {
            myCell.detailLabel.text = prefix

            // Add url support
            if let nsrange = data.containedURL(), let range = Range(nsrange, in: data) {
                let urlStr = String(data[range])

                // Store the link for future use.
                if let enumCell = cell as? EnumerationCell {
                    enumCell.referencedURL = URL(string: urlStr)
                }
                // Underline the string.
                let attrStr = NSMutableAttributedString(string: data)
                let normalAttr: [NSAttributedString.Key: Any] = [ .font: myCell.textView.font! ]
                let linkAttr: [NSAttributedString.Key: Any] = [ .underlineStyle: NSUnderlineStyle.single.rawValue ]
                attrStr.addAttributes(normalAttr, range: NSRange(location: 0, length: data.count))
                attrStr.addAttributes(linkAttr, range: nsrange)

                myCell.textView.attributedText = attrStr
                myCell.textView.textColor = .label
                myCell.textView.isUserInteractionEnabled = false
            } else {
                myCell.textView.text = data
                myCell.isUserInteractionEnabled = true
            }
        }

        return cell
    }
}

// MARK: - UITableViewDelegate

extension EnumerationList: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let headerView = view as? UITableViewHeaderFooterView else { return }
        headerView.textLabel?.font = .systemFont(ofSize: 18)
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let myCell = cell as? EnumerationCell else { return }
        myCell.detailLabel.text = nil
        myCell.textView.text = nil
        myCell.textView.attributedText = nil
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? EnumerationCell else { return }
        if let url = cell.referencedURL {
            UIApplication.shared.open(url)
        }
    }
}
