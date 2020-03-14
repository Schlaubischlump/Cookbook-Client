//
//  RecipesViewController+ContextMenu.swift
//  Cookbook
//
//  Created by David Klopp on 14.03.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation
import UIKit

extension RecipesViewController {
    /// Show an `Open in new window` button when right clicking on a recipe.
    public override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath,
                                   point: CGPoint) -> UIContextMenuConfiguration? {
        let actionProvider: ([UIMenuElement]) -> UIMenu? = { _ in
            return UIMenu(title: "Actions", image: nil, identifier: nil, children: [
                UIAction(title: NSLocalizedString("OPEN_IN_NEW_WINDOW", comment: ""), image: nil) { _ in
                    let userActivity = NSUserActivity(activityType: ActivityType.main)
                    userActivity.title = ActivityTitle.newWindow
                    userActivity.userInfo = ["row": indexPath.row]
                    UIApplication.shared.requestSceneSessionActivation(nil, userActivity: userActivity, options: nil)
                }
            ])
        }

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: actionProvider)
    }
}
