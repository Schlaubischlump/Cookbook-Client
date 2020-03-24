//
//  DetailViewController.swift
//  Cookbook
//
//  Created by David Klopp on 22.12.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//

import UIKit
import MBProgressHUD

/// Change layout to two column or one on a mac.
let kMaxCellWidth: CGFloat = 500

class RecipeDetailViewController: UIViewController {
    // MARK: - Properties

    /// main scrollview container
    @IBOutlet var scrollView: UIScrollView?
    @IBOutlet var contentView: UIView?

    /// parallax header image view
    @IBOutlet var parallaxHeaderImageView: UIImageView?

    /// header image view top / height constraint
    @IBOutlet var parallaxHeightConstraint: NSLayoutConstraint?
    @IBOutlet var parallaxTopConstraint: NSLayoutConstraint?

    /// List with general information about the recipe
    @IBOutlet var descriptionList: EnumerationList?
    @IBOutlet var descriptionListHeight: NSLayoutConstraint?

    /// List with all tools required.
    @IBOutlet var toolsList: EnumerationList?
    @IBOutlet var toolsListHeight: NSLayoutConstraint?

    /// List with all ingredients.
    @IBOutlet var ingredientsList: EnumerationList?
    @IBOutlet var ingredientsListHeight: NSLayoutConstraint?

    /// List with all instructions.
    @IBOutlet var instructionsList: EnumerationList?
    @IBOutlet var instructionsListHeight: NSLayoutConstraint?

    /// Initital height of the parallax image view.
    lazy var initialParallaxHeight: CGFloat = {
        return self.parallaxHeightConstraint?.constant ?? 0
    }()

    /// Compact and Regular constraints.
    @IBOutlet var toolListTrailingRegular: NSLayoutConstraint!
    @IBOutlet var instructionListTopRegular: NSLayoutConstraint!
    @IBOutlet var instructionListLeadingRegular: NSLayoutConstraint!
    @IBOutlet var instructionListTrailingRegular: NSLayoutConstraint!

    @IBOutlet var toolListTrailingCompact: NSLayoutConstraint!
    @IBOutlet var instructionListTopCompact: NSLayoutConstraint!
    @IBOutlet var instructionListLeadingCompact: NSLayoutConstraint!
    @IBOutlet var instructionListTrailingCompact: NSLayoutConstraint!

    /// Recipe which belongs to this viewcontroller.
    var recipe: Recipe? {
        didSet (newRecipe) {
            if self.recipe?.recipeID != newRecipe?.recipeID {
                self.reloadData(useCachedData: false)
            }
        }
    }

    /// Recipe details for this detailItem.
    var recipeDetails: [String: Any] = [:]

    /**
      The current recipe details as represented in the UI. These values must not represent the actual recipeDetails
      stored on the server. Thus property is nil when not in edit mode.
    */
    var proposedRecipeDetails: [String: Any]? {
        guard self.isEditable else { return nil }
        // Because dictionary and array are both structs, this should copy the recipeDetails.
        var details: [String: Any] = self.recipeDetails
        if let descriptionList = self.descriptionList, descriptionList.data.count == 8 {
            details["name"] = descriptionList.data[0]
            details["description"] = descriptionList.data[1]
            details["url"] = descriptionList.data[2]
            details["image"] = descriptionList.data[3]
            details["prepTime"] = descriptionList.data[4].iso8601()
            details["cookTime"] = descriptionList.data[5].iso8601()
            details["totalTime"] = descriptionList.data[6].iso8601()
            details["recipeYield"] = descriptionList.data[7].intValue
        }
        // Copy the remaining lists.
        details["tool"] = self.toolsList?.data ?? []
        details["recipeIngredient"] = self.ingredientsList?.data ?? []
        details["recipeInstructions"] = self.instructionsList?.data ?? []
        return details
     }

    /// Include the parallax header view.
    var includeParallaxHeaderView: Bool = true {
        didSet {
            if self.isViewLoaded {
                self.parallaxHeaderImageView?.isHidden = !self.includeParallaxHeaderView
                self.parallaxHeightConstraint?.constant = self.includeParallaxHeaderView ? 320 : 0
            }
        }
    }

