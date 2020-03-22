//
//  NextCloudLoginViewController.swift
//  Cookbook
//
//  Created by David Klopp on 03.03.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//
// This file is ment to be portable. Do not relay on any Interface Builder .xib files or similar.
// Do all layout inside the code and include all extensions in this file.

import Foundation
import UIKit

// MARK: - Default Extensions
extension UIImage {
    static func imageFrom(color: UIColor) -> UIImage? {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        let renderFormat = UIGraphicsImageRendererFormat.default()
        renderFormat.opaque = true
        let renderer = UIGraphicsImageRenderer(size: rect.size, format: renderFormat)
        return renderer.image { context in
            color.setFill()
            context.fill(rect)
        }
    }
}

extension UIColor {
    class var nextCloudBlue: UIColor {
        return UIColor(displayP3Red: 0, green: 130/255, blue: 201/255, alpha: 1)
    }
}

// MARK: - Constants
typealias NextCloudModalCompletionType = (NextCloudModalResponse) -> Void

// MARK: - Enums
enum EntryType: Int {
    case none = -1
    case server = 0
    case user = 1
    case passwd = 2
}

enum NextCloudModalResponse: Int {
    case cancel = 0
    case save = 1
    case login = 2
}

// MARK: - Helper Classes
class NextCloudTextField: UITextField {
    /// Reference to the corresponding entry.
    var entryType: EntryType = .none
}

class NextCloudTextfieldCell: UITableViewCell {
    static let identifier = "NextCloudTextfieldCell"

    /// Reference to the user editable textField
    let textField = NextCloudTextField(frame: .zero)

    /// Internal reference to the separator line below the textField.
    private let separator = UIView(frame: .zero)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)

        self.selectionStyle = .none
        self.backgroundColor = .clear
        self.contentView.backgroundColor = .clear

        self.textField.returnKeyType = .done
        self.textField.backgroundColor = .clear
        self.contentView.addSubview(self.textField)

        self.separator.backgroundColor = .lightGray
        self.contentView.addSubview(self.separator)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        var contentFrame = self.contentView.bounds
        contentFrame.size.width -= self.separatorInset.left
        contentFrame.origin.x += self.separatorInset.left

        self.textField.frame = contentFrame
        self.separator.frame = CGRect(x: contentFrame.minX, y: contentFrame.height-1,
                                      width: contentFrame.width, height: 1)

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - View Controller
class NextCloudLoginController: UIViewController {
    private var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .interactive
        return tableView
    }()

    private lazy var loginButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(NSLocalizedString("LOGIN", comment: ""), for: .normal)
        button.titleLabel?.textColor = .white
        button.setBackgroundImage(.imageFrom(color: .nextCloudBlue), for: .normal)
        button.addTarget(self, action: #selector(login), for: .touchUpInside)
        button.clipsToBounds = true
        return button
    }()

    private var modalCompletionHandler: NextCloudModalCompletionType?

    var server: String?
    var username: String?
    var password: String?

    private var originalBottomInset: CGFloat = 0

    // MARK: - Button visibility
    var showsCancelButton: Bool = false {
        didSet {
            if self.showsCancelButton {
                self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self,
                                                                        action: #selector(cancel))
            } else {
                self.navigationItem.leftBarButtonItem = nil
            }
        }
    }

    var showsSaveButton: Bool = false {
        didSet {
            if self.showsSaveButton {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self,
                                                                         action: #selector(save))
            } else {
                self.navigationItem.rightBarButtonItem = nil
            }
        }
    }

    var showsLoginButton: Bool = true {
        didSet {
            self.loginButton.isHidden = !self.showsLoginButton
            self.view.setNeedsLayout()
            self.view.layoutSubviews()
        }
    }

    // MARK: - Constructor
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }

    private func setup() {
        self.tableView.register(NextCloudTextfieldCell.self, forCellReuseIdentifier: NextCloudTextfieldCell.identifier)
    }

    // MARK: - View Handling
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground

        // Configure the navigationbar if it is available.
        if let navbar = self.navigationController?.navigationBar {
            navbar.isTranslucent = false
            navbar.barTintColor = .nextCloudBlue
            navbar.tintColor = .white

            let logoView = UIImageView(image: #imageLiteral(resourceName: "logo0"))
            logoView.contentMode = .scaleAspectFit
            logoView.animationImages = (0...33).map { UIImage(named: "logo\($0)")! }
            logoView.animationDuration = 1.0
            logoView.animationRepeatCount = 1
            self.navigationItem.titleView = logoView
        }

        // Setup the login button.
        self.view.addSubview(self.tableView)
        self.view.addSubview(self.loginButton)

        // Configure the tableView.
        self.tableView.dataSource = self
        self.tableView.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(notification:)),
                                               name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(notification:)),
                                               name: UIResponder.keyboardDidHideNotification, object: nil)

        // Start the logo animation.
        if animated, let logoView = self.navigationItem.titleView as? UIImageView {
            logoView.startAnimating()
            logoView.image = logoView.animationImages?.last
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidHideNotification, object: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let frame = self.view.bounds
        let padY: CGFloat = 20
        let buttonHeight: CGFloat = 60
        let buttonWidth = frame.width*0.33

        // Layout the tableView.
        self.tableView.frame = frame
        if !self.loginButton.isHidden {
            self.tableView.contentInset.bottom = buttonHeight + 2*padY
            self.tableView.verticalScrollIndicatorInsets.bottom = buttonHeight + 2*padY
        }

        // Layout the login button.
        self.loginButton.layer.cornerRadius = buttonHeight/2
        self.loginButton.frame = CGRect(x: (frame.width-buttonWidth)/2, y: frame.height-padY-buttonHeight,
                                        width: buttonWidth, height: buttonHeight)
    }

    // MARK: - Save / Cancel / Login dialog
    @objc func cancel() {
        if let completion = self.modalCompletionHandler { completion(.cancel) }
    }

    @objc func save() {
        if let completion = self.modalCompletionHandler { completion(.save) }
    }

    @objc func login() {
        if let completion = self.modalCompletionHandler { completion(.login) }
    }

    // MARK: - Sheet presentation
    func beginSheetModal(_ viewController: UIViewController,
                         completionHandler: @escaping NextCloudModalCompletionType) {
        guard !self.isBeingPresented else { return }

        let nextCloudNavController = UINavigationController(rootViewController: self)
        nextCloudNavController.modalPresentationStyle = .formSheet
        nextCloudNavController.isModalInPresentation = true

        self.modalCompletionHandler = completionHandler
        viewController.present(nextCloudNavController, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension NextCloudLoginController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return NSLocalizedString("SERVER", comment: "")
        case 1: return NSLocalizedString("USER", comment: "")
        case 2: return NSLocalizedString("PASSWORD", comment: "")
        default: return ""
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: NextCloudTextfieldCell.identifier,
                                                 for: indexPath) as! NextCloudTextfieldCell
        // swiftlint:enable force_cast
        cell.textField.returnKeyType = .done
        cell.textField.delegate = self
        cell.textField.addTarget(self, action: #selector(self.textFieldDidChange), for: UIControl.Event.editingChanged)

        switch indexPath.section {
        case EntryType.server.rawValue:
            cell.textField.placeholder = "https://yournextcloudserver.com"
            cell.textField.keyboardType = .URL
            cell.textField.text = self.server
            cell.textField.entryType = .server
        case EntryType.user.rawValue:
            cell.textField.placeholder = "John"
            cell.textField.text = self.username
            cell.textField.entryType = .user
        case EntryType.passwd.rawValue:
            cell.textField.isSecureTextEntry = true
            cell.textField.placeholder = "••••••••"
            cell.textField.text = self.password
            cell.textField.entryType = .passwd
        default: break
        }

        return cell
    }

    @objc func textFieldDidChange(textField: UITextField) {
        guard let entryField = textField as? NextCloudTextField else { return }

        switch entryField.entryType {
        case .server: self.server = entryField.text
        case .user:   self.username = entryField.text
        case .passwd: self.password = entryField.text
        case .none:   break
        }
    }
}

