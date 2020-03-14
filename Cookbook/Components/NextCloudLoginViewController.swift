//
//  NextCloudLoginViewController.swift
//  Cookbook
//
//  Created by David Klopp on 03.03.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//
// This file is ment to be portable. Do not relay on any Interface Builder .xib files or similar.
// Do all layout inside the code.

import Foundation
import UIKit

// MARK: - Constants
typealias NextCloudModalCompletionType = (NextCloudModalResponse) -> Void

// MARK: - Default Extensions
extension UIImage {
    static func imageFrom(color: UIColor) -> UIImage? {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

extension UIColor {
    class var nextCloudBlue: UIColor {
        return UIColor(displayP3Red: 0, green: 130/255, blue: 201/255, alpha: 1)
    }
}

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

        self.textField.backgroundColor = .clear
        self.contentView.addSubview(self.textField)

        self.separator.backgroundColor = .lightGray
        self.contentView.addSubview(self.separator)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let xOff = self.separatorInset.left
        var contentFrame = self.contentView.bounds
        contentFrame.size.width -= xOff
        contentFrame.origin.x += xOff

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
    private var tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var loginButton = UIButton(type: .custom)
    private var modalCompletionHandler: NextCloudModalCompletionType?

    var server: String?
    var username: String?
    var password: String?

    // MARK: - Button visibility
    var showsCancelButton: Bool = false {
        didSet {
            if self.showsCancelButton {
                let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self,
                                                   action: #selector(cancel))
                self.navigationItem.leftBarButtonItem = cancelButton
            } else {
                self.navigationItem.leftBarButtonItem = nil
            }
        }
    }

    var showsSaveButton: Bool = false {
        didSet {
            if self.showsSaveButton {
                let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))
                self.navigationItem.rightBarButtonItem = saveButton
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
        self.tableView.backgroundColor = .systemBackground
        self.tableView.separatorStyle = .none
        self.tableView.keyboardDismissMode = .interactive

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

        self.view.addSubview(self.tableView)

        // Configure the tableView.
        self.tableView.dataSource = self
        self.tableView.delegate = self

        // Setup the login button.
        self.loginButton.setTitle(NSLocalizedString("LOGIN", comment: ""), for: .normal)
        self.loginButton.titleLabel?.textColor = .white
        self.loginButton.setBackgroundImage(.imageFrom(color: .nextCloudBlue), for: .normal)
        self.loginButton.addTarget(self, action: #selector(login), for: .touchUpInside)
        self.loginButton.clipsToBounds = true
        self.view.addSubview(self.loginButton)

        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(notification:)),
                                               name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(notification:)),
                                               name: UIResponder.keyboardDidHideNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Start the logo animation.
        guard animated else { return }
        if let logoView = self.navigationItem.titleView as? UIImageView {
            logoView.startAnimating()
            logoView.image = logoView.animationImages?.last
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let padY: CGFloat = 20
        let buttonHeight: CGFloat = 60

        // Layout the tableView.
        var frame = self.view.bounds
        if !self.loginButton.isHidden {
            frame.size.height -= buttonHeight + 2*padY
        }
        self.tableView.frame = frame

        // Layout the login button.
        frame.size.height = buttonHeight
        frame.origin.y = self.tableView.frame.maxY+padY
        frame.size.width = frame.width*0.33
        frame.origin.x = (self.tableView.frame.width - frame.width)/2
        self.loginButton.frame = frame
        self.loginButton.layer.cornerRadius = buttonHeight/2
    }

    // MARK: - Save / Cancel / Login dialog
    @objc func cancel() {
        if let completion = self.modalCompletionHandler {
            completion(.cancel)
        }
        self.modalCompletionHandler = nil
    }

    @objc func save() {
        if let completion = self.modalCompletionHandler {
            completion(.save)
        }
        self.modalCompletionHandler = nil
    }

    @objc func login() {
        if let completion = self.modalCompletionHandler {
            completion(.login)
        }
        //self.dismiss(animated: true)
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
        default:
            break
        }

        return cell
    }

    @objc func textFieldDidChange(textField: UITextField) {
        guard let entryField = textField as? NextCloudTextField else { return }

        switch entryField.entryType {
        case .server:
            self.server = entryField.text
        case .user:
            self.username = entryField.text
        case .passwd:
            self.password = entryField.text
        case .none:
            break
        }
    }
}

// MARK: - Keyboard handling
extension NextCloudLoginController: UITextFieldDelegate {

    /// User presses return key.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardHeight = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?
            .cgRectValue.height {
            self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        UIView.animate(withDuration: 0.25, animations: {
            // For some reason adding inset in keyboardWillShow is animated by itself but removing is not, that's why we
            // have to use animateWithDuration here
            self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
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
