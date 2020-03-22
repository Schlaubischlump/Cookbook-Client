//
//  RecipesViewController+Keyboard.swift
//  Cookbook
//
//  Created by David Klopp on 22.03.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation
import UIKit

extension RecipeDetailViewController {

    /**
     Scroll the scrollView to make the first responder cell visible. If a `keyboardFrame` is provider it is first
     ensured that the cell is covered by the keyboard. Otherwise the scrollView will scroll directly.
     - Parameter keyboardFrame: Frame of the software keyboard.
    */
    func makeFirstResponderVisible(keyboardFrame: CGRect?) {
        // We need to find the first responder and the corresponding tableView cell.
        for enumList in [self.descriptionList, self.toolsList, self.instructionsList, self.ingredientsList] {
            guard let list = enumList else { return }

            let firstResponderCell = list.visibleCells.first(where: {
                ($0 as? EnumerationCell)?.textView.isFirstResponder ?? false
            })
            // We found a first responder.
            if let cell = firstResponderCell {
                // Cell frame inside the scrollView.
                let cellFrameInsideScrollView = self.scrollView.convert(cell.frame, from: cell.superview)

                if keyboardFrame != nil {
                    // Cell frame converted to absolut screen coodinates.
                    var cellFrameAbsolut = cellFrameInsideScrollView
                    cellFrameAbsolut.origin.y -= self.scrollView.contentOffset.y
                    cellFrameAbsolut.origin.x -= self.scrollView.contentOffset.x
                    cellFrameAbsolut = self.view.convert(cellFrameAbsolut, to: nil)
                    // If the keyboard intersects with the absolut cell frame then scroll the cell to be visible.
                    if cellFrameAbsolut.intersects(keyboardFrame!) {
                        self.scrollView.scrollRectToVisible(cellFrameInsideScrollView, animated: true)
                    }
                    // We do not need to look any further.
                    break
                } else {
                    self.scrollView.scrollRectToVisible(cellFrameInsideScrollView, animated: true)
                }
            }
        }
    }

    /**
     Extend the scrollView contentInset bottom when the keyboard is visible.
     */
    @objc func keyboardDidShow(_ notification: Notification) {
        let keyboardFrameInfo = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
        guard let keyboardFrame = (keyboardFrameInfo as? NSValue)?.cgRectValue else { return }

        // Calculate the intersection between the keyboard and the srollView. Therefore transform the scrollView frame
        // to absolut screen coordinates.
        let scrollViewFrame = self.view.convert(self.scrollView.frame, to: nil)
        let keyboardBottomInset = scrollViewFrame.intersection(keyboardFrame).height

        UIView.animate(withDuration: 0.25, animations: {
            self.scrollView.contentInset.bottom = keyboardBottomInset
            self.scrollView.verticalScrollIndicatorInsets.bottom = keyboardBottomInset
        })

        self.makeFirstResponderVisible(keyboardFrame: keyboardFrame)
    }

    /**
     Remove the additional scrollView contentInset bottom when the keyboard is hidden.
     */
    @objc func keyboardDidHide(_ notification: Notification) {
        UIView.animate(withDuration: 0.25, animations: {
            self.scrollView.contentInset.bottom = 0
            self.scrollView.verticalScrollIndicatorInsets.bottom = 0
        })
    }
}
