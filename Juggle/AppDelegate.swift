//
//  AppDelegate.swift
//  Juggle
//
//  Created by Nathaniel Remy on 22/07/2018.
//  Copyright © 2018 Nathaniel Remy. All rights reserved.
//

import UIKit
import Firebase
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Configure app to work with Firebase GoogleService-Info.plist file
        FirebaseApp.configure()
        
        // Set MainTabBarController as root view
        window = UIWindow()
        guard let window = window else { fatalError() }
        
        window.rootViewController = MainTabBarController()
        
        attemptRegisteringForAPNS(apllication: application)
        
        return true
    }
    
    fileprivate func attemptRegisteringForAPNS(apllication: UIApplication) {
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        
        //User Notifications Auth
        //For iOS 10 and above
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { (granted, err) in
            if let error = err {
                print("Failed to request Auth: ", error); return
            }
            if granted {
                print("Auth granted")
            } else {
                print("Auth denied")
            }
        }
        
        apllication.registerForRemoteNotifications()
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("Registration Token Received: ", fcmToken)
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("REGISTERED")
    }
    
    //Show push notifications while app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler(.alert)
    }
    
    //Do something when user taps on notifaction
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        
        guard let type = userInfo[Constants.APNS.type] as? String else { return }
        
        if type == Constants.APNS.message {
            guard let taskOwnerId = userInfo[Constants.FirebaseDatabase.taskOwnerId] as? String, let taskId = userInfo[Constants.FirebaseDatabase.taskId] as? String, let chatPartnerId = userInfo[Constants.FirebaseDatabase.fromId] as? String else { return }
            
            prepareChatLog(forTaskId: taskId, taskOwnerId: taskOwnerId, chatPartnerId: chatPartnerId)
            
        } else {
            return
        }
    }
    
    //Fetch user and task to display in ChatLogVC
    fileprivate func prepareChatLog(forTaskId taskId: String, taskOwnerId ownerId: String, chatPartnerId: String) {
        
        Database.fetchUserFromUserID(userID: chatPartnerId) { (userr) in
            guard let user = userr else { return }
            
            let taskRef = Database.database().reference().child(Constants.FirebaseDatabase.tasksRef).child(ownerId).child(taskId)
            taskRef.observeSingleEvent(of: .value, with: { (snapshot) in
                
                guard let dictionary = snapshot.value as? [String : Any] else {
                    return
                }
                
                let task = Task(id: snapshot.key, dictionary: dictionary)
                self.showChatLog(forTask: task, user: user)
                
            }) { (error) in
                print("Error fetching task: ", error); return
            }
        }
    }
    
    //Show ChatLogVC
    fileprivate func showChatLog(forTask task: Task, user: User) {
        let chatLogVC = ChatLogVC(collectionViewLayout: UICollectionViewFlowLayout())
        chatLogVC.data = (user, task)
        
        if let mainTabBarController = self.window?.rootViewController as? MainTabBarController {
            mainTabBarController.selectedIndex = 0
            mainTabBarController.presentedViewController?.dismiss(animated: true, completion: nil)
            
            if let homeNavController = mainTabBarController.viewControllers?.first as? UINavigationController {
                homeNavController.pushViewController(chatLogVC, animated: true) //Present ChatLogVC
            } else {
                return
            }
        } else {
            return
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}
