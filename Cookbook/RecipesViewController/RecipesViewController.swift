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
import MBProgressHUD

// MARK: - Helper
let kErrorHudDisplayDuration = 1.5
let kMaxWidth: CGFloat = 300

typealias ResultHandler = (Swift.Result<Void, Error>) -> Void

// MARK: - RecipesViewController

class RecipesTableViewCell: UITableViewCell {
    var imageLoadingRequestReceipt: RequestReceipt?
}

class RecipesViewController: UITableViewController {

    // NotificationCenter observer.
    private var logoutObserver: NSObjectProtocol?
    private var reloadObserver: NSObjectProtocol?
    private var loginObserver: NSObjectProtocol?

    let searchController = UISearchController(searchResultsController: nil)
    var filteredRecipes: [Recipe] = []

    var recipes: [Recipe] = []
    /// First row to select when the tableView appears
    var firstSelectedRow: Int = 0
    /// Set this flag to true when opening a new window with drag and drop.
    /// In this case we want to open the detailViewController.
    var isActivatedByNewWindowActivity: Bool = false

    // MARK: - View handling
    override func viewDidLoad() {
        super.viewDidLoad()
        self.splitViewController?.maximumPrimaryColumnWidth = kMaxWidth

        // Add drag and drop support.
        self.tableView.dragDelegate = self

        // Customize appearance.
        self.view.backgroundColor = .systemBackground

        // Add a searchbar.
        self.searchController.searchResultsUpdater = self
        self.searchController.obscuresBackgroundDuringPresentation = false
        self.searchController.hidesNavigationBarDuringPresentation = false
        self.searchController.searchBar.placeholder = NSLocalizedString("SEARCH_RECIPES", comment: "")
        self.navigationItem.searchController = searchController
        self.definesPresentationContext = true

        #if targetEnvironment(macCatalyst)
        self.tableView.contentInset.top = 15.0
        self.tableView.rowHeight = 30.0

        // Add a fake title.
        self.title = ""

        let label = UILabel()
        label.text = NSLocalizedString("RECIPES", comment: "")
        label.textColor = .gray
        label.font = .systemFont(ofSize: UIFont.labelFontSize, weight: .semibold)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: label)

        #else

        // Set the navigationbar title.
        self.title = NSLocalizedString("RECIPES", comment: "")

        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.tableView.rowHeight = 80.0

        // Add a settings button on the right hand side on iOS.
        navigationItem.rightBarButtonItem = self.barButtonForType(.settings)
        #endif

        // Do any additional setup after loading the view.
        //navigationItem.leftBarButtonItem = editButtonItem

