//
//  PreferencesViewController.swift
//  Cookbook
//
//  Created by David Klopp on 06.03.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation
import UIKit
import Alamofire

class PreferencesViewControllerMac: UIViewController {
    @IBOutlet var serverLabel: UILabel!
    @IBOutlet var userLabel: UILabel!
    @IBOutlet var passwordLabel: UILabel!
    @IBOutlet var serverField: UITextField!
    @IBOutlet var userField: UITextField!
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var logoutButton: UIButton!

    private var didPerformLogout: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("PREFERENCES", comment: "")

        self.serverLabel.text = NSLocalizedString("SERVER", comment: "") + ":"
        self.userLabel.text = NSLocalizedString("USER", comment: "") + ":"
        self.passwordLabel.text = NSLocalizedString("PASSWORD", comment: "") + ":"
        self.logoutButton.setTitle(NSLocalizedString("LOGOUT", comment: ""), for: .normal)

        // Configure the textfields.
        self.passwordField.isSecureTextEntry = true

        // Fill in placeholder values.
        self.serverField.placeholder = "https://yournextcloudserver.com"
        self.userField.placeholder = "John"
        self.passwordField.placeholder = "••••••••"

        // Load the current credentials inside the window
        self.serverField.text = loginCredentials.server
        self.userField.text = loginCredentials.username
        self.passwordField.text = loginCredentials.password

        // Add callbacks.
        self.serverField.addTarget(self, action: #selector(self.textFieldDidChange),
                                   for: UIControl.Event.editingChanged)
        self.userField.addTarget(self, action: #selector(self.textFieldDidChange),
                                 for: UIControl.Event.editingChanged)
        self.passwordField.addTarget(self, action: #selector(self.textFieldDidChange),
                                     for: UIControl.Event.editingChanged)
    }

    @objc func textFieldDidChange(textField: UITextField) {
        if textField == self.userField {
            loginCredentials.username = self.userField.text
        } else if textField == self.passwordField {
            loginCredentials.password = self.passwordField.text
        } else if textField == self.serverField {
            loginCredentials.server = self.serverField.text
        }
    }

    @IBAction func logoutClicked(_ sender: UIButton) {
        self.serverField.text = ""
        self.userField.text = ""
        self.passwordField.text = ""

        loginCredentials.server = ""
        loginCredentials.username = ""
        loginCredentials.password = ""

        try? loginCredentials.updateStoredInformation()

        NotificationCenter.default.post(name: .logout, object: nil)

        self.didPerformLogout = true

        /*
         // If you want to close the window after a logout.
         if let session = self.view.window?.windowScene?.session {
            UIApplication.shared.requestSceneSessionDestruction(session, options: nil)
        }*/
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        try? loginCredentials.updateStoredInformation()

        // Reset the login credentials before we try the next api request.
        if self.didPerformLogout && !loginCredentials.informationIsSet() { return }

        Session.default.session.reset {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .reload, object: nil)
            }
        }
    }
}
