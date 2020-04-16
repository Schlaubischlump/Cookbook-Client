//
//  MasterViewController.swift
//  Cookbook
//
//  Created by David Klopp on 22.12.19.
//  Copyright © 2019 David Klopp. All rights reserved.
//
import UIKit
import Alamofire
import AlamofireImage

// MARK: - Helper
let kErrorHudDisplayDuration = 1.5

// MARK: - RecipesViewController

class RecipesViewController: UITableViewController {
    /// Presented viewcontroller when a new recipe should be created.
    var newRecipeController: RecipeDetailViewController?
    /// Presented viewcontroller when the user needs to login.
    var loginViewController: NextCloudLoginController?

    /// The searchcontroller instance to filter the recipes in the tableView based on their names.
    let searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.placeholder = NSLocalizedString("SEARCH_RECIPES", comment: "")
        return searchController
    }()

    /// All unfiltered recipes, ignoring the currently active search.
    var recipes: [Recipe] = []

    /// Filtered data which is displayed inside the tableView, respecting the active search.
    var filteredRecipes: [Recipe] = []

    /// First row to select when the tableView appears. Set this to a nil, to not select any cell.
    var firstSelectedRow: Int? = 0

    /// Reload the recipe data on viewWillAppear. This property is useful to prevent a reload when the sidebar changes
    /// its collapsed state.
    var reloadRecipesOnViewWillAppear: Bool = false

    /// Open the next recipeDetailViewController in edit mode.
    var openNextRecipeDetailViewInEditMode: Bool = false

    // MARK: - View handling
    override func viewDidLoad() {
        super.viewDidLoad()

        // Customize appearance.
        self.view.backgroundColor = .systemBackground

        // Add drag and drop support.
        self.tableView.dragDelegate = self

        // Add a searchController with the corresponding searchbar.
        self.definesPresentationContext = true
        self.searchController.searchResultsUpdater = self
        self.navigationItem.searchController = self.searchController

        self.tableView.rowHeight = 80.0

        #if targetEnvironment(macCatalyst)
        // Always display the navigation bar.
        self.navigationItem.hidesSearchBarWhenScrolling = false
        // Add a fake title to make the UI look a little bit nicer on macOS.
        self.navigationItem.leftBarButtonItem = UIBarButtonItem.with(kind: .fakeTitle(self.title!))
        self.title = ""
        #else
        // Set the navigationbar title.
        self.navigationController?.navigationBar.prefersLargeTitles = true
        // Add a toolbar item to create new recipe.
        self.navigationController?.isToolbarHidden = false
        self.toolbarItems = [UIBarButtonItem.with(kind: .add, target: self, action: #selector(self.addRecipe))]
        // Add a settings button on the right hand side on iOS.
        navigationItem.rightBarButtonItem = UIBarButtonItem.with(kind: .settings, target: self,
                                                                 action: #selector(self.showPreferencesiOS))
        #endif

        self.reloadRecipesOnViewWillAppear = true
    }

    override func viewWillAppear(_ animated: Bool) {
        // Clear the selection if the viewController is collapsed.
        self.clearsSelectionOnViewWillAppear = self.splitViewController?.isCollapsed ?? true

        super.viewWillAppear(animated)

        // Register NotificationCenter callbacks.
        self.registerNotifications()

        // Try to load the data. We need to be sure that the view hierachy is already created before we call this
        // function. Otherwise our app might crash.
        if self.reloadRecipesOnViewWillAppear {
            self.reloadData(useCachedData: false)
            // Prevent a reload each time the toggle button is clicked.
            self.reloadRecipesOnViewWillAppear = false
        }
    }

    deinit {
        // Do not remove these on viewWillDisappear. Otherwise collapsing the sidebar follwed by a logout will not
        // clear the tableView recipes.
        self.deregisterNotifications()
    }

    // MARK: - NextCloudLogin

    /**
     Show the Nextcloud login view and update the credentials when required.
     */
    func showNextcloudLogin() {
        guard self.loginViewController == nil else { return }

        // Some information is missing, present the login screen to the user with the partial information filled in.
        self.loginViewController = NextCloudLoginController()
        self.loginViewController?.server = loginCredentials.server
        self.loginViewController?.username = loginCredentials.username
        self.loginViewController?.password = loginCredentials.password

        NotificationCenter.default.post(name: .showLoginPrompt, object: nil)

        self.loginViewController?.beginSheetModal(self) { [weak self] response in
            switch response {
            case .login:
                loginCredentials.server = self?.loginViewController?.server
                loginCredentials.username = self?.loginViewController?.username
                loginCredentials.password = self?.loginViewController?.password

                // Attempt to login on all open windows.
                NotificationCenter.default.post(name: .login, object: self)
            default: break
            }
        }
    }

    // MARK: - Segues
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        // Only perform a segue if the current recipe changed, otherwise we can keep the detailController.
        guard let detailController = (self.splitViewController as? SplitViewController)?.recipeDetailController else {
            return true
        }

        if let cell = sender as? UITableViewCell, let indexPath = self.tableView.indexPath(for: cell) {
            return self.filteredRecipes[indexPath.row].recipeID != detailController.recipe?.recipeID
        } else if let indexPath = sender as? IndexPath {
            return self.filteredRecipes[indexPath.row].recipeID != detailController.recipe?.recipeID
        }
        return true
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            guard let indexPath = self.tableView.indexPathForSelectedRow,
                let navController = segue.destination as? UINavigationController,
                let controller = navController.topViewController as? RecipeDetailViewController else { return }
            // Update the detail controller with the recipe info.
            controller.recipe = self.filteredRecipes[indexPath.row]

            // Hide the navigationBar on macOS.
            #if targetEnvironment(macCatalyst)
            navController.navigationBar.isHidden = true
            #else
            // Setup the navigation and toolbar buttons on iOS.
            controller.setupNavigationAndToolbar()

            // Add the display mode button
            controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
            controller.navigationItem.leftItemsSupplementBackButton = true
            #endif

            // We might need to open the view in edit mode.
            controller.startEditModeOnViewDidAppear = self.openNextRecipeDetailViewInEditMode
            self.openNextRecipeDetailViewInEditMode = false
        }
    }

    // MARK: - Table View
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell,
                            forRowAt indexPath: IndexPath) {

        // Do not auto select an item if we are searching or if we explicitly do not want to change the selection.
        guard !self.searchController.searchBar.isFirstResponder, let row = self.firstSelectedRow else { return }

        // Only when we display the last cell. viewDidAppear is not called often enough for this, so we use
        // `willDisplayCell`. We want to execute this function only once. In this case we just choose the last cell.
        if indexPath.row == tableView.indexPathsForVisibleRows?.last?.row {
            // If both views are visible select the first item if possible, but only if none is currently selected.
            guard tableView.indexPathForSelectedRow == nil else { return }
            // This prevents opening the first item when the app launches on an iPhone.
            if self.splitViewController?.displayMode == .allVisible && !self.splitViewController!.isCollapsed {
                self.tableView.becomeFirstResponder()

                let firstIndexPath = IndexPath(row: row, section: 0)
                self.tableView.selectRow(at: firstIndexPath, animated: false, scrollPosition: .none)

                let identifier = "showDetail"
                if self.shouldPerformSegue(withIdentifier: identifier, sender: firstIndexPath) {
                    self.performSegue(withIdentifier: identifier, sender: nil)
                }
            }
        }
    }

    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell,
                            forRowAt indexPath: IndexPath) {
        // Stop loading the image if the cell disappears.
        guard let recipeCell = cell as? RecipesTableViewCell else { return }

        // Save some memory.
        recipeCell.label.text = nil

        // Cancel any running thumbnail download request.
        if let receipt = recipeCell.imageLoadingRequestReceipt {
            ImageDownloader.default.cancelRequest(with: receipt)
            recipeCell.imageLoadingRequestReceipt = nil
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filteredRecipes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        if let recipeCell = cell as? RecipesTableViewCell {
            let recipe = self.filteredRecipes[indexPath.row]
            recipeCell.label.text = recipe.name
            recipeCell.selectedColor = self.view.tintColor.withAlphaComponent(0.5)
            recipeCell.showLineSeparator = (indexPath.row != 0)

            if let image = recipe.thumbnail {
                // Check if we have a cached thumbnail image and if so use it. We should not rely on AlamoreFireImage's
                // caching.
                recipeCell.thumbnail.image = image
            } else {
                // Load image asynchronous.
                recipeCell.imageLoadingRequestReceipt = recipe.loadImage(completionHandler: { image in
                    // Resize image to fill the height and redraw the UI.
                    recipeCell.thumbnail.image = image ?? #imageLiteral(resourceName: "placeholder_thumb")
                    recipeCell.setNeedsLayout()
                })
            }
        }
        return cell
    }
}
