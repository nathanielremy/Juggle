//
//  UserProfileVC.swift
//  Juggle
//
//  Created by Nathaniel Remy on 22/07/2018.
//  Copyright © 2018 Nathaniel Remy. All rights reserved.
//

import UIKit
import Firebase

class UserProfileVC: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    //MARK: Stored properties
    var userId: String?
    var user: User?
    var tasks = [Task]()
    var reviews = [Review]()
    var shouldShowTasks: Bool = true
    var rating: Double?
    
    let activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView()
        ai.hidesWhenStopped = true
        ai.color = UIColor.mainBlue()
        ai.translatesAutoresizingMaskIntoConstraints = false
        
        return ai
    }()
    
    let noResultsView: UIView = {
        let view = UIView.noResultsView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.backgroundColor = .white
        collectionView?.register(UserProfileHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: Constants.CollectionViewCellIds.userProfileHeaderCell)
        collectionView?.register(TaskCell.self, forCellWithReuseIdentifier: Constants.CollectionViewCellIds.taskCell)
        collectionView?.register(ReviewCell.self, forCellWithReuseIdentifier: Constants.CollectionViewCellIds.reviewCell)
        
        collectionView?.alwaysBounceVertical = true
        
        // Manualy refresh the collectionView
        let refreshController = UIRefreshControl()
        refreshController.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView?.refreshControl = refreshController
        
        fetchUser()
        fetchUserTasks()
        fetchReviews()
    }
    
    fileprivate func setupSettingsBarButton(forUserId userId: String) {
        if userId == Auth.auth().currentUser?.uid {
            let settingsBarButton = UIBarButtonItem(image: #imageLiteral(resourceName: "gear"), style: .plain, target: self, action: #selector(handleSettingsBarButton))
            settingsBarButton.tintColor = UIColor.mainBlue()
            navigationItem.rightBarButtonItem = settingsBarButton
            return
        } else {
            return
        }
    }
    
    @objc fileprivate func handleSettingsBarButton() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { (_) in
            do {
                try Auth.auth().signOut()
                
                let loginVC = LogInVC()
                let signupNavController = UINavigationController(rootViewController: loginVC)
                self.present(signupNavController, animated: true, completion: nil)
                
            } catch let signOutError {
                print("Failed to sign out: ", signOutError)
            }
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    @objc fileprivate func handleRefresh() {
        fetchUser()
        if shouldShowTasks {
            self.fetchUserTasks()
        } else {
            self.fetchReviews()
        }
    }
    
    fileprivate func fetchUser() {
        let userIdForFetch = self.userId ?? (Auth.auth().currentUser?.uid ?? "")
        
        Database.fetchUserFromUserID(userID: userIdForFetch) { (user) in
            if let user = user {
                self.user = user
                DispatchQueue.main.async {
                    self.setupSettingsBarButton(forUserId: user.uid)
                    self.navigationItem.title = user.fullName
                    self.user = user
                    if self.shouldShowTasks {
                        self.collectionView?.reloadData()
                    }
                }
            }
        }
    }
    
    fileprivate func fetchUserTasks() {
        let userId = self.userId ?? (Auth.auth().currentUser?.uid ?? "")
        
        let databaseRef = Database.database().reference().child(Constants.FirebaseDatabase.tasksRef).child(userId)
        databaseRef.observeSingleEvent(of: .value, with: { (dataSnapshot) in
            
            guard let snapshotDictionary = dataSnapshot.value as? [String : Any] else {
                self.tasks.removeAll()
                if self.shouldShowTasks {
                    self.showNoResultsFoundView()
                }
                print("fetchUserTasks(): Unable to convert to [String:Any]"); return
            }
            
            self.tasks.removeAll()
            
            snapshotDictionary.forEach({ (key, value) in
                guard let postDictionary = value as? [String : Any] else { return }
                let task = Task(id: key, dictionary: postDictionary)
                self.tasks.append(task)
                // Rearrange the tasks array to be from most recent to oldest
                self.tasks.sort(by: { (task1, task2) -> Bool in
                    return task1.creationDate.compare(task2.creationDate) == .orderedDescending
                })
            })
            if self.tasks.isEmpty {
                if self.shouldShowTasks {
                    self.showNoResultsFoundView()
                }
                return
            }
            if self.shouldShowTasks {
                DispatchQueue.main.async {
                    self.removeNoResultsView()
                }
            }
        }) { (error) in
            if self.shouldShowTasks {
                self.showNoResultsFoundView()
            }
            print("fetchUserTasks(): Error fetching user's tasks: ", error)
        }
    }
    
    func fetchReviews() {
        let userId = self.userId ?? (Auth.auth().currentUser?.uid ?? "")
        
        let databaseRef = Database.database().reference().child(Constants.FirebaseDatabase.reviewsRef).child(userId)
        databaseRef.observeSingleEvent(of: .value, with: { (dataSnapshot) in
            
            guard let dictionary = dataSnapshot.value as? [String : Any] else {
                self.reviews.removeAll()
                self.rating = 0
                if self.shouldShowTasks == false {
                    self.showNoResultsFoundView()
                }
                print("fetchReviews(): Unable to convert to [String:Any]"); return
            }
            
            self.reviews.removeAll()
            
            dictionary.forEach({ (key, value) in
                guard let reviewDictionary = value as? [String : Any] else { return }
                let review = Review(id: key, dictionary: reviewDictionary)
                self.reviews.append(review)
                // Rearrange the tasks array to be from most recent to oldest
                self.reviews.sort(by: { (review1, review2) -> Bool in
                    return review1.creationDate.compare(review2.creationDate) == .orderedDescending
                })
            })
            
            if self.reviews.isEmpty {
                self.rating = 0
                if self.shouldShowTasks == false {
                    self.showNoResultsFoundView()
                }
                return
            }
            self.calculateRating()
        }) { (error) in
            if self.shouldShowTasks == false {
                self.showNoResultsFoundView()
            }
            print("FetchReviews() Error: ", error)
        }
    }
    
    func calculateRating() {
        var totalStars: Double = 0
        
        for review in self.reviews {
            totalStars += Double(review.intRating)
        }
        
        let outOfFive = Double(totalStars/Double(reviews.count))
        self.rating = outOfFive
        
        DispatchQueue.main.async {
            self.removeNoResultsView()
        }
    }
    
    fileprivate func showNoResultsFoundView() {
        self.collectionView?.reloadData()
        self.collectionView?.refreshControl?.endRefreshing()
        DispatchQueue.main.async {
            self.collectionView?.addSubview(self.noResultsView)
            self.noResultsView.centerYAnchor.constraint(equalTo: (self.collectionView?.centerYAnchor)!).isActive = true
            self.noResultsView.centerXAnchor.constraint(equalTo: (self.collectionView?.centerXAnchor)!).isActive = true
        }
    }
    
    fileprivate func removeNoResultsView() {
        self.collectionView?.reloadData()
        self.collectionView?.refreshControl?.endRefreshing()
        DispatchQueue.main.async {
            self.noResultsView.removeFromSuperview()
        }
    }
    
    //MARK: UserProfileHeaderCell Methods
    // Add section header for collectionView a supplementary kind
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        guard let headerCell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: Constants.CollectionViewCellIds.userProfileHeaderCell, for: indexPath) as? UserProfileHeader else { fatalError("Unable to dequeue UserProfileHeaderCell")}
        
        headerCell.delegate = self
        headerCell.user = self.user
        headerCell.rating = self.rating
        
        return headerCell
    }
    
    // Need to provide a size or the header will not render out
    // Define the size of the section header for the collectionView
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        return CGSize(width: view.frame.width, height: 308)
    }
    
    //MARK: CollectionView cell methods
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if shouldShowTasks {
            return self.tasks.count
        } else {
            return self.reviews.count
        }
    }
    
    // What's the vertical spacing between each cell ?
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if shouldShowTasks {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.CollectionViewCellIds.taskCell, for: indexPath) as! TaskCell
            cell.task = self.tasks[indexPath.item]
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.CollectionViewCellIds.reviewCell, for: indexPath) as! ReviewCell
            cell.review = self.reviews[indexPath.item]
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if self.shouldShowTasks {
            return CGSize(width: view.frame.width, height: 110)
        } else {
            
            var height: CGFloat = 80
            let review = self.reviews[indexPath.item].reviewString
            
            height = self.estimatedFrameForReviewCell(fromText: review).height + 55
            
            if height < 101 {
                return CGSize(width: view.frame.width, height: 101)
            } else {
                return CGSize(width: view.frame.width, height: height)
            }
        }
    }
    
    fileprivate func estimatedFrameForReviewCell(fromText text: String) -> CGRect {
        //Height must be something really tall and width is the same as chatBubble in ChatMessageCell
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [.font : UIFont.systemFont(ofSize: 16)], context: nil)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.shouldShowTasks {
            let taskDetailsVC = TaskDetailsVC()
            taskDetailsVC.task = self.tasks[indexPath.item]
            
            self.navigationController?.pushViewController(taskDetailsVC, animated: true)
        }
    }
    
    func okayAlert(title: String, message: String) -> UIAlertController {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Okay", style: .cancel , handler: nil)
        alertController.addAction(okAction)
        
        return alertController
    }
}

