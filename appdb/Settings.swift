//
//  Settings.swift
//  appdb
//
//  Created by ned on 13/03/2018.
//  Copyright © 2018 ned. All rights reserved.
//

import UIKit
import Static
import SafariServices
import RealmSwift
import BulletinBoard

class Settings: TableViewController {
    
    lazy var bulletinManager: BulletinManager = {
        let rootItem: BulletinItem = DeviceLinkIntroBulletins.makeSelectorPage()
        let manager = BulletinManager(rootItem: rootItem)
        manager.theme_backgroundColor = Color.invertedTitle
        return manager
    }()
    
    deinit { NotificationCenter.default.removeObserver(self) }
    
    convenience init() {
        self.init(style: .grouped)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Settings".localized()
        
        tableView.theme_separatorColor = Color.borderColor
        tableView.theme_backgroundColor = Color.tableViewBackgroundColor
        view.theme_backgroundColor = Color.tableViewBackgroundColor
        
        // Hide last separator
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 1))
        
        tableView.rowHeight = 50
        
        // Subscribe to notifications for device linked/unlinked so i can refresh sections
        NotificationCenter.default.addObserver(self, selector: #selector(refreshSources), name: .RefreshSettings, object: nil)
        
        // Register for 3d Touch
        if #available(iOS 9.0, *), traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: tableView)
        }
        
        refreshSources()
        
        // Refresh link code & configuration parameters
        if deviceIsLinked {
            API.getLinkCode(success: {
                API.getConfiguration(success: { [unowned self] in
                    self.refreshSources()
                }) { _ in }
            }) { error in
                // Profile has been removed, so let's deauthorize the app as well
                if error == "NO_DEVICE_LINKED" { self.deauthorize() }
            }
        }
    }
    
    // Deauthorize app (clean link code, token & refresh settings)
    func deauthorize() {
        let realm = try! Realm()
        guard let pref = realm.objects(Preferences.self).first else { return }
        do { try realm.write {
            pref.token = ""
            pref.linkCode = ""
        } } catch { }
        NotificationCenter.default.post(name: .RefreshSettings, object: self, userInfo: ["linked": false])
    }
    
    // Push news controller
    func pushNews() {
        let newsViewController = News()
        if IS_IPAD {
            let nav = DismissableModalNavController(rootViewController: newsViewController)
            nav.modalPresentationStyle = .formSheet
            self.navigationController?.present(nav, animated: true)
        } else {
            self.navigationController?.pushViewController(newsViewController, animated: true)
        }
    }
    
    // Push system status controller
    func pushSystemStatus() {
        let statusViewController = SystemStatus()
        if IS_IPAD {
            let nav = DismissableModalNavController(rootViewController: statusViewController)
            nav.modalPresentationStyle = .formSheet
            self.navigationController?.present(nav, animated: true)
        } else {
            self.navigationController?.pushViewController(statusViewController, animated: true)
        }
    }
    
    // Device Link Bulletin intro
    // Also subscribes to notification requests to open Safari
    func pushDeviceLink() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(openSafari(notification:)), name: .OpenSafari, object: nil)
        
        bulletinManager.prepare()
        bulletinManager.presentBulletin(above: tabBarController ?? self)
    }
    
    // Open Safari from given url via notification
    @objc fileprivate func openSafari(notification: Notification) {
        guard let urlString = notification.userInfo?["URLString"] as? String else { return }
        guard let url = URL(string: urlString) else { return }
        
        // NOTE: SVC causes all sorts of issues when presented from a bulletin
        // so let's just open Safari.app instead
        // 2lazy2fix
        
        UIApplication.shared.openURL(url)
        
        /*if #available(iOS 9.0, *) {
            let svc = SFSafariViewController(url: url)
            bulletinManager.presentAboveBulletin(svc, animated: true, completion: nil)
        } else {
            UIApplication.shared.openURL(url)
        }*/
    }
    
    // Reloads table view
    
    @objc func refreshSources() {
        if deviceIsLinked {
            dataSource.sections = deviceLinkedSections
        } else {
            dataSource.sections = deviceNotLinkedSections
        }
    }
}

// MARK: - 3D Touch

extension Settings: UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = tableView.indexPathForRow(at: location) else { return nil }
        guard let row = dataSource.row(at: location) else { return nil }
        previewingContext.sourceRect = tableView.rectForRow(at: indexPath)
        
        // Wrap it into a UINavigationController to see viewController's title on peek
        switch row.text {
            case "System Status".localized(): return UINavigationController(rootViewController: SystemStatus())
            case "News".localized(): return UINavigationController(rootViewController: News())
            default: return nil
        }
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        // Unwrap it when committing, to make sure it show back button and everything navigation-related
        if let view = (viewControllerToCommit as? UINavigationController)?.viewControllers.first {
            show(view, sender: self)
        }
    }
}