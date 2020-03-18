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
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var contentView: UIView!

    /// parallax header image view
    @IBOutlet var parallaxHeaderImageView: UIImageView!

    /// header image view top / height constraint
    @IBOutlet var parallaxHeightConstraint: NSLayoutConstraint!
    @IBOutlet var parallaxTopConstraint: NSLayoutConstraint!

    /// List with general information about the recipe
    @IBOutlet var descriptionList: EnumerationList!
    @IBOutlet var descriptionListHeight: NSLayoutConstraint!

    /// List with all tools required.
    @IBOutlet var toolsList: EnumerationList!
    @IBOutlet var toolsListHeight: NSLayoutConstraint!

    /// List with all ingredients.
    @IBOutlet var ingredientsList: EnumerationList!
    @IBOutlet var ingredientsListHeight: NSLayoutConstraint!

    /// List with all instructions.
    @IBOutlet var instructionsList: EnumerationList!
    @IBOutlet var instructionsListHeight: NSLayoutConstraint!

    /// Initital height of the parallax image view.
    lazy var initialParallaxHeight: CGFloat = {
        return self.parallaxHeightConstraint.constant
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
                print("[Info:] Recipe changed: ", self.recipe?.name)
                self.reloadData(useCachedData: false)
            }
        }
    }

    /// Recipe details for this detailItem.
    var recipeDetails: [String: Any] = [:]

    /// Edit the view.
    var isEditable: Bool = false {
        didSet {
            if self.isEditable {
                // Show all available description fields.
                self.reloadRecipeDescriptionList(includeAllFields: true)

                // Start editing the view.
                self.descriptionList.isEditable = true
                self.ingredientsList.isEditable = true
                self.instructionsList.isEditable = true
                self.toolsList.isEditable = true
            } else {
                // Write all the data entered in the UI back to the datastructure.
                self.descriptionList.isEditable = false
                self.ingredientsList.isEditable = false
                self.instructionsList.isEditable = false
                self.toolsList.isEditable = false

                // Update the recipeDetails to represent the new data.
                self.updateRecipeDetailsFromUI()

                // Change the name according to newly entered values.
                self.title = self.recipe?.name
                self.descriptionList?.title = self.recipe?.name

                let recipesController = (self.splitViewController as? SplitViewController)?.recipesMasterController
                recipesController?.reloadVisibleTitles()

                // Update the server information and reload the corresponding full size and thumb image for this recipe.
                self.recipe?.update(self.recipeDetails, completionHandler: {
                    // Update the full size image.
                    self.recipe?.loadImage(completionHandler: {[weak self] image in
                        guard let view = self?.parallaxHeaderImageView else { return }
                        UIView.transition(with: view, duration: 0.25, options: .transitionCrossDissolve, animations: {
                            view.image = image
                        })
                    }, thumb: false)

                    // Update the thumb image in the sidebar.
                    recipesController?.reloadVisibleThumbImages()
                }, errorHandler: { _ in
                    // Inform the user that the update operation did not work.
                    ProgressHUD.showError(attachedTo: self.view,
                                          message: NSLocalizedString("ERROR_UPDATING", comment: ""),
                                          animated: true)?.hide(animated: true, afterDelay: kErrorHudDisplayDuration)
                })

                // Load the new recipeDetails.
                self.reloadRecipeDescriptionList(includeAllFields: false)
            }

        }
    }

    private var logoutObserver: NSObjectProtocol?
    private var reloadObserver: NSObjectProtocol?

    #if !targetEnvironment(macCatalyst)
    private var keyboardShowObserver: NSObjectProtocol?
    private var keyboardHideObserver: NSObjectProtocol?
    #endif

    // MARK: - Helper

    /**
     Update the recipe description list. If `includeAllFields` is true, the description list will include entries
     with an empty value as well as an additional field for `image` and `name`.
     - Parameter includeAllFields: show all avaiable fields
     */
    func reloadRecipeDescriptionList(includeAllFields: Bool = false) {
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
        self.descriptionList.enumerationStyle = .string(descKeys)
        self.descriptionList.data = descData

        // Reload the UI, so that all cells are visible before changing the edit mode.
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
        self.descriptionList.reloadData()
        self.updateContentSize()
    }

    /// The recipeDetails will be updated to match the currently displayed values.
    func updateRecipeDetailsFromUI() {
        let name = self.descriptionList.data[0]
        self.recipeDetails["name"] = name
        self.recipeDetails["description"] = self.descriptionList.data[1]
        self.recipeDetails["url"] = self.descriptionList.data[2]
        self.recipeDetails["image"] = self.descriptionList.data[3]
        self.recipeDetails["prepTime"] = self.descriptionList.data[4].iso8601()
        self.recipeDetails["cookTime"] = self.descriptionList.data[5].iso8601()
        self.recipeDetails["totalTime"] = self.descriptionList.data[6].iso8601()
        self.recipeDetails["recipeYield"] = self.descriptionList.data[7].intValue

        self.recipeDetails["tool"] = self.toolsList.data
        self.recipeDetails["recipeIngredient"] = self.ingredientsList.data
        self.recipeDetails["recipeInstructions"] = self.instructionsList.data

        // Update the recipe name.
        self.recipe?.name = name
    }

    /// Update the scrollView contentSize to display all the content.
    func updateContentSize() {
        self.toolsListHeight.constant = self.toolsList.contentSize.height
        self.descriptionListHeight.constant = self.descriptionList.contentSize.height
        self.ingredientsListHeight.constant = self.ingredientsList.contentSize.height
        self.instructionsListHeight.constant = self.instructionsList.contentSize.height

        self.updateViewConstraints()
    }

    // MARK: - View handling

    private func configureLists() {
        // Configure the lists.
        self.toolsList?.title = NSLocalizedString("TOOLS", comment: "")
        self.ingredientsList?.title = NSLocalizedString("INGREDIENTS", comment: "")
        self.instructionsList?.title = NSLocalizedString("INSTRUCTIONS", comment: "")

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

        self.scrollView.delegate = self
        self.scrollView.keyboardDismissMode = .interactive

        #if targetEnvironment(macCatalyst)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        #else

        // Setup the toolbar to add/edit/delte items.
        self.navigationController?.isToolbarHidden = false
        let editButton = BarButtonItem.with(type: .edit)
        editButton.target = self
        editButton.action = #selector(self.editRecipe)
        let deleteButton = BarButtonItem.with(type: .delete)
        deleteButton.target = self
        deleteButton.action = #selector(self.deleteRecipe)
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        self.toolbarItems = [deleteButton, flexibleSpace, editButton]
        #endif

        self.configureLists()
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

        #if !targetEnvironment(macCatalyst)
        // Add a contentInset to the bottom on iOS device when the keyboard appears.
        self.keyboardShowObserver = center.addObserver(forName: UIResponder.keyboardDidShowNotification, object: nil,
                                                       queue: .main, using: { notification in
            if let keyboardHeight = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?
                .cgRectValue.height {
                self.scrollView.contentInset.bottom = keyboardHeight
            }
        })

        // Add a contentInset to the bottom on iOS device when the keyboard appears.
        self.keyboardHideObserver = center.addObserver(forName: UIResponder.keyboardDidHideNotification, object: nil,
                                                       queue: .main, using: { _ in
            self.scrollView.contentInset.bottom = 0
        })
        #endif

        // Fixme: Reload the ui after a small delay... I have no idea why this must be done.
        if self.recipe != nil {
            self.perform( #selector(self.reloadData), with: true, afterDelay: 0.5)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Remove notification listener
        let center = NotificationCenter.default
        if let observer = self.logoutObserver { center.removeObserver(observer) }
        if let observer = self.reloadObserver { center.removeObserver(observer) }

        #if !targetEnvironment(macCatalyst)
        if let observer = self.keyboardShowObserver { center.removeObserver(observer) }
        if let observer = self.keyboardHideObserver { center.removeObserver(observer) }
        #endif
    }
}

// MARK: - UIScrollViewDelegate
extension RecipeDetailViewController: UIScrollViewDelegate {

    /// Add a parallax effect when scrolling
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let yOff = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
        var frame = self.parallaxHeaderImageView.layer.frame
        frame.origin.y = min(yOff, 0)
        frame.size.height = self.initialParallaxHeight + max(-yOff, 0)
        self.parallaxHeaderImageView.layer.frame = frame
    }
}

// MARK: - EnumerationListDelegate
extension RecipeDetailViewController: EnumerationListDelegate {
    func enumerationList(_ list: EnumerationList, heightChanged: CGFloat) {
        self.updateContentSize()
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
    }
}
