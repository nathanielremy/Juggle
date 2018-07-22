//
//  MainTabBarController.swift
//  Juggle
//
//  Created by Nathaniel Remy on 22/07/2018.
//  Copyright © 2018 Nathaniel Remy. All rights reserved.
//

import UIKit
import Firebase

class MainTabBarController: UITabBarController, UITabBarControllerDelegate {
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        
        let index = viewControllers?.index(of: viewController)
        
        if index == 1 {
            let categoryPicker = TaskCategoryPickerVC(collectionViewLayout: UICollectionViewFlowLayout())
            let categoryPickerNavController = UINavigationController(rootViewController: categoryPicker)
            
            present(categoryPickerNavController, animated: true, completion: nil)
            
            return false
        } else {
            return true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = self
        
        if Auth.auth().currentUser == nil {
            // Show LogInVC if user is not signed in
            DispatchQueue.main.async {
                let logInVC = LogInVC()
                let navController = UINavigationController(rootViewController: logInVC)
                self.present(navController, animated: true, completion: nil)
                return
            }
        } else {
            // Set up TabBarViewControllers if user is signed in
            setupViewControllers()
        }
    }
    
    func setupViewControllers() {
        // User profile
        let userNavController = templateNavController(unselectedImage: #imageLiteral(resourceName: "profile_unselected"), selectedImage: #imageLiteral(resourceName: "profile_unselected"), rootViewController: UserProfileVC(collectionViewLayout: UICollectionViewFlowLayout()))
        
        // Messages VC
        let messagesNavController = templateNavController(unselectedImage: #imageLiteral(resourceName: "comment"), selectedImage: #imageLiteral(resourceName: "comment"), rootViewController: MessagesVC())
        
        // Post
        let postNavController = templateNavController(unselectedImage: #imageLiteral(resourceName: "plus_unselected"), selectedImage: #imageLiteral(resourceName: "plus_unselected"))
        
        // View tasks
        let viewTasksNavController = templateNavController(unselectedImage: #imageLiteral(resourceName: "home_unselected"), selectedImage: #imageLiteral(resourceName: "home_unselected"), rootViewController: ViewTasksVC(collectionViewLayout: UICollectionViewFlowLayout()))
        
        tabBar.tintColor = UIColor.mainBlue()
        self.viewControllers = [
            viewTasksNavController,
            postNavController,
            messagesNavController,
            userNavController
        ]
    }
    
    fileprivate func templateNavController(unselectedImage: UIImage, selectedImage: UIImage, rootViewController: UIViewController = UIViewController()) -> UINavigationController {
        let vC = rootViewController
        let navVC = UINavigationController(rootViewController: vC)
        navVC.tabBarItem.image = unselectedImage
        navVC.tabBarItem.selectedImage = selectedImage
        
        return navVC
    }
}
