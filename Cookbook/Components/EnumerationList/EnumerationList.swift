//
//  EnumerationCell.swift
//  Cookbook
//
//  Created by David Klopp on 23.12.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//
// This class always assumes that all cells are visible. Do not use this class if you want your tableView to be
// scrollable. It will not work.

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
                // Stop editing every textView.
                self.visibleCells.forEach { enumCell in
                    let cell = enumCell as? EnumerationCell
                    cell?.textView.isEditable = false
                    cell?.textView.spellCheckingType = .no
                }
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

    deinit {
        #if !targetEnvironment(macCatalyst)
        let center = NotificationCenter.default
        center.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: nil)
        center.removeObserver(self, name: UIResponder.keyboardDidHideNotification, object: nil)
        #endif
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
        let newIndexPath = IndexPath(item: self._data.count, section: 0)
        self.performBatchUpdates({
            self._data.append("")
            self.insertRows(at: [newIndexPath], with: .fade)
        }, completion: { _ in
            if let cell = self.cellForRow(at: newIndexPath) as? EnumerationCell {
                cell.textView.becomeFirstResponder()
            }
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
        if let title = self.title, !title.isEmpty {
            return title
        }
        return nil
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
                    self?._data[indexPath.row] = myCell.textView.attributedText.string
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
            // This fix is necessary for the pdf share function when dark mode is active.
            let textColor: UIColor = (self.overrideUserInterfaceStyle == .light) ? .black : .label
            myCell.textView.textColor = textColor
            myCell.detailLabel.textColor = textColor
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