extension UserProfileVC: UserProfileHeaderDelegate {
    
    func editOrReviewProfile(_ editOrReview: String) {
        if editOrReview == Constants.ButtonTitles.reviewProfile {
            guard let user = self.user else {
                let alert = self.okayAlert(title: "Unable to review this user", message: "There is a problem creating reviews for this user. Try again later.")
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            let reviewProfileVC = ReviewProfileVC()
            reviewProfileVC.user = user
            
            navigationController?.pushViewController(reviewProfileVC, animated: true)
            
        } else if editOrReview == Constants.ButtonTitles.editProfile {
            let editProfileVC = EditProfileVC()
            editProfileVC.user = self.user
            navigationController?.pushViewController(editProfileVC, animated: true)
        }
    }
    
    func didChangeToReviews() {
        if shouldShowTasks {
            self.shouldShowTasks = false
            self.collectionView?.reloadData()
            if self.reviews.isEmpty {
                self.showNoResultsFoundView()
            } else {
                self.removeNoResultsView()
            }
        }
    }
    
    func didChangeToTasks() {
        if !shouldShowTasks {
            self.shouldShowTasks = true
            if self.tasks.isEmpty {
                self.showNoResultsFoundView()
            } else {
                self.removeNoResultsView()
            }
        }
    }
}
