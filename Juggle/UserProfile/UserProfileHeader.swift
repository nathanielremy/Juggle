//
//  UserProfileHeader.swift
//  Juggle
//
//  Created by Nathaniel Remy on 22/07/2018.
//  Copyright © 2018 Nathaniel Remy. All rights reserved.
//

import UIKit
import Firebase

protocol UserProfileHeaderDelegate {
    func didChangeToTasks()
    func didChangeToReviews()
    func editOrReviewProfile(_ editOrReview: String)
}

class UserProfileHeader: UICollectionViewCell {
    
    //MARK: Stored properties
    var delegate: UserProfileHeaderDelegate?
    var isTasksView = true
    
    var user: User? {
        didSet {
            guard let user = user else {
                print("UserProfileHeader/user?: NO USER...")
                return
            }
            profileImageView.loadImage(from: user.profileImageURLString)
            fullNameLabel.text = user.fullName
            
            if user.uid == Auth.auth().currentUser?.uid {
                self.editProfileOrReviewButton.setTitle(Constants.ButtonTitles.editProfile, for: .normal)
            } else {
                self.editProfileOrReviewButton.setTitle(Constants.ButtonTitles.reviewProfile, for: .normal)
            }
        }
    }
    
    var rating: Double? {
        didSet {
            guard let rating = rating else { print("UserProfileHeader/rating?: No rating"); return}
            modifyStars(withRating: rating)
        }
    }
    
    func modifyStars(withRating rating: Double) {
        let stars = UIView.ratingImage(fromRating: rating)
        starView.image = stars
    }
    
    let starView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = #imageLiteral(resourceName: "zeroStarRating").withRenderingMode(.alwaysOriginal)
        
        return imageView
    }()
    
    let profileImageView: CustomImageView = {
        let image = CustomImageView()
        image.backgroundColor = .lightGray
        image.clipsToBounds = true
        image.contentMode = .scaleAspectFill
        image.layer.borderColor = UIColor.mainBlue().cgColor
        image.layer.borderWidth = 1.5
        
        return image
    }()
    
    let fullNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textAlignment = .center
        
        return label
    }()
    
    lazy var editProfileOrReviewButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitleColor(UIColor.mainBlue(), for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.layer.borderColor = UIColor.mainBlue().cgColor
        button.layer.cornerRadius = 5
        button.layer.borderWidth = 1
        button.addTarget(self, action: #selector(handleEditProfileOrReviewButton), for: .touchUpInside)
        
        return button
    }()
    
    @objc fileprivate func handleEditProfileOrReviewButton() {
        if editProfileOrReviewButton.titleLabel?.text == Constants.ButtonTitles.editProfile {
            print("Edit profile")
            delegate?.editOrReviewProfile(Constants.ButtonTitles.editProfile)
        } else if editProfileOrReviewButton.titleLabel?.text == Constants.ButtonTitles.reviewProfile {
            print("Review profile")
            delegate?.editOrReviewProfile(Constants.ButtonTitles.reviewProfile)
        }
    }
    
    lazy var tasksButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor.mainBlue()
        button.setTitle("Tasks", for: .normal)
        button.tintColor = .white
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.addTarget(self, action: #selector(handleTasksButton), for: .touchUpInside)
        
        return button
    }()
    
    @objc func handleTasksButton() {
        if !isTasksView {
            tasksButton.backgroundColor = UIColor.mainBlue()
            reviewsButton.backgroundColor = UIColor.mainBlue().withAlphaComponent(0.4)
            self.delegate?.didChangeToTasks()
            
            isTasksView = true
        }
    }
    
    lazy var reviewsButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor.mainBlue().withAlphaComponent(0.4)
        button.setTitle("Reviews", for: .normal)
        button.tintColor = .white
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.addTarget(self, action: #selector(handleReviewsButton), for: .touchUpInside)
        
        return button
    }()
    
    @objc func handleReviewsButton() {
        if isTasksView {
            tasksButton.backgroundColor = UIColor.mainBlue().withAlphaComponent(0.4)
            reviewsButton.backgroundColor = UIColor.mainBlue()
            self.delegate?.didChangeToReviews()
            
            isTasksView = false
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        
        setupStarStack()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate func setupStarStack() {
        addSubview(starView)
        starView.anchor(top: safeAreaLayoutGuide.topAnchor, left: nil, bottom: nil, right: nil, paddingTop: 15, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 190, height: 45)
        starView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        
        setupViews()
    }
    
    fileprivate func setupViews() {
        addSubview(profileImageView)
        profileImageView.anchor(top: starView.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 20, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 100, height: 100)
        profileImageView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        profileImageView.layer.cornerRadius = 100/2
        
        addSubview(fullNameLabel)
        fullNameLabel.anchor(top: profileImageView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 20, paddingBottom: 0, paddingRight: -20, width: nil, height: 50)
        
        addSubview(editProfileOrReviewButton)
        editProfileOrReviewButton.anchor(top: fullNameLabel.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 150, height: 34)
        editProfileOrReviewButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        
        setupBottomToolBar()
    }
    
    // Setup tool bar for changing between user reviews and tasks
    fileprivate func setupBottomToolBar() {
        let topDivider = UIView()
        topDivider.backgroundColor = UIColor.mainBlue()
        
        let bottomDivider = UIView()
        bottomDivider.backgroundColor = UIColor.mainBlue()
        
        let stackView = UIStackView(arrangedSubviews: [tasksButton, reviewsButton])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        
        addSubview(stackView)
        addSubview(topDivider)
        addSubview(bottomDivider)
        
        stackView.anchor(top: nil, left: leftAnchor, bottom: self.bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: nil, height: 35)
        
        topDivider.anchor(top: stackView.topAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: nil, height: 0.5)
        
        bottomDivider.anchor(top: nil, left: leftAnchor, bottom: stackView.bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: nil, height: 0.5)
    }
}
