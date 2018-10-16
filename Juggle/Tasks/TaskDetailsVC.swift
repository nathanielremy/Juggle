//
//  TaskDetailsVC.swift
//  Juggle
//
//  Created by Nathaniel Remy on 22/07/2018.
//  Copyright © 2018 Nathaniel Remy. All rights reserved.
//

import UIKit
import Firebase
import MapKit

class TaskDetailsVC: UIViewController {
    
    fileprivate func fetchUser(uid: String) {
        Database.fetchUserFromUserID(userID: uid) { (user) in
            if let user = user {
                self.user = user
                DispatchQueue.main.async {
                    self.profileIageView.loadImage(from: user.profileImageURLString)
                    self.fullNameLabel.text = user.fullName
                }
            }
        }
    }
    
    fileprivate func fetchReviewsFor(userId: String) {
        let databaseRef = Database.database().reference().child(Constants.FirebaseDatabase.reviewsRef).child(userId)
        databaseRef.observeSingleEvent(of: .value, with: { (dataSnapshot) in
            guard let reviewDictionary = dataSnapshot.value as? [String : Any] else {
                self.updateStarView(forRating: 0)
                return
            }
            
            reviewDictionary.forEach({ (key, value) in
                guard let dictionary = value as? [String : Any] else { self.updateStarView(forRating: 0); return }
                let review = Review(id: key, dictionary: dictionary)
                self.reviews.append(review)
            })
            
            self.calculateReviewRating()
            
        }) { (error) in
            print("TaskDetailsVC/fetchReviewsFor: Could not load reviews.")
        }
    }
    
    fileprivate func calculateReviewRating() {
        if self.reviews.isEmpty {
            updateStarView(forRating: 0); return
        }
        
        var totalStars: Double = 0
        
        for review in self.reviews {
            totalStars += Double(review.intRating)
        }
        
        let outOfFive = Double(totalStars/Double(reviews.count))
        self.updateStarView(forRating: outOfFive)
    }
    
    fileprivate func updateStarView(forRating rating: Double) {
        DispatchQueue.main.async {
            self.starView.image = UIView.ratingImage(fromRating: rating)
        }
    }
    
    //MARK: Stored properties
    var reviews = [Review]()
    var user: User?
    var task: Task? {
        didSet {
            guard let task = task else {
                self.navigationController?.popViewController(animated: true)
                return
            }
            fetchUser(uid: task.userId)
            fetchReviewsFor(userId: task.userId)
            self.titleLabel.text = task.title
            self.budgetLabel.attributedText = self.makeAttributedText(withTitle: "Budget (eur):  ", description: String(task.budget))
            self.categoryLabel.attributedText = self.makeAttributedText(withTitle: "Category:  ", description: task.category)
            self.descriptionTextView.text = task.description
            
            if task.isOnline {
                self.locationLabel.attributedText = self.makeAttributedText(withTitle: "Location: ", description: "Online/Phone")
            } else {
                guard let locationString = task.stringLocation else {
                    self.locationLabel.attributedText = self.makeAttributedText(withTitle: "Location: ", description: "Online/Phone")
                    return
                }
                self.viewMapButton.setTitle("View map", for: .normal)
                self.locationLabel.attributedText = self.makeAttributedText(withTitle: "Location: ", description: locationString)
            }
        }
    }
    
    fileprivate func makeAttributedText(withTitle title: String, description: String) -> NSAttributedString {
        let attributedText = NSMutableAttributedString(string: title + " ", attributes: [.font : UIFont.boldSystemFont(ofSize: 16), .foregroundColor : UIColor.mainBlue()])
        attributedText.append(NSAttributedString(string: description, attributes: [.font : UIFont.systemFont(ofSize: 14), .foregroundColor : UIColor.darkText]))
        
        return attributedText
    }
    
    let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.bounces = true
        sv.backgroundColor = .white
        
