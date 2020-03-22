//
//  ReloadableViewController.swift
//  Cookbook
//
//  Created by David Klopp on 21.03.20.
//  Copyright © 2020 David Klopp. All rights reserved.
//

import Foundation

protocol ReloadableViewController {
    /**
     Reload the UI without reloading the actual backend data.
     */
    func reloadDataFromCache()
    /**
     Reload the backend data and update the UI.
     */
    func reloadDataFromServer()
    /**
     Reload the data from the server or the cache depending on the flag.
     */
    func reloadData(useCachedData: Bool)
}
