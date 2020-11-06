//
//  TableViewController.swift
//  SpaceReload
//
//  Created by Alex Gibson on 20/10/2020.
//

import UIKit

class TableViewController: UITableViewController {
    
    var refreshView: RefreshView?
    var pendingReset: Bool = false
    let refreshTriggerPullDistance: CGFloat = 180
    let refreshViewExtent: CGFloat = 180

    override func viewDidLoad() {
        super.viewDidLoad()
        refreshView = RefreshView(frameHeight: refreshViewExtent)
        refreshView?.backgroundColor = UIColor.systemPink
        let containerView = UIView()
        containerView.addSubview(refreshView!)
        tableView.backgroundView = containerView
        refreshView?.isPaused = true
    }
    
    func beginRefreshing() {
        UIView.animate(
            withDuration: 0.15,
            delay: 0.0,
            options: [.allowUserInteraction, .beginFromCurrentState],
            animations: {
                self.tableView.contentInset =
                    .init(top: self.refreshViewExtent, left: 0, bottom: 0, right: 0)
                self.tableView.setContentOffset(
                    .init(x: 0, y: -self.refreshViewExtent), animated: true)
                self.refreshView?.isRefreshing = true
        }, completion: { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                self.endRefreshing()
            }
        })
    }

    func endRefreshing() {
        UIView.animate(
            withDuration: 2.3,
            delay: 0.0,
            options: [.beginFromCurrentState]) {
                self.tableView.setContentOffset(.zero, animated: true)
                self.pendingReset = true
        }
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y + topbarHeight
        refreshView?.isPaused = offset >= 0
        refreshView?.pulledExtent = offset
        refreshView?.frame = CGRect(
            x: 0,
            y: topbarHeight,
            width: view.bounds.width,
            height: -offset)
    }
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView.contentOffset.y + topbarHeight < -refreshTriggerPullDistance {
            beginRefreshing()
        }
    }
    
    override func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if pendingReset {
            tableView.contentInset = .zero
            refreshView?.isRefreshing = false
            refreshView?.reset()
            pendingReset = false
        }
    }
}

extension UIViewController {
    var topbarHeight: CGFloat {
        return (view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0.0) +
            (self.navigationController?.navigationBar.frame.height ?? 0.0)
    }
}