    /**
     Toggle edit mode on and off. This method does not change any data.
     */
    var isEditable: Bool = false {
        didSet {
            guard isViewLoaded else { return }

            if self.isEditable {
                // Show all available description fields.
                self.reloadRecipeDescriptionList(includeAllFields: true)

                // Start editing the view.
                self.descriptionList?.isEditable = true
                self.ingredientsList?.isEditable = true
                self.instructionsList?.isEditable = true
                self.toolsList?.isEditable = true
            } else {
                // Write all the data entered in the UI back to the datastructure.
                self.descriptionList?.isEditable = false
                self.ingredientsList?.isEditable = false
                self.instructionsList?.isEditable = false
                self.toolsList?.isEditable = false

                // Hide all not requiered fields.
                self.reloadRecipeDescriptionList(includeAllFields: false)
            }
        }
    }

    /// Start edit mode as soon as the view appears on the screen.
    var startEditModeOnViewDidAppear: Bool = false

    private var logoutObserver: NSObjectProtocol?
    private var reloadObserver: NSObjectProtocol?

    // MARK: - Helper

    /**
     Update the recipe description list. If `includeAllFields` is true, the description list will include entries
     with an empty value as well as an additional field for `image` and `name`.
     - Parameter includeAllFields: show all avaiable fields
     */
    private func reloadRecipeDescriptionList(includeAllFields: Bool = false) {
        var (descKeys, descData) = Recipe.parseDescriptionValuesFor(jsonArray: self.recipeDetails)

        if includeAllFields {
            // Add a value for each possible field.
            let lookUpKeyData = Dictionary(uniqueKeysWithValues: zip(descKeys, descData))
            descKeys = Recipe.descriptionKeys
            descData = descKeys.map { lookUpKeyData[$0] ?? ""  }

            // Add extra entries to change the recipe name and image.
            descKeys.insert(NSLocalizedString("NAME", comment: ""), at: 0)
            descKeys.insert(NSLocalizedString("IMAGE", comment: ""), at: 3)
            descData.insert(self.recipeDetails["name"] as? String ?? "", at: 0)
            descData.insert(self.recipeDetails["image"] as? String ?? "", at: 3)
        }

        // Update the descriptionList with the new data.
        self.descriptionList?.enumerationStyle = .string(descKeys)
        self.descriptionList?.data = descData

        // Reload the UI, so that all cells are visible before changing the edit mode.
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
        self.descriptionList?.reloadData()
        self.updateContentSize()
    }

    /// Update the scrollView contentSize to display all the content.
    @objc func updateContentSize() {
        self.toolsListHeight?.constant = self.toolsList?.contentSize.height ?? 0
        self.descriptionListHeight?.constant = self.descriptionList?.contentSize.height ?? 0
        self.ingredientsListHeight?.constant = self.ingredientsList?.contentSize.height ?? 0
        self.instructionsListHeight?.constant = self.instructionsList?.contentSize.height ?? 0

        self.updateViewConstraints()
    }

    // MARK: - View handling

