//
//  EnumerationCell.swift
//  Cookbook
//
//  Created by David Klopp on 23.12.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//

import Foundation
import UIKit

enum EnumerationType {
    case none
    case number
    case bullet(_ char: Character = "•")
    case string(_ keys: [String])
}

open class EnumerationCell: UITableViewCell {
    static let identifier = "EnumerationCell"

    fileprivate var referencedURL: URL?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.backgroundColor = .clear
        self.contentView.backgroundColor = .clear
        self.textLabel!.numberOfLines = 0
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/**
 This class implements a simplified list with different styles.
 */
class EnumerationList: UITableView, UITableViewDataSource, UITableViewDelegate {
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
            return "\(row+1).\t"
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

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.title
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: EnumerationCell.identifier, for: indexPath)

        let defaultFont: UIFont = .systemFont(ofSize: UIFont.labelFontSize)
        let normalAttr: [NSAttributedString.Key: Any] = [
            .font: defaultFont
        ]
        let defaultFontSemiBold: UIFont = .systemFont(ofSize: UIFont.labelFontSize, weight: .semibold)
        let boldAttr: [NSAttributedString.Key: Any] = [
            .font: defaultFontSemiBold
        ]

        let data = self.data[indexPath.row]

        let prefix = self.prefix(indexPath.row)
        let string: String = prefix+"\(data)"
        let attrStr = NSMutableAttributedString(string: string)
        attrStr.addAttributes(normalAttr, range: NSRange(location: 0, length: string.count))
        attrStr.addAttributes(boldAttr, range: NSRange(location: 0, length: prefix.count))

        // Add url support
        if let nsrange = data.containedURL(), let range = Range(nsrange, in: data) {
            let urlStr = String(data[range])

            // Store the link for future use.
            if let enumCell = cell as? EnumerationCell {
                enumCell.referencedURL = URL(string: urlStr)
            }
            // Underline the string.
            let linkAttr: [NSAttributedString.Key: Any] = [
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ]
            attrStr.addAttributes(linkAttr, range: NSRange(location: nsrange.location+prefix.count,
                                                           length: nsrange.length))
        }
        cell.textLabel!.attributedText = attrStr

        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let headerView = view as? UITableViewHeaderFooterView else { return }
        headerView.textLabel?.font = .systemFont(ofSize: 18)
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.textLabel?.attributedText = nil
        cell.textLabel?.text = nil
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? EnumerationCell else { return }
        if let url = cell.referencedURL {
            UIApplication.shared.open(url)
        }
    }
}
