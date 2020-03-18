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
 Delegate to get informed if the EnumerationList height changes.
 */
protocol EnumerationListDelegate: AnyObject {
    func enumerationList(_ list: EnumerationList, heightChanged: CGFloat)
}

extension EnumerationListDelegate {
    func enumerationList(_ list: EnumerationList, heightChanged: CGFloat) {}
}

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

/**
 This class implements a simplified list with different styles.
 */
class EnumerationList: UITableView {
    /// Delegate for enumeration List callbacks.
    weak var listDelegate: EnumerationListDelegate?

    /// Enumeration display style.
    var enumerationStyle: EnumerationType = .none

    /// Allow adding a new row in edit mode.
    var allowsCellInsertion: Bool = false

    /// Allow deleting rows in the list.
    var allowsCellDeletion: Bool = false

    /// List title.
    var title: String? = nil {
        didSet {
            self.reloadData()
        }
    }

    /// Internal data array.
    private var _data: [String] = []

    /// List data to display.
    var data: [String] {
        get {
            return self._data
        }

        set (newValue) {

            let numItems: Int = newValue.count

            // Make sure that the number of prefixes matches the number of data points.
            switch self.enumerationStyle {
            case .string(let keys):
                if numItems > keys.count {
                    fatalError("Number of keys must not be smaller then the number of data points!")
                }
            default:
                break
            }

            self._data = newValue

            self.reloadData()
            self.layoutIfNeeded()
        }
    }

    var isEditable: Bool = false {
        didSet {
            // Apply the new data.
            if !self.isEditable {
                // We do not want to trigger the reload => store everything in a temp array.
                var newData: [String] = Array(repeating: "", count: self._data.count)
                // Stop editing and set the new string data.
                zip(self.indexPathsForVisibleRows!, self.visibleCells).forEach { (indexPath, enumCell) in
                    let cell = enumCell as? EnumerationCell
                    // Update the backend data.
                    cell?.textView.isEditable = false
                    cell?.textView.spellCheckingType = .no
                    newData[indexPath.row] = cell?.textView.attributedText.string ?? ""
                }
                // Trigger reload by setting the new data to make all cells visible.
                self.data = newData
            } else {
                // Reload to make all cells visible.
                self.reloadData()
                self.visibleCells.forEach {
                    let cell = $0 as? EnumerationCell
                    // Start editing.
                    cell?.textView.isEditable = true
                    cell?.textView.spellCheckingType = .yes
                }
            }
            self.isEditing = self.isEditable
            // Reload to show / hide the footer view.
            self.reloadData()
            // Inform the delegate to update the frame.
            self.listDelegate?.enumerationList(self, heightChanged: self.contentSize.height)
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

    @objc func deleteRowAtIndexPath(_ indexPath: IndexPath) {
        self.performBatchUpdates({
            self._data.remove(at: indexPath.row)
            self.deleteRows(at: [indexPath], with: .fade)
        }, completion: { _ in
             // Update the numbers on the left side of the view.
            switch self.enumerationStyle {
            case .number:
                for (row, cell) in self.visibleCells.enumerated() {
                   (cell as? EnumerationCell)?.detailLabel.text = self.prefix(row)
                }
            case .string(var keys):
                keys.remove(at: indexPath.row)
            default: break
            }
             self.listDelegate?.enumerationList(self, heightChanged: self.contentSize.height)
        })
    }

    @objc func appendRow(sender: Any) {
        self.performBatchUpdates({
            self._data.append("")
            self.insertRows(at: [IndexPath(item: self._data.count-1, section: 0)], with: .fade)
        }, completion: { _ in
            self.listDelegate?.enumerationList(self, heightChanged: self.contentSize.height)
        })
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
        return self._data.count
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard self.isEditable && self.allowsCellInsertion else { return nil }

        let footerView = UIView()
        let addButton = UIButton(type: .contactAdd)
        addButton.frame.origin = CGPoint(x: self.separatorInset.left, y: 5)
        addButton.addTarget(self, action: #selector(self.appendRow), for: .touchUpInside)
        footerView.addSubview(addButton)
        return footerView
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return (self.isEditable && self.allowsCellInsertion) ? 30 : 0
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return self.isEditable && self.allowsCellDeletion
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath)
        -> UITableViewCell.EditingStyle {
            return .none
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: EnumerationCell.identifier, for: indexPath)

        if let myCell = cell as? EnumerationCell {
            myCell.textView.isEditable = self.isEditable
            myCell.textView.isSelectable = true
            myCell.detailLabel.text = self.prefix(indexPath.row)
            myCell.deleteAccessoryAction = {
                guard let indexPath = self.indexPath(for: myCell) else { return }
                self.deleteRowAtIndexPath(indexPath)
            }

            myCell.textChanged = { [weak self] text in
                UIView.animate(withDuration: 0, animations: {
                    self?.beginUpdates()
                    self?.endUpdates()
                }, completion: { _ in
                    guard let self = self else { return }
                    self.listDelegate?.enumerationList(self, heightChanged: self.contentSize.height)
                })
            }

            // Fill the textView with the corresponding data.
            let data = self._data[indexPath.row]
            let attrStr = NSMutableAttributedString(string: data)
            attrStr.addAttributes([.font: myCell.textView.font!], range: NSRange(location: 0, length: data.count))

            // Set the text property to resize the textView to have a height greater 0, even if the text is empty.
            // textView.text will not be displayed, because we are settings the attributedText afterwards.
            myCell.textView.text = " "
            myCell.textView.attributedText = attrStr
            myCell.textView.textColor = .label
            myCell.textView.linkTextAttributes = [ .underlineStyle: NSUnderlineStyle.single.rawValue ]
        }
        return cell
    }

    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}

// MARK: - UITableViewDelegate

extension EnumerationList: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        (view as? UITableViewHeaderFooterView)?.textLabel?.font = .systemFont(ofSize: 18)
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let myCell = cell as? EnumerationCell else { return }
        myCell.detailLabel.text = nil
        myCell.textView.attributedText = nil
    }
}
