//
//  MessagesVC.swift
//  Juggle
//
//  Created by Nathaniel Remy on 22/07/2018.
//  Copyright © 2018 Nathaniel Remy. All rights reserved.
//

import UIKit
import Firebase

class MessagesVC: UITableViewController {
    
    //MARK: Stored properties
    var messages = [Message]()
    var messagesDictionary = [String : Message]()
    var timer: Timer?
    
    let noResultsView: UIView = {
        let view = UIView.noResultsView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }()
    
    let activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView()
        ai.hidesWhenStopped = true
        ai.color = UIColor.mainBlue()
        ai.translatesAutoresizingMaskIntoConstraints = false
        
        return ai
    }()
    
    fileprivate func showNoResultsFoundView() {
        DispatchQueue.main.async {
            self.tableView?.addSubview(self.noResultsView)
            self.noResultsView.centerYAnchor.constraint(equalTo: (self.tableView?.centerYAnchor)!).isActive = true
            self.noResultsView.centerXAnchor.constraint(equalTo: (self.tableView?.centerXAnchor)!).isActive = true
        }
    }
    
    fileprivate func removeNoResultsView() {
        DispatchQueue.main.async {
            self.noResultsView.removeFromSuperview()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Messages"
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
        
        // Manualy refresh the collectionView
        let refreshController = UIRefreshControl()
        refreshController.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        
        tableView.refreshControl = refreshController
        
        tableView.register(MessageTableViewCell.self, forCellReuseIdentifier: Constants.TableViewCellIds.messageTableViewCell)
        
        
        observeUserMessages()
    }
    
    @objc fileprivate func handleRefresh() {
        observeUserMessages()
    }
    
    fileprivate func observeUserMessages() {
        self.disableAndActivate(true)
        
        guard let currentUserId = Auth.auth().currentUser?.uid else { print("Could not fetch currentUserId"); self.disableAndActivate(false); return }
        
        let ref = Database.database().reference().child(Constants.FirebaseDatabase.userMessagesRef).child(currentUserId)
        self.disableAndActivate(false)
        ref.observe(.childAdded, with: { (snapShot) in
            self.disableAndActivate(true)
            let userId = snapShot.key
            let userRef = Database.database().reference().child(Constants.FirebaseDatabase.userMessagesRef).child(currentUserId).child(userId)
            self.disableAndActivate(false)
            userRef.observe(.childAdded, with: { (snapshot2) in
                self.disableAndActivate(true)
                
                let messageId = snapshot2.key
                self.fetchMessage(withMessageId: messageId)
                
            }, withCancel: { (error) in
                print("Error fetching messages: ", error); self.disableAndActivate(false); return
            })
        }) { (error) in
            print("ERROR: ", error); self.disableAndActivate(false); return
        }
        
        ref.observe(.childRemoved, with: { (snapshot3) in
            self.messagesDictionary.removeValue(forKey: snapshot3.key)
            self.attemptReloadTable()
        }) { (error) in
            print("Error fetching data when child removed: ", error); self.disableAndActivate(false); return
        }
    }
    
    fileprivate func attemptReloadTable() {
        //Solution to only reload tableView once
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.handleReloadTableView), userInfo: nil, repeats: false)
    }
    
    @objc func handleReloadTableView() {
        self.messages = Array(self.messagesDictionary.values)
        self.messages.sort(by: { (msg1, msg2) -> Bool in
            return Double(msg1.timeStamp.timeIntervalSince1970) > Double(msg2.timeStamp.timeIntervalSince1970)
        })
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    fileprivate func fetchMessage(withMessageId messageId: String) {
        let messagesRef = Database.database().reference().child(Constants.FirebaseDatabase.messagesRef).child(messageId)
        self.disableAndActivate(false)
        messagesRef.observeSingleEvent(of: .value, with: { (snapshot) in
            self.disableAndActivate(true)
            guard let dictionary = snapshot.value as? [String : Any] else { print("snapShot not convertible to [String : Any]"); self.disableAndActivate(false); return }
            
            let message = Message(key: snapshot.key, dictionary: dictionary)
            
            //Grouping all messages per user
            if let chatPartnerId = message.chatPartnerId() {
                self.messagesDictionary[chatPartnerId] = message
            }
            
            //Solution to only reload tableView once
            self.attemptReloadTable()
            self.disableAndActivate(false)
            
        }, withCancel: { (error) in
            print("ERROR: ", error); self.disableAndActivate(false); return
        })
    }
    
    func prepareChatController(forUser user: User, indexPath: Int, taskOwner: String) {
        let taskId = self.messages[indexPath].taskId
        
        let taskRef = Database.database().reference().child(Constants.FirebaseDatabase.tasksRef).child(taskOwner).child(taskId)
        taskRef.observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let dictionary = snapshot.value as? [String : Any] else {
                DispatchQueue.main.async {
                    self.disableAndActivate(false)
                }
                self.showChatController(forTask: nil, user: user)
                print("Could not convert snapshot to [String : Any]"); return
            }
            
            let task = Task(id: snapshot.key, dictionary: dictionary)
            self.showChatController(forTask: task, user: user)
            
        }) { (error) in
            print("Error fetching task: ", error); return
        }
    }
    
    func showChatController(forTask task: Task?, user: User) {
        DispatchQueue.main.async {
            self.disableAndActivate(false)
            let chatLogVC = ChatLogVC(collectionViewLayout: UICollectionViewFlowLayout())
            chatLogVC.data = (user, task)
            self.navigationController?.pushViewController(chatLogVC, animated: true)
        }
    }
    
    //MARK: TableView Methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if self.messages.count == 0 {
            self.showNoResultsFoundView()
        } else {
            self.removeNoResultsView()
        }
        
        return self.messages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.TableViewCellIds.messageTableViewCell, for: indexPath) as! MessageTableViewCell
        
        let message = self.messages[indexPath.row]
        
        if let uId = message.chatPartnerId() {
            Database.fetchUserFromUserID(userID: uId) { (userr) in
                guard let user = userr else { print("Could not fetch user from Database"); return }
                DispatchQueue.main.async {
                    cell.message = (message, user)
                    cell.delegate = self
                }
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.disableAndActivate(true)
        let message = self.messages[indexPath.row]
        
        //Select correct user to show in ChatLogVC
        guard let uId = message.chatPartnerId() else {
            self.disableAndActivate(false)
            print("No chat partner Id"); return
        }
        Database.fetchUserFromUserID(userID: uId) { (userr) in
            guard let user = userr else {
                self.disableAndActivate(false)
                print("No user returned from database"); return
            }
            
            DispatchQueue.main.async {
                self.prepareChatController(forUser: user, indexPath: indexPath.row, taskOwner: message.taskOwnerId)
            }
        }
    }
    
    //Enable the tableView to delete messages
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    //What happens when user hits delete
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        guard let currentUserId = Auth.auth().currentUser?.uid else { print("Could not fetch current user Id"); return }
        guard let chatParterId = self.messages[indexPath.row].chatPartnerId() else { print("Could not fetch chatPartnerId"); return }
        
        let deleteRef = Database.database().reference().child(Constants.FirebaseDatabase.userMessagesRef).child(currentUserId).child(chatParterId)
        deleteRef.removeValue { (err, _) in
            if let error = err {
                print("Error deleting value from database: ", error)
                return
            }
            
            self.messagesDictionary.removeValue(forKey: chatParterId)
            self.attemptReloadTable()
        }
    }
    
    func okayAlert(title: String, message: String) -> UIAlertController {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Okay", style: .cancel , handler: nil)
        alertController.addAction(okAction)
        
        return alertController
    }
    
    func disableAndActivate(_ bool: Bool) {
        DispatchQueue.main.async {
            if bool {
                self.activityIndicator.startAnimating()
            } else {
                self.activityIndicator.stopAnimating()
                self.tableView.refreshControl?.endRefreshing()
            }
            self.tableView.isUserInteractionEnabled = !bool
        }
    }
}

extension MessagesVC: MessageTableViewCellDelegate {
    func handleViewTaskButton(forTask task: Task?) {
        if let task = task {
            let taskDetailsVC = TaskDetailsVC()
            taskDetailsVC.task = task
            navigationController?.pushViewController(taskDetailsVC, animated: true)
        } else {
            let alert = self.okayAlert(title: "Unable to view this task", message: "The user has deleted this task")
            self.present(alert, animated: true, completion: nil)
        }
    }
}