    private func configureLists() {
        // Configure the lists.
        self.toolsList?.title = NSLocalizedString("TOOLS", comment: "")
        self.ingredientsList?.title = NSLocalizedString("INGREDIENTS", comment: "")
        self.instructionsList?.title = NSLocalizedString("INSTRUCTIONS", comment: "")

        self.toolsList?.enumerationStyle = .bullet()
        self.instructionsList?.enumerationStyle = .number
        self.ingredientsList?.enumerationStyle = .bullet()

        self.toolsList?.allowsCellInsertion = true
        self.ingredientsList?.allowsCellInsertion = true
        self.instructionsList?.allowsCellInsertion = true
        self.toolsList?.allowsCellDeletion = true
        self.ingredientsList?.allowsCellDeletion = true
        self.instructionsList?.allowsCellDeletion = true

        self.descriptionList?.listDelegate = self
        self.toolsList?.listDelegate = self
        self.ingredientsList?.listDelegate = self
        self.instructionsList?.listDelegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.scrollView?.delegate = self
        self.scrollView?.keyboardDismissMode = .interactive

        self.configureLists()

        // Force and update just in case the variables were set before the view was loaded.
        if !self.includeParallaxHeaderView {
            self.includeParallaxHeaderView = false
        }

        if self.isEditable {
            self.isEditable = true
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Change the layout to compact if we resize the window below a width of 500.
        #if targetEnvironment(macCatalyst)
        let useCompact = self.view.frame.width < 500
        self.toolListTrailingRegular.isActive = !useCompact
        self.instructionListTopRegular.isActive = !useCompact
        self.instructionListLeadingRegular.isActive = !useCompact
        self.instructionListTrailingRegular.isActive = !useCompact

        self.toolListTrailingCompact.isActive = useCompact
        self.instructionListTopCompact.isActive = useCompact
        self.instructionListLeadingCompact.isActive = useCompact
        self.instructionListTrailingCompact.isActive = useCompact
        #endif

        self.updateContentSize()
    }

    // MARK: - NotificationCenter Callbacks

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Register NotificationCenter callbacks.
        let center = NotificationCenter.default
        self.logoutObserver = center.addObserver(forName: .logout, object: nil, queue: .main) { [weak self] _ in
            self?.recipe = nil
        }
        self.reloadObserver = center.addObserver(forName: .reload, object: nil, queue: .main) { [weak self] _ in
            self?.recipe = nil
        }

        // After all data is loaded we need to relayout the UI.
        center.addObserver(self, selector: #selector(self.didLoadRecipeDetails),
                           name: .didLoadRecipeDetails, object: nil)
        center.addObserver(self, selector: #selector(self.didEditRecipe), name: .didEditRecipe, object: nil)
        center.addObserver(self, selector: #selector(self.didRemoveRecipe), name: .didRemoveRecipe, object: nil)

        #if !targetEnvironment(macCatalyst)
        // Add observers for the keyboard show / hide events.
        center.addObserver(self, selector: #selector(self.keyboardDidShow),
                           name: UIResponder.keyboardDidShowNotification, object: nil)
        center.addObserver(self, selector: #selector(self.keyboardDidHide),
                           name: UIResponder.keyboardDidHideNotification, object: nil)
        #endif
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Edit mode will end if the view disappears.
        if self.isEditable {
            NotificationCenter.default.post(name: .didEditRecipe, object: self, userInfo: nil)
        }

        // Remove notification listener
        let center = NotificationCenter.default
        if let observer = self.logoutObserver { center.removeObserver(observer) }
        if let observer = self.reloadObserver { center.removeObserver(observer) }
        center.removeObserver(self, name: .didLoadRecipeDetails, object: nil)
        center.removeObserver(self, name: .willLoadRecipeDetails, object: nil)
        center.removeObserver(self, name: .didEditRecipe, object: nil)
        center.removeObserver(self, name: .didRemoveRecipe, object: nil)

        #if !targetEnvironment(macCatalyst)
        center.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: nil)
        center.removeObserver(self, name: UIResponder.keyboardDidHideNotification, object: nil)
        #endif
    }
}

// MARK: - UIScrollViewDelegate
extension RecipeDetailViewController: UIScrollViewDelegate {
    /// Add a parallax effect when scrolling
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let yOff = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
        if var frame = self.parallaxHeaderImageView?.layer.frame {
            frame.origin.y = min(yOff, 0)
            frame.size.height = self.initialParallaxHeight + max(-yOff, 0)
            self.parallaxHeaderImageView?.layer.frame = frame
        }
    }
}

// MARK: - EnumerationListDelegate
extension RecipeDetailViewController: EnumerationListDelegate {
    func enumerationList(_ list: EnumerationList, heightChanged: CGFloat) {
        self.updateContentSize()
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()

        // If the entered text changed or a tool / instruction / ingredient was added resize the scrollView.
        #if !targetEnvironment(macCatalyst)
        self.makeFirstResponderVisible(keyboardFrame: nil)
        #endif
    }
}
