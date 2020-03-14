//
//  RecipesViewController+DragAndDrop.swift
//  Cookbook
//
//  Created by David Klopp on 14.03.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation
import UIKit

// MARK: - Drag and Drop
extension RecipesViewController: UITableViewDragDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession,
                   at indexPath: IndexPath) -> [UIDragItem] {
        let userActivity = NSUserActivity(activityType: ActivityType.main)
        userActivity.title = ActivityTitle.newWindow
        userActivity.userInfo = ["row": indexPath.row]
        guard let image = tableView.cellForRow(at: indexPath)?.imageView?.image else { return [] }
        let itemProvider = NSItemProvider(object: image)
        itemProvider.registerObject(userActivity, visibility: .all)

        let dragItem = UIDragItem(itemProvider: itemProvider)
        //dragItem.localObject = recipe

        return [dragItem]
    }
}
