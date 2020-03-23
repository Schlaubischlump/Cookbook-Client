//
//  ProgressHUD.swift
//  Cookbook
//
//  Created by David Klopp on 18.03.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation
import UIKit
import MBProgressHUD

/**
 Wrapper class for MBProgressHUD which supports sending notifications when a HUD is displayed or hidden.
 */
class ProgressHUD: MBProgressHUD {
    /// Create a new HUD attached to a specific view.
    static func attached(to view: UIView?) -> MBProgressHUD? {
        guard let view = view else { return nil }

        let hud = ProgressHUD(view: view)
        hud.removeFromSuperViewOnHide = true
        //hud.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        hud.animationType = .zoomIn
        view.addSubview(hud)
        return hud
    }

    /// Show a loading HUD.
    @discardableResult
    static func showSpinner(attachedTo view: UIView?=nil, animated: Bool=true) -> MBProgressHUD? {
        let window = UIApplication.shared.windows.first
        let hud = ProgressHUD.attached(to: view ?? window)
        hud?.mode = .indeterminate
        hud?.show(animated: animated)
        return hud
    }

    /// Show an error HUD.
    @discardableResult
    static func showError(attachedTo view: UIView?=nil, message: String="", animated: Bool=true) -> MBProgressHUD? {
        let window = UIApplication.shared.windows.first
        let hud = ProgressHUD.attached(to: view ?? window)
        let label = UILabel(frame: .zero)
        label.numberOfLines = 0
        label.text = "❌" + (!message.isEmpty ? "\n\n"+message : "")
        label.textAlignment = .center
        label.textColor = .darkGray
        label.backgroundColor = .clear
        hud?.mode = .customView
        hud?.customView = label
        hud?.show(animated: animated)
        return hud
    }
}