        return sv
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = UIColor.darkText
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 24)
        return label
    }()
    
    let starView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = #imageLiteral(resourceName: "zeroStarRating").withRenderingMode(.alwaysOriginal)
        
        return imageView
    }()
    
    lazy var profileIageView: CustomImageView = {
        let image = CustomImageView()
        image.backgroundColor = .lightGray
        image.clipsToBounds = true
        image.contentMode = .scaleAspectFill
        image.layer.borderColor = UIColor.mainBlue().cgColor
        image.layer.borderWidth = 1.5
        image.isUserInteractionEnabled = true
        image.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleProfileImageView)))
        
        return image
    }()
    
    @objc fileprivate func handleProfileImageView() {
        guard let profileUser = self.user else {
            DispatchQueue.main.async {
                let alert = self.okayAlert(title: "Unable to load user", message: "Sorry for the inconvenience. Please try again.")
                self.present(alert, animated: true, completion: nil)
            }
            return
        }
        let userProfileVC = UserProfileVC(collectionViewLayout: UICollectionViewFlowLayout())
        userProfileVC.userId = profileUser.uid
        DispatchQueue.main.async {
            self.navigationController?.pushViewController(userProfileVC, animated: true)
        }
    }
    
    let fullNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textAlignment = .center
        label.textColor = .darkText
        
        return label
    }()
    
    lazy var sendMessageButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor.mainBlue()
        button.setTitle("Message", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.tintColor = .white
        button.addTarget(self, action: #selector(handleSendMessageButton), for: .touchUpInside)
        
        return button
    }()
    
    @objc fileprivate func handleSendMessageButton() {
        if let task = self.task, let user = self.user {
            if self.user?.uid == Auth.auth().currentUser?.uid {
                let alert = okayAlert(title: "Cannot Message User", message: "Sorry you are unable to send messages to yourself.")
                self.present(alert, animated: true, completion: nil)
                return
            } else {
                let chatLogVC = ChatLogVC(collectionViewLayout: UICollectionViewFlowLayout())
                chatLogVC.shouldShowCancel = true
                chatLogVC.taskId = task.id
                chatLogVC.taskOwnerId = task.userId
                chatLogVC.data = (user, task)
                let chatLogNavController = UINavigationController(rootViewController: chatLogVC)
                self.present(chatLogNavController, animated: true, completion: nil)
            }
        }
    }
    
    let budgetLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .left
        
        let topSeperatorView = UIView()
        topSeperatorView.backgroundColor = .lightGray
        
        label.addSubview(topSeperatorView)
        topSeperatorView.anchor(top: label.topAnchor, left: label.leftAnchor, bottom: nil, right: label.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: nil, height: 0.5)
        
        return label
    }()
    
    let categoryLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .left
        
        let topSeperatorView = UIView()
        topSeperatorView.backgroundColor = .lightGray
        
        label.addSubview(topSeperatorView)
        topSeperatorView.anchor(top: label.topAnchor, left: label.leftAnchor, bottom: nil, right: label.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: nil, height: 0.5)
        
        return label
    }()
    
    let locationLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .left
        
        return label
    }()
    
    lazy var viewMapButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = UIColor.mainBlue()
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 12)
        button.addTarget(self, action: #selector(handleViewMapButton), for: .touchUpInside)
        
        return button
    }()
    
    @objc fileprivate func handleViewMapButton() {
        guard let task = self.task, let longitude = task.longitude, let latitude = task.latitude else {
            let alert = self.okayAlert(title: "Unable to load map", message: "Please contact the task owner for more details.")
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        let mapView = TaskLocationMapViewVC()
        mapView.coordinnate = coordinate
        navigationController?.pushViewController(mapView, animated: true)
    }
    
    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Description:"
        label.textAlignment = .left
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textColor = UIColor.mainBlue()
        
        return label
    }()
    
    let descriptionTextView: UITextView = {
        let tv = UITextView()
        tv.layer.borderWidth = 0.5
        tv.layer.borderColor = UIColor.lightGray.cgColor
        tv.font = UIFont.systemFont(ofSize: 14)
        tv.isUserInteractionEnabled = false
        
        return tv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationItem.title = "Task Details"
        
        setupViews()
    }
    
    @objc fileprivate func handleOptionsButton() {
        let vC = self
        
        let alert = UIAlertController(title: "Delete This Task?", message: "Are you sure that you want to permanently delete this task?", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { (self) in
            
            guard let task = vC.task else {
                print("No task"); return
            }
            
            //Delete Task from database
            let taskRef = Database.database().reference().child(Constants.FirebaseDatabase.tasksRef).child(task.userId).child(task.id)
            taskRef.removeValue(completionBlock: { (err, _) in
                if let error = err {
                    print("Error deleting task (\(task.id)): ", error)
                }
                DispatchQueue.main.async {
                    vC.navigationController?.popViewController(animated: true)
                }
            })
        }
        alert.addAction(cancelAction)
        alert.addAction(deleteAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    fileprivate func setupViews() {
        view.addSubview(scrollView)
        scrollView.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: nil, height: nil)
        scrollView.contentSize = CGSize(width: view.frame.width, height: 865)
        
        scrollView.addSubview(titleLabel)
        titleLabel.anchor(top: scrollView.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 8, paddingLeft: 20, paddingBottom: 0, paddingRight: -25, width: nil, height: 70)
        
        scrollView.addSubview(starView)
        starView.anchor(top: titleLabel.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 8, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 190, height: 45)
        starView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        
        scrollView.addSubview(profileIageView)
        profileIageView.anchor(top: starView.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 20, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 100, height: 100)
        profileIageView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        profileIageView.layer.cornerRadius = 100 / 2
        
        scrollView.addSubview(fullNameLabel)
        fullNameLabel.anchor(top: profileIageView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: -20, width: nil, height: 50)
        
        scrollView.addSubview(sendMessageButton)
        sendMessageButton.anchor(top: fullNameLabel.bottomAnchor, left: nil , bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 125, height: 35)
        sendMessageButton.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        sendMessageButton.layer.cornerRadius = 16
        
        if self.task?.userId == Auth.auth().currentUser?.uid {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(handleOptionsButton))
        }
        
        setupStackView()
    }
    
    fileprivate func setupStackView() {
        let stackView = UIStackView(arrangedSubviews: [budgetLabel, categoryLabel])
        scrollView.addSubview(stackView)
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 0
        
        stackView.anchor(top: sendMessageButton.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 20, paddingLeft: 20, paddingBottom: 0, paddingRight: -20, width: nil, height: 120)
        
        scrollView.addSubview(viewMapButton)
        viewMapButton.anchor(top: stackView.bottomAnchor, left: nil, bottom: nil, right: stackView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 60, height: 95)
        
        scrollView.addSubview(locationLabel)
        locationLabel.anchor(top: stackView.bottomAnchor, left: stackView.leftAnchor, bottom: nil, right: viewMapButton.leftAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: -5, width: nil, height: 95)
        
        let locationSeperatorView = UIView()
        locationSeperatorView.backgroundColor = .lightGray
        
        scrollView.addSubview(locationSeperatorView)
        locationSeperatorView.anchor(top: locationLabel.topAnchor, left: stackView.leftAnchor, bottom: nil, right: stackView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: nil, height: 0.5)
        
        scrollView.addSubview(descriptionLabel)
        descriptionLabel.anchor(top: locationLabel.bottomAnchor, left: stackView.leftAnchor, bottom: nil, right: stackView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: nil, height: 50)
        
        let descriptionSeperatorView = UIView()
        descriptionSeperatorView.backgroundColor = .lightGray
        
        scrollView.addSubview(descriptionSeperatorView)
        descriptionSeperatorView.anchor(top: descriptionLabel.topAnchor, left: stackView.leftAnchor, bottom: nil, right: stackView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: nil, height: 0.5)
        
        scrollView.addSubview(descriptionTextView)
        descriptionTextView.anchor(top: descriptionLabel.bottomAnchor, left: stackView.leftAnchor, bottom: nil, right: stackView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: nil, height: 200)
    }
    
    func okayAlert(title: String, message: String) -> UIAlertController {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Okay", style: .cancel , handler: nil)
        alertController.addAction(okAction)
        
        return alertController
    }
}
