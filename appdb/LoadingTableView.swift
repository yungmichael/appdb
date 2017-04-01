//
//  LoadingTableView.swift
//  appdb
//
//  Created by ned on 06/01/2017.
//  Copyright © 2017 ned. All rights reserved.
//

import UIKit
import Cartography

/*
 *    USAGE FOR FUTURE NED
 *    subclass LoadingTableView, set state.
 *
 *    STATES:
 *      .loading to make spinner appear in center (make sure to return 0 cells)
 *      .done to hide spinner and reload data
 *      use showErrorMessage() to trigger state .error, which will display error message in center
 *
 *    ADDITIONAL PROPERTIES:
 *      animated - enable/disable bounce on reload
 *      showsErrorButton - enable/disable retry button in .error
 *
 */

class LoadingTableView: UITableViewController {
    
    var animated: Bool = false
    var showsErrorButton: Bool = true
    
    enum State {
        case done
        case loading
        case error
    }
    
    var state: State = .done {
        didSet {
            switch state {
            case .done:
                activityIndicator.stopAnimating()
                tableView.isScrollEnabled = true
                tableView.reloadData()
                
                if animated {
                    // Bounce animation
                    self.view.transform = CGAffineTransform.identity.scaledBy(x: 0.96, y: 0.96)
                    UIView.animate(withDuration: 0.2, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                        self.view.transform = CGAffineTransform.identity.scaledBy(x: 1.01, y: 1.01)
                    }, completion: { _ in
                        UIView.animate(withDuration: 0.1, animations: {
                            self.view.transform = CGAffineTransform.identity.scaledBy(x: 1.0, y: 1.0)
                        }, completion: nil)
                    })
                }
            case .loading:
                // Set Up
                tableView.isScrollEnabled = false
                
                //Set up Activity Indicator View
                activityIndicator = UIActivityIndicatorView()
                activityIndicator.theme_activityIndicatorViewStyle = [.gray, .white]
                activityIndicator.hidesWhenStopped = true
                activityIndicator.startAnimating()
                
                if let refreshButton = refreshButton, let error = errorMessage, let secondary = secondaryErrorMessage {
                    refreshButton.isHidden = true
                    error.isHidden = true
                    secondary.isHidden = true
                }
                
                view.addSubview(activityIndicator)
                
                setConstraints(.loading)
            case .error:
                //Set up Error Message
                errorMessage = UILabel()
                errorMessage.theme_textColor = Color.copyrightText
                errorMessage.font = .systemFont(ofSize: (26~~22))
                errorMessage.numberOfLines = 0
                errorMessage.textAlignment = .center
                errorMessage.isHidden = false
                
                //Set up Secondary Error Message
                secondaryErrorMessage = UILabel()
                secondaryErrorMessage.theme_textColor = Color.copyrightText
                secondaryErrorMessage.font = .systemFont(ofSize: (19~~15))
                secondaryErrorMessage.numberOfLines = 0
                secondaryErrorMessage.textAlignment = .center
                secondaryErrorMessage.isHidden = false
                
                // Set up 'Retry' button
                if showsErrorButton {
                    refreshButton = ButtonFactory.createRetryButton(text: "Retry".localized(), color: Color.copyrightText)
                    refreshButton.isHidden = false
                }
                
                activityIndicator.stopAnimating()
                
                if showsErrorButton { view.addSubview(refreshButton) }
                view.addSubview(errorMessage)
                view.addSubview(secondaryErrorMessage)
                
                setConstraints(.error)
            }
        }
    }
    
    var activityIndicator: UIActivityIndicatorView!
    var errorMessage: UILabel!
    var secondaryErrorMessage: UILabel!
    var refreshButton: UIButton!
    var group = ConstraintGroup()
    
    // MARK: - ViewDidLoad

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Orientation

    func setConstraints(_ state: State) {

        let offset = (navigationController?.navigationBar.frame.size.height ?? 0) + UIApplication.shared.statusBarFrame.height + (tabBarController?.tabBar.frame.height ?? 0)
        
        switch state {
        case .loading:
            constrain(activityIndicator, replace: group) { indicator in
                indicator.centerX == indicator.superview!.centerX
                indicator.centerY == indicator.superview!.centerY - (offset / 2.0)
            }
        case .error:
            if showsErrorButton {
                constrain(errorMessage, secondaryErrorMessage, refreshButton, replace: group) { message, secondaryMessage, button in
                    message.left == message.superview!.left + 30
                    message.right == message.superview!.right - 30
                    message.centerX == message.superview!.centerX
                    message.centerY == message.superview!.centerY - (offset / 2.0) - 35
                    
                    secondaryMessage.left == message.left
                    secondaryMessage.right == message.right
                    secondaryMessage.top == message.bottom + 10
                    
                    button.top == secondaryMessage.bottom + 30
                    button.centerX == button.superview!.centerX
                    button.width == CGFloat(refreshButton.tag + 20)
                }
            } else {
                constrain(errorMessage, secondaryErrorMessage, replace: group) { message, secondaryMessage in
                    message.left == message.superview!.left + 30
                    message.right == message.superview!.right - 30
                    message.centerX == message.superview!.centerX
                    message.centerY == message.superview!.centerY - (offset / 2.0) - 10
                    
                    secondaryMessage.left == message.left
                    secondaryMessage.right == message.right
                    secondaryMessage.top == message.bottom + 10
                }
            }
        default: break
        }
    }
    
    // Update constraints to reflect orientation change
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (context: UIViewControllerTransitionCoordinatorContext!) -> Void in
            if self.state != .done { self.setConstraints(self.state) }
        }, completion: nil)
    }
    
    // MARK: - error Screen
    func showErrorMessage(text: String = "", secondaryText: String = "") {
        state = .error
        secondaryErrorMessage.text = secondaryText
        errorMessage.text = text
    }

}
