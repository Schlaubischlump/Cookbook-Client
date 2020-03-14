//
//  PreferencesViewControlleriOS.swift
//  Cookbook
//
//  Created by David Klopp on 08.03.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation
import UIKit
import Alamofire

// MARK: - Constants
enum PreferencesModalResponse: Int {
    case cancel = 0
    case save = 1
    case logout = 2
}

typealias PreferencesModalCompletionType = (PreferencesModalResponse) -> Void

// MARK: - UITableViewCells
class PreferencesTextField: UITextField {
    var indexPath: IndexPath?
}

class PreferencesTextFieldCell: UITableViewCell {
    static let identifier: String = "textFieldCell"

    lazy var label: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.text = "Detail"
        return label
    }()

    lazy var textField: PreferencesTextField = {
        let textField = PreferencesTextField()
        textField.borderStyle = .none
        textField.placeholder = "Text"
        return textField
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)

        self.contentView.addSubview(self.label)
        self.contentView.addSubview(self.textField)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let factor: CGFloat = 0.25
        let height = self.contentView.bounds.height
        let width = self.contentView.bounds.width
        let xOff: CGFloat = 10
        let labelWidth = width*factor-xOff
        label.frame = CGRect(x: xOff, y: 0, width: labelWidth, height: height)
        textField.frame = CGRect(x: xOff+labelWidth, y: 0, width: width*(1.0-factor)-xOff, height: height)
    }
}

class PreferencesButtonCell: UITableViewCell {
    static let identifier: String = "buttonCell"

    /// Button title.
    var title: String? {
        get { return self.textLabel?.text }
        set (text) { self.textLabel?.text = text }
    }
    /// Action to perfom on click.
    var action: Selector?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)

        self.textLabel?.isUserInteractionEnabled = false
        self.textLabel?.font = .systemFont(ofSize: UIFont.labelFontSize)
        self.textLabel?.textColor = self.tintColor
        self.textLabel?.textAlignment = .center
        self.textLabel?.text = "Button"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UITableViews
class PreferencesViewControlleriOS: UITableViewController {
    private var modalCompletionHandler: PreferencesModalCompletionType?
    private var textFieldValues: [IndexPath: String] = [:]

    // MARK: - Init
    convenience init() {
        self.init(style: .grouped)
    }

    // MARK: - View handling
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("SETTINGS", comment: "")

        self.tableView.register(PreferencesTextFieldCell.self,
                                forCellReuseIdentifier: PreferencesTextFieldCell.identifier)
        self.tableView.register(PreferencesButtonCell.self,
                                forCellReuseIdentifier: PreferencesButtonCell.identifier)
    }

    // MARK: - UITableViewDatasource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return NSLocalizedString(section == 0 ? "SERVER_CONFIGURATION" : "", comment: "")
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 3 : 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = indexPath.section == 0 ? PreferencesTextFieldCell.identifier : PreferencesButtonCell.identifier
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)

        if let cell = cell as? PreferencesTextFieldCell {
            switch indexPath.row {
            case 0:
                cell.label.text = NSLocalizedString("SERVER", comment: "")
                cell.textField.placeholder = "https://yournextcloudserver.com"
                cell.textField.keyboardType = .URL
                if let server = loginCredentials.server, !server.isEmpty {
                    cell.textField.text = server
                }
            case 1:
                cell.label.text = NSLocalizedString("USER", comment: "")
                cell.textField.placeholder = "John"
                if let user = loginCredentials.username, !user.isEmpty {
                    cell.textField.text = user
                }
            case 2:
                cell.label.text = NSLocalizedString("PASSWORD", comment: "")
                cell.textField.placeholder = "••••••••"
                cell.textField.isSecureTextEntry = true
                if let password = loginCredentials.password, !password.isEmpty {
                    cell.textField.text = password
                }
            default:
                break
            }
            cell.textField.indexPath = indexPath
            cell.textField.addTarget(self, action: #selector(self.textFieldDidChange),
                                     for: UIControl.Event.editingChanged)
            // Store the inital textField value.
            self.textFieldValues[indexPath] = cell.textField.text
        } else if let cell = cell as? PreferencesButtonCell {
            cell.title = NSLocalizedString("LOGOUT", comment: "")
            cell.action = #selector(self.sendLogout)
        }

        return cell
    }

    // MARK: - UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Perform the button action on a click.
        if let cell = tableView.cellForRow(at: indexPath) as? PreferencesButtonCell {
            tableView.deselectRow(at: indexPath, animated: true)
            if let action = cell.action {
                self.perform(action, with: cell)
            }
        }
    }

    // MARK: - Sheet presentation
    func beginSheetModal(completionHandler: @escaping PreferencesModalCompletionType) {
        guard !self.isBeingPresented else { return }
        guard let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else { return }
        guard let mainViewController = keyWindow.rootViewController else { return }

        let preferencesNavController = UINavigationController(rootViewController: self)
        preferencesNavController.modalPresentationStyle = .formSheet

        let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveButtonPressed))
        self.navigationItem.rightBarButtonItem = saveButton

        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self,
                                           action: #selector(self.cancelButtonPressed))
        self.navigationItem.leftBarButtonItem = cancelButton

        self.modalCompletionHandler = completionHandler
        mainViewController.present(preferencesNavController, animated: true)
    }

    // MARK: - Helper
    @objc func textFieldDidChange(textField: UITextField) {
        guard let preferenceTextField = textField as? PreferencesTextField else { return }
        if let indexPath = preferenceTextField.indexPath {
            self.textFieldValues[indexPath] = preferenceTextField.text
        }
    }

    @objc func saveButtonPressed(_ sender: Any) {
        loginCredentials.server = self.textFieldValues[IndexPath(row: 0, section: 0)]
        loginCredentials.username = self.textFieldValues[IndexPath(row: 1, section: 0)]
        loginCredentials.password = self.textFieldValues[IndexPath(row: 2, section: 0)]

        // Reset the login credentials before we try the next api request.
        SessionManager.default.session.reset {
            NotificationCenter.default.post(name: .reload, object: nil)
            DispatchQueue.main.async {
                if let completion = self.modalCompletionHandler {
                    completion(.save)
                }
                self.modalCompletionHandler = nil
            }
        }
    }

    @objc func cancelButtonPressed(_ sender: Any) {
        if let completion = self.modalCompletionHandler {
            completion(.cancel)
        }
        self.modalCompletionHandler = nil
    }

    @objc func sendLogout(_ sender: Any) {
        loginCredentials.server = ""
        loginCredentials.username = ""
        loginCredentials.password = ""

        try? loginCredentials.updateStoredInformation()

        self.tableView.reloadData()

        if let completion = self.modalCompletionHandler {
            completion(.logout)
        }
        self.modalCompletionHandler = nil
    }
}
