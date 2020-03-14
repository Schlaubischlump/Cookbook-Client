//
//  Notification+Extension.swift
//  Cookbook
//
//  Created by David Klopp on 07.03.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let login = Notification.Name("com.cookbook.login.notification")
    static let logout = Notification.Name("com.cookbook.logout.notification")
    static let reload = Notification.Name("com.cookbook.reload.notification")
}