        // If the login credentials are available load the data.
        if loginCredentials.informationIsSet() {
            let hud = MBProgressHUD.showSpinner(attachedTo: self.splitViewController?.view)
            self.reloadRecipes { [weak self] result in
                hud?.hide(animated: true)

                switch result {
                case .success:
                    break
                case .failure:
                    // Login information seems to be incorrect => Show login dialog
                    self?.showNextcloudLogin()
                    MBProgressHUD.showError(attachedTo: self?.presentedViewController?.view,
                                            message: NSLocalizedString("ERROR_LOADING_RECIPES", comment: ""),
                                            animated: true)?
                                 .hide(animated: true, afterDelay: kErrorHudDisplayDuration)
                }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        self.clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)

        // Register NotificationCenter callbacks.
        let center = NotificationCenter.default

        // Called after a successfull login.
        self.loginObserver = center.addObserver(forName: .login, object: nil, queue: .main, using: { [weak self] _ in
            // Show progress spinner.
            let hud = MBProgressHUD.showSpinner(attachedTo: self?.presentedViewController?.view)
            self?.reloadRecipes { result in
                hud?.hide(animated: true)

                switch result {
                case .success:
                    // Save the login information for the next time and dismiss the login screen.
                    try? loginCredentials.updateStoredInformation()
                    self?.presentedViewController?.dismiss(animated: true)

                case .failure:
                    // Show an error message
                    MBProgressHUD.showError(attachedTo: self?.presentedViewController?.view,
                                            message: NSLocalizedString("INVALID_LOGIN", comment: ""),
                                            animated: true)?
                                 .hide(animated: true, afterDelay: kErrorHudDisplayDuration)
                }
            }
        })

        // Called after a successfull logout.
        self.logoutObserver = center.addObserver(forName: .logout, object: nil, queue: .main) { [weak self] _ in
            self?.recipes = []
            self?.filteredRecipes = []
            self?.tableView.reloadData()
            self?.showNextcloudLogin()
        }

        // Called to force a reload.
        self.reloadObserver = center.addObserver(forName: .reload, object: nil, queue: .main) { [weak self] _ in
            guard loginCredentials.informationIsSet() else { return }
            // Reload data and show an error if required.
            let hud = MBProgressHUD.showSpinner(attachedTo: self?.splitViewController?.view)
            self?.reloadRecipes { result in
                hud?.hide(animated: true)

                switch result {
                case .success:
                    // Apply the changes only on success.
                    try? loginCredentials.updateStoredInformation()
                case .failure:
                    self?.showNextcloudLogin()
                    MBProgressHUD.showError(attachedTo: self?.presentedViewController?.view,
                                            message: NSLocalizedString("INVALID_LOGIN", comment: ""),
                                            animated: true)?
                                 .hide(animated: true, afterDelay: kErrorHudDisplayDuration)
                }
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Present the login screen if no login information is available
        if !loginCredentials.informationIsSet() {
            self.showNextcloudLogin()
        }
    }

    deinit {
        // Remove notification listener.
        // Do not remove these on viewWillDisappear. Otherwise collapsing the sidebar follwed by a logout will not
        // clear the tableView recipes.
        let center = NotificationCenter.default
        if let observer = self.loginObserver {
            center.removeObserver(observer)
        }
        if let observer = self.logoutObserver {
            center.removeObserver(observer)
        }
        if let observer = self.reloadObserver {
            center.removeObserver(observer)
        }
    }
}

// MARK: - Data loading + login
extension RecipesViewController {
    /**
     Reload all recipes from the server and optinally provide a success/failure handler.
     - Parameter completion: completion handler
     */
    func reloadRecipes(_ completion: @escaping ResultHandler = { _ in }) {
        Recipe.loadRecipes(completionHandler: { recipes in
            self.recipes = recipes
            self.filteredRecipes = recipes
            self.tableView.reloadData()
            // Reload did work.
            completion(Swift.Result.success(()))
        }, errorHandler: { err in
            self.recipes = []
            self.filteredRecipes = []
            self.tableView.reloadData()
            // Reload failed
            completion(Swift.Result.failure(err))
        })
    }

    /**
     Show the Nextcloud login view and update the credentials when required.
     */
    private func showNextcloudLogin() {
        // Some information is missing, present the login screen to the user with the partial information filled in.
        let nextCloudViewController = NextCloudLoginController()
        nextCloudViewController.server = loginCredentials.server
        nextCloudViewController.username = loginCredentials.username
        nextCloudViewController.password = loginCredentials.password

        nextCloudViewController.beginSheetModal(self) { [weak nextCloudViewController] response in
            switch response {
            case .login:
                loginCredentials.server = nextCloudViewController?.server
                loginCredentials.username = nextCloudViewController?.username
                loginCredentials.password = nextCloudViewController?.password

                // Update all open windows.
                NotificationCenter.default.post(name: .login, object: nil)
            default:
                break
            }
        }
    }
}

// MARK: - Segues
extension RecipesViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                guard let navController = segue.destination as? UINavigationController,
                    let controller = navController.topViewController as? RecipeDetailViewController else {
                        return
                }

                let recipe = self.filteredRecipes[indexPath.row]
                controller.detailItem = recipe
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true

                controller.navigationItem.rightBarButtonItem = self.barButtonForType(.share)

                // Set this value, to open the currently selected row, if the search result is cleared, after an item
                // was selected. We need to find the row of the selected item inside the unfiltered tableView.
                self.firstSelectedRow = self.recipes.firstIndex(where: { $0.recipeID == recipe.recipeID }) ?? 0
            }
        }
    }
}

// MARK: - Table View
extension RecipesViewController {
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

        // If both views are visible select the first item if possible and none is currently selected.
        // This prevents opening the first item when the app launches on an iPhone.
        let isSplitViewControllerSeparated = self.splitViewController?.displayMode == .allVisible
            && !self.splitViewController!.isCollapsed

        // Nevertheless we want this to be executed when we open a new window on iPad.
        if isSplitViewControllerSeparated || self.isActivatedByNewWindowActivity {
            // Only when we display the last cell
            if indexPath.row == tableView.indexPathsForVisibleRows?.last?.row {
                self.tableView.becomeFirstResponder()
                self.tableView.selectRow(at: IndexPath(row: self.firstSelectedRow, section: 0),
                                         animated: false, scrollPosition: .none)
                self.performSegue(withIdentifier: "showDetail", sender: nil)
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
        cell.imageView?.image = #imageLiteral(resourceName: "placeholder_thumb").af_imageAspectScaled(toFill: CGSize(width: height, height: height))

        guard let recipeCell = cell as? RecipesTableViewCell  else { return cell }

        // Load image asynchronous.
        recipeCell.imageLoadingRequestReceipt = recipe.loadImage(completionHandler: { image in
            // Resize image to fill the height and redraw the UI.
            recipeCell.imageView?.image = image?.af_imageAspectScaled(toFill: CGSize(width: height, height: height))
            recipeCell.setNeedsLayout()
        })
        return recipeCell
    }
}
