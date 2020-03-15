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
    var detailItem: Recipe? {
        didSet {
            // Update the view.
            configureView()
        }
    }

    /// Recipe details for this detailItem.
    var recipeDetails: [String: Any] = [:] {
        didSet {
            // Populate the gui.
            let (descriptionKeys, descriptionData) = Recipe.parseDescriptionValuesFor(jsonArray: self.recipeDetails)
            self.descriptionList.enumerationStyle = .string(descriptionKeys)
            self.descriptionList.data = descriptionData

            self.toolsList.enumerationStyle = .bullet()
            self.toolsList.data = self.recipeDetails["tool"] as? [String] ?? []

            self.ingredientsList.enumerationStyle = .bullet()
            self.ingredientsList.data = self.recipeDetails["recipeIngredient"]  as? [String] ?? []

            self.instructionsList.enumerationStyle = .number
            self.instructionsList.data = self.recipeDetails["recipeInstructions"]  as? [String] ?? []

            self.updateContentSize()
        }
    }

    private var logoutObserver: NSObjectProtocol?
    private var reloadObserver: NSObjectProtocol?

    // MARK: - Helper

    func configureView() {
        if let detail = detailItem {
            self.title = detailItem?.name

            self.descriptionList?.title = detailItem?.name
            self.toolsList?.title = NSLocalizedString("TOOLS", comment: "")
            self.ingredientsList?.title = NSLocalizedString("INGREDIENTS", comment: "")
            self.instructionsList?.title = NSLocalizedString("INSTRUCTIONS", comment: "")

            // Load the recipe details.
            detail.loadRecipeDetails(completionHandler: { prop in
                self.recipeDetails = prop!
            }, errorHandler: { _ in
                // Show loading recipe details error.
                MBProgressHUD.showError(attachedTo: self.view,
                                        message: NSLocalizedString("ERROR_LOADING_RECIPE_DETAILS", comment: ""),
                                        animated: true)
            })

            // Load the actual image.
            detail.loadImage(completionHandler: {image in
                self.parallaxHeaderImageView.image = image
            }, thumb: false)
        } else if self.isViewLoaded && self.view.window != nil {
            self.title = ""
            self.descriptionList?.title = ""
            self.parallaxHeaderImageView.image = #imageLiteral(resourceName: "placeholder")
            self.descriptionList.data = []
            self.toolsList.data = []
            self.ingredientsList.data = []
            self.instructionsList.data = []
            self.updateContentSize()
        }
    }

    func updateContentSize() {
        self.toolsListHeight.constant = self.toolsList.contentSize.height
        self.descriptionListHeight.constant = self.descriptionList.contentSize.height
        self.ingredientsListHeight.constant = self.ingredientsList.contentSize.height
        self.instructionsListHeight.constant = self.instructionsList.contentSize.height

        super.updateViewConstraints()
    }

    // MARK: - View handling

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = ""

        self.scrollView.delegate = self

        #if targetEnvironment(macCatalyst)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        #endif

        // Do any additional setup after loading the view.
        configureView()
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
            self?.detailItem = nil
        }
        self.reloadObserver = center.addObserver(forName: .reload, object: nil, queue: .main) { [weak self] _ in
            self?.detailItem = nil
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Remove notification listener
        let center = NotificationCenter.default
        if let observer = self.logoutObserver {
            center.removeObserver(observer)
        }
        if let observer = self.reloadObserver {
            center.removeObserver(observer)
        }
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
