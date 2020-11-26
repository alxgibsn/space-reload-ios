//
//  RefreshControlTableViewController.swift
//  SpaceReload
//
//  Created by Alex Gibson on 22/10/2020.
//

import UIKit

class RefreshControlTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.refreshControl = RiveRefreshControl()
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        return cell
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let refreshControl = self.refreshControl as? RiveRefreshControl {
            let offset = scrollView.contentOffset.y
            refreshControl.pulledExtent = offset
        }
    }
    
    override func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if let refreshControl = self.refreshControl as? RiveRefreshControl {
            refreshControl.reset()
        }
    }
}
