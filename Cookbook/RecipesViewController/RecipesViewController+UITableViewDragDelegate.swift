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
        let recipe = self.filteredRecipes[indexPath.row]
        let userActivity = NSUserActivity(activityType: ActivityType.default)
        userActivity.title = ActivityTitle.newWindow
        userActivity.userInfo = recipe.toDict()
        guard let image = tableView.cellForRow(at: indexPath)?.imageView?.image else { return [] }
        let itemProvider = NSItemProvider(object: image)
        itemProvider.registerObject(userActivity, visibility: .all)

        let dragItem = UIDragItem(itemProvider: itemProvider)
        //dragItem.localObject = self.filteredRecipes[indexPath.row]

        return [dragItem]
    }
}