// MARK: - Keyboard handling
extension NextCloudLoginController: UITextFieldDelegate {

    /// User presses return key.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        let keyboardFrameInfo = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
        guard let keyboardFrame = (keyboardFrameInfo as? NSValue)?.cgRectValue else { return }
        // Idea: Calculate the y value from the bottom of the screen to the bottom of the tableView in screen
        // coordinates and intersect this frame with the keyboard frame.
        // 1. Convert the tableView frame to absolut screen coordintes.
        let tableViewFrame = self.view.convert(self.tableView.frame, to: nil)
        // 2. Calculate the intersection with the keyboardFrame.
        self.originalBottomInset = self.tableView.contentInset.bottom
        let keyboardBottomInset = tableViewFrame.intersection(keyboardFrame).height //+ heightDelta
        // 3. Adjust the content inset.
        UIView.animate(withDuration: 0.25, animations: {
            self.tableView.contentInset.bottom = keyboardBottomInset
            self.tableView.verticalScrollIndicatorInsets.bottom = keyboardBottomInset
        })
        // Scroll to make the firstResponder textField visible.
        // 1. Find the cell which contains the firstResponder.
        let firstResponderCell = self.tableView.visibleCells.first(where: {
            ($0 as? NextCloudTextfieldCell)?.textField.isFirstResponder ?? false
        })
        if let cell = firstResponderCell as? NextCloudTextfieldCell {
            // 2. Convert the frame of the cell to absolut screen
            let cellFrame = cell.superview?.convert(cell.frame, to: nil)
            if cellFrame?.intersects(keyboardFrame) ?? false {
                // 3. Scroll the cell to be visible
                self.tableView.scrollRectToVisible(cell.frame, animated: true)
            }
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        UIView.animate(withDuration: 0.25, animations: {
            self.tableView.contentInset.bottom = self.originalBottomInset
            self.tableView.verticalScrollIndicatorInsets.bottom = self.originalBottomInset
        })
    }
}

// MARK: - UITableViewDelegate
extension NextCloudLoginController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let myCell = cell as? NextCloudTextfieldCell else { return }
        myCell.textField.delegate = nil
        myCell.textField.text = nil
        myCell.textField.isSecureTextEntry = false
        myCell.textField.keyboardType = .default
        myCell.textField.entryType = .none
    }
}
