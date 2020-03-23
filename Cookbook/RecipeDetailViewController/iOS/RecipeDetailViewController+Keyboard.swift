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
            if let cell = firstResponderCell, let scrollView = self.scrollView {
                // Cell frame inside the scrollView.
                let cellFrameInsideScrollView = scrollView.convert(cell.frame, from: cell.superview)

                if keyboardFrame != nil {
                    // Cell frame converted to absolut screen coodinates.
                    var cellFrameAbsolut = cellFrameInsideScrollView
                    cellFrameAbsolut.origin.y -= scrollView.contentOffset.y
                    cellFrameAbsolut.origin.x -= scrollView.contentOffset.x
                    cellFrameAbsolut = self.view.convert(cellFrameAbsolut, to: nil)
                    // If the keyboard intersects with the absolut cell frame then scroll the cell to be visible.
                    if cellFrameAbsolut.intersects(keyboardFrame!) {
                        scrollView.scrollRectToVisible(cellFrameInsideScrollView, animated: true)
                    }
                    // We do not need to look any further.
                    break
                } else {
                    scrollView.scrollRectToVisible(cellFrameInsideScrollView, animated: true)
                }
            }
        }
    }

    /**
     Extend the scrollView contentInset bottom when the keyboard is visible.
     */
    @objc func keyboardDidShow(_ notification: Notification) {
        let keyboardFrameInfo = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
        guard let keyboardFrame = (keyboardFrameInfo as? NSValue)?.cgRectValue,
              let scrollView = self.scrollView else { return }

        // Calculate the intersection between the keyboard and the srollView. Therefore transform the scrollView frame
        // to absolut screen coordinates.
        let scrollViewFrame = self.view.convert(scrollView.frame, to: nil)
        let keyboardBottomInset = scrollViewFrame.intersection(keyboardFrame).height

        UIView.animate(withDuration: 0.25, animations: {
            scrollView.contentInset.bottom = keyboardBottomInset
            scrollView.verticalScrollIndicatorInsets.bottom = keyboardBottomInset
        })

        self.makeFirstResponderVisible(keyboardFrame: keyboardFrame)
    }

    /**
     Remove the additional scrollView contentInset bottom when the keyboard is hidden.
     */
    @objc func keyboardDidHide(_ notification: Notification) {
        guard let scrollView = self.scrollView else { return }
        UIView.animate(withDuration: 0.25, animations: {
            scrollView.contentInset.bottom = 0
            scrollView.verticalScrollIndicatorInsets.bottom = 0
        })
    }
}
