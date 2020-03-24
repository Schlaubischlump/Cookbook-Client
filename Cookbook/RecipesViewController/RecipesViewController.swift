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
let kMaxWidth: CGFloat = 300

// MARK: - RecipesViewController

class RecipesViewController: UITableViewController {
    // Temporary presented viewController.
    var newRecipeController: RecipeDetailViewController?
    var loginViewController: NextCloudLoginController?

    let searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.placeholder = NSLocalizedString("SEARCH_RECIPES", comment: "")
        return searchController
    }()

    /// All unfiltered recipes.
    var recipes: [Recipe] = []

    /// Filtered data which is displayed inside the tableView.
    var filteredRecipes: [Recipe] = []

    /// First row to select when the tableView appears. Set this to a nil, to not select any cell.
    var firstSelectedRow: Int? = 0

    /// Reload the recipe data on viewWillAppear.
    var reloadRecipesOnViewWillAppear: Bool = false

    /// Open the next recipeDetailViewController in edit mode.
    var openNextRecipeDetailViewInEditMode: Bool = false

    // MARK: Constructor

    override init(style: UITableView.Style) {
        super.init(style: style)
        self.setup()
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }

    func setup() {
        self.title = NSLocalizedString("RECIPES", comment: "")
    }

    // MARK: - View handling
    override func viewDidLoad() {
        super.viewDidLoad()
        self.splitViewController?.maximumPrimaryColumnWidth = kMaxWidth

        // Add drag and drop support.
        self.tableView.dragDelegate = self

        // Customize appearance.
        self.view.backgroundColor = .systemBackground

        // Add a searchController with the corresponding searchbar.
        self.definesPresentationContext = true
        self.searchController.searchResultsUpdater = self
        self.navigationItem.searchController = self.searchController

        #if targetEnvironment(macCatalyst)
        // Always display the navigation bar.
        self.navigationItem.hidesSearchBarWhenScrolling = false

        self.tableView.contentInset.top = 15.0
        self.tableView.rowHeight = 30.0

        // Add a fake title to make the UI look a little bit nicer on macOS.
        self.navigationItem.leftBarButtonItem = UIBarButtonItem.with(kind: .fakeTitle(self.title!))
        self.title = ""

        #else

        // Set the navigationbar title.
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.tableView.rowHeight = 80.0

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
        self.clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)

        // Make sure that the new names and images are loaded even on the iPhone.
        // self.tableView.reloadData()

        // Register NotificationCenter callbacks.
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(self.didRemoveRecipe), name: .didRemoveRecipe, object: nil)
        center.addObserver(self, selector: #selector(self.didLoadRecipes), name: .didLoadRecipes, object: nil)
        center.addObserver(self, selector: #selector(self.didEditRecipe), name: .didEditRecipe, object: nil)
        center.addObserver(self, selector: #selector(self.didAddRecipe), name: .didAddRecipe, object: nil)
        center.addObserver(self, selector: #selector(self.didAttemptLogin), name: .login, object: nil)
        center.addObserver(self, selector: #selector(self.requestReload), name: .reload, object: nil)
        center.addObserver(self, selector: #selector(self.didLogout), name: .logout, object: nil)

        // Try to load the data.
        if self.reloadRecipesOnViewWillAppear {
            self.reloadData(useCachedData: false)
            // Prevent a reload each time the toggle button is clicked.
            self.reloadRecipesOnViewWillAppear = false
        }
    }

    deinit {
        // Remove notification listener.
        // Do not remove these on viewWillDisappear. Otherwise collapsing the sidebar follwed by a logout will not
        // clear the tableView recipes.
        let center = NotificationCenter.default
        center.removeObserver(self, name: .didRemoveRecipe, object: nil)
        center.removeObserver(self, name: .didLoadRecipes, object: nil)
        center.removeObserver(self, name: .didEditRecipe, object: nil)
        center.removeObserver(self, name: .didAddRecipe, object: nil)
        center.removeObserver(self, name: .login, object: nil)
        center.removeObserver(self, name: .logout, object: nil)
        center.removeObserver(self, name: .reload, object: nil)
    }
}

// MARK: - NextCloudLogin
extension RecipesViewController {
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
            let recipe = self.filteredRecipes[indexPath.row]
            controller.recipe = recipe

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
        #if targetEnvironment(macCatalyst)
        cell.textLabel?.font = .systemFont(ofSize: UIFont.labelFontSize-1)
        #else
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.font = .boldSystemFont(ofSize: UIFont.labelFontSize)
        #endif

        // Do not auto select an item if we are searching.
        guard !self.searchController.searchBar.isFirstResponder else { return }

        // Only when we display the last cell. viewDidAppear is not called often enough for this, so we use
        // `willDisplayCell`. We want to execute this function only once. In this case we just choose the last cell.
        if indexPath.row == tableView.indexPathsForVisibleRows?.last?.row {
            // If both views are visible select the first item if possible and none is currently selected.
            // This prevents opening the first item when the app launches on an iPhone.
            let isSplitViewControllerSeparated = self.splitViewController?.displayMode == .allVisible
                && !self.splitViewController!.isCollapsed

            // Nevertheless we want this to be executed when we open a new window on iPad.
            if isSplitViewControllerSeparated {
                guard self.firstSelectedRow != nil else { return }

                let indexPath = IndexPath(row: self.firstSelectedRow!, section: 0)
                self.tableView.becomeFirstResponder()
                self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)

                let identifier = "showDetail"
                if self.shouldPerformSegue(withIdentifier: identifier, sender: indexPath) {
                    self.performSegue(withIdentifier: identifier, sender: nil)
                }
            }
        }
    }

    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell,
                            forRowAt indexPath: IndexPath) {
        // Save some memory.
        cell.textLabel?.text = nil

        // Stop loading the image if the cell disappears.
        guard let recipeCell = cell as? RecipesTableViewCell else { return }
        if let receipt = recipeCell.imageLoadingRequestReceipt {
            ImageDownloader.default.cancelRequest(with: receipt)
            recipeCell.imageLoadingRequestReceipt = nil
        }

        // Reset the image
        // cell.imageView?.image = #imageLiteral(resourceName: "placeholder_thumb")
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filteredRecipes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let recipe = self.filteredRecipes[indexPath.row]
        cell.textLabel!.text = recipe.description
        cell.selectionStyle = .blue

        let height = tableView.rowHeight-10
        let currentImage = cell.imageView?.image
        cell.imageView?.image = currentImage?.af_imageAspectScaled(toFill: CGSize(width: height, height: height))

        guard let recipeCell = cell as? RecipesTableViewCell  else { return cell }

        // Load image asynchronous.
        recipeCell.imageLoadingRequestReceipt = recipe.loadImage(completionHandler: { image in
            // Resize image to fill the height and redraw the UI.
            let newImage = image ?? #imageLiteral(resourceName: "placeholder_thumb")
            recipeCell.imageView?.image = newImage.af_imageAspectScaled(toFill: CGSize(width: height, height: height))
            recipeCell.setNeedsLayout()
        })
        return recipeCell
    }
}
