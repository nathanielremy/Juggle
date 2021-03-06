//
//  SignupVC.swift
//  Juggle
//
//  Created by Nathaniel Remy on 22/07/2018.
//  Copyright © 2018 Nathaniel Remy. All rights reserved.
//

import UIKit
import Firebase

class SignUpVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    //MARK: Stored properties
    lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.bounces = true
        sv.backgroundColor = .white
        
        return sv
    }()
    
    let activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView()
        ai.hidesWhenStopped = true
        ai.color = UIColor.mainBlue()
        
        return ai
    }()
    
    let plusPhotoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "plus_photo"), for: .normal)
        button.tintColor = UIColor.mainBlue()
        button.addTarget(self, action: #selector(handlePlusPhoto), for: .touchUpInside)
        
        return button
    }()
    
    // Present the image picker
    @objc func handlePlusPhoto() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.allowsEditing = true
        imagePickerController.delegate = self
        present(imagePickerController, animated: true, completion: nil)
    }
    
    // Set the selected image from image picker as profile picture
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let editedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {

            plusPhotoButton.setImage(editedImage.withRenderingMode(.alwaysOriginal), for: .normal)

        } else if let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {

            plusPhotoButton.setImage(originalImage.withRenderingMode(.alwaysOriginal), for: .normal)
        }

        // Make button perfectly round
        plusPhotoButton.layer.cornerRadius = plusPhotoButton.frame.width / 2
        plusPhotoButton.layer.masksToBounds = true
        plusPhotoButton.layer.borderColor = UIColor.mainBlue().cgColor
        plusPhotoButton.layer.borderWidth = 3

        // Dismiss image picker view
        picker.dismiss(animated: true, completion: nil)
    }
    
    lazy var firstNameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "First Name"
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.borderStyle = .roundedRect
        tf.tintColor = UIColor.mainBlue()
        tf.delegate = self
        tf.addTarget(self, action: #selector(handleTextFieldChanges), for: .editingChanged)
        
        return tf
    }()
    
    lazy var lastNameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Last Name"
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.borderStyle = .roundedRect
        tf.tintColor = UIColor.mainBlue()
        tf.delegate = self
        tf.addTarget(self, action: #selector(handleTextFieldChanges), for: .editingChanged)
        
        return tf
    }()
    
    lazy var emailTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Email Address"
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.borderStyle = .roundedRect
        tf.tintColor = UIColor.mainBlue()
        tf.delegate = self
        tf.addTarget(self, action: #selector(handleTextFieldChanges), for: .editingChanged)
        
        return tf
    }()
    
    lazy var passwordOneTextField: UITextField = {
        let tf = UITextField()
        tf.isSecureTextEntry = true
        tf.placeholder = "Password (atleast 6 characters)"
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.borderStyle = .roundedRect
        tf.tintColor = UIColor.mainBlue()
        tf.delegate = self
        tf.addTarget(self, action: #selector(handleTextFieldChanges), for: .editingChanged)
        
        return tf
    }()
    
    lazy var passwordTwoTextField: UITextField = {
        let tf = UITextField()
        tf.isSecureTextEntry = true
        tf.placeholder = "Re-enter Password"
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.borderStyle = .roundedRect
        tf.tintColor = UIColor.mainBlue()
        tf.delegate = self
        tf.addTarget(self, action: #selector(handleTextFieldChanges), for: .editingChanged)
        
        return tf
    }()
    
    @objc func handleTextFieldChanges() {
        
        let isFormValid = verifyInputFields()
        if isFormValid {
            self.signUpButton.isEnabled = true
            self.signUpButton.backgroundColor = UIColor.mainBlue().withAlphaComponent(1)
        } else {
            self.signUpButton.isEnabled = false
            self.signUpButton.backgroundColor = UIColor.mainBlue().withAlphaComponent(0.3)
        }
    }
    
    fileprivate func verifyInputFields() -> Bool {
        guard firstNameTextField.text?.count ?? 0 > 0 else { return false }
        guard lastNameTextField.text?.count ?? 0 > 0 else { return false }
        guard emailTextField.text?.count ?? 0 > 0 else { return false }
        guard passwordOneTextField.text?.count ?? 0 > 5 else { return false }
        guard passwordTwoTextField.text?.count ?? 0 > 5 else { return false }
        
        return true
    }
    
    let signUpButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign Up", for: .normal)
        button.backgroundColor = UIColor.mainBlue().withAlphaComponent(0.3)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 5
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.addTarget(self, action: #selector(handleSignup), for: .touchUpInside)
        button.isEnabled = false
        
        return button
    }()
    
    fileprivate func display(alert: UIAlertController) {
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @objc fileprivate func handleSignup() {
        self.disableAndActivate(true)
        
        if !verifyInputFields() {
            disableAndActivate(false)
            present(okayAlert(title: "Invalid Forms", message: "Please re-enter your information in the textfields and try again."), animated: true
                , completion: nil)
            return
        }
        
        guard let textFields = approveInputFields() else {
            self.disableAndActivate(false)
            return
        }
        
        Auth.auth().createUser(withEmail: textFields.email, password: textFields.password) { (newUser, err) in
            
            if let error = err {
                if error.localizedDescription == Constants.ErrorDescriptions.unavailableEmail {
                    let alert = self.okayAlert(title: "Email Unavailable", message: "The email address is already in use by another user.")
                    self.display(alert: alert)
                    
                } else if error.localizedDescription == Constants.ErrorDescriptions.networkError {
                    let alert = self.okayAlert(title: "Network Connection Error", message: "Please try connectig to a better network.")
                    self.display(alert: alert)
                    
                } else {
                    let alert = self.okayAlert(title: "Error Logging In", message: "Please verify that you have entered the correct credentials.")
                    self.display(alert: alert)
                }
                
                self.disableAndActivate(false)
                return
            }
            
            guard let user = newUser else {
                DispatchQueue.main.async {
                    self.disableAndActivate(false)
                }
                return
            }
            
            guard let imageData = self.approveProfileImage().jpegData(compressionQuality: 0.2) else {
                DispatchQueue.main.async {
                    self.disableAndActivate(false)
                }
                return
            }
            
            // create a random file name to add profile image to Firebase storage
            let randomFile = UUID().uuidString
            let storageRef = Storage.storage().reference().child(Constants.FirebaseStorage.profileImages).child(randomFile)
            storageRef.putData(imageData, metadata: nil, completion: { (metaData, err) in
                
                if let error = err {
                    print("Error uploading profileImage to storage: ", error)
                    DispatchQueue.main.async {
                        self.disableAndActivate(false)
                    }
                    return
                }
                
                guard let profileImageURLString = metaData?.downloadURL()?.absoluteString else {
                    print("Could not return profileImageURL from storage")
                    DispatchQueue.main.async {
                        self.disableAndActivate(false)
                    }
                    return
                }
                
                guard let fcmToken = Messaging.messaging().fcmToken else {
                    print("Could not generate fcmToken for user")
                    DispatchQueue.main.async {
                        self.disableAndActivate(false)
                    }
                    return
                }
                
                let userValues = [
                    Constants.FirebaseDatabase.emailAddress : textFields.email,
                    Constants.FirebaseDatabase.fullName : textFields.fullName,
                    Constants.FirebaseDatabase.profileImageURLString : profileImageURLString,
                    Constants.APNS.fcmToken : fcmToken
                ]
                let values = [user.uid : userValues]
                
                let databaseRef = Database.database().reference().child(Constants.FirebaseDatabase.usersRef)
                databaseRef.updateChildValues(values, withCompletionBlock: { (err, _) in
                    if let error = err {
                        print("Error saving user info to database: ", error)
                        DispatchQueue.main.async {
                            self.disableAndActivate(false)
                        }
                        return
                    }
                    
                    // Delete and refresh info in mainTabBar controllers
                    guard let mainTabBarController = UIApplication.shared.keyWindow?.rootViewController as? MainTabBarController else { fatalError() }
                    mainTabBarController.setupViewControllers()
                    
                    self.dismiss(animated: true, completion: nil)
                })
            })
        }
    }
    
    fileprivate func approveProfileImage() -> UIImage {
        var image = UIImage()
        
        guard let plusPhotoImage = self.plusPhotoButton.imageView?.image else {
            image = #imageLiteral(resourceName: "default_profile_image")
            return image
        }
        
        if plusPhotoImage == #imageLiteral(resourceName: "plus_photo") {
            image = #imageLiteral(resourceName: "default_profile_image")
            return image
        } else {
            image = plusPhotoImage
            return image
        }
    }
    
    fileprivate func approveInputFields() -> (email: String, password: String, fullName: String)? {
        guard let password1 = passwordOneTextField.text, let password2 = passwordTwoTextField.text else { return nil }
        
        if password1 != password2 {
            let alert = self.okayAlert(title: "Re-enter passwords", message: "Both password text fields must be identical and atleast 6 characters long.")
            self.present(alert, animated: true, completion: nil); return nil
        }
        
        guard let email = emailTextField.text else { return nil }
        guard let firstName = firstNameTextField.text else { return nil }
        guard let lastName = lastNameTextField.text else { return nil }
        
        return (email, password1, firstName + " " + lastName)
    }
    
    let switchToLoginButton: UIButton = {
        let button = UIButton(type: .system)
        
        let attributedTitle = NSMutableAttributedString(string: "Already have an account?  ", attributes: [.font : UIFont.systemFont(ofSize: 14), .foregroundColor : UIColor.lightGray])
        attributedTitle.append(NSAttributedString(string: "Login.", attributes: [.font : UIFont.boldSystemFont(ofSize: 14), .foregroundColor : UIColor.mainBlue()]))
        
        button.setAttributedTitle(attributedTitle, for: .normal)
        button.addTarget(self, action: #selector(handleSwitchToLogin), for: .touchUpInside)
        
        return button
    }()
    
    @objc fileprivate func handleSwitchToLogin() {
        navigationController?.popToRootViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
        
        setupView()
    }
    
    fileprivate func setupView() {
        view.addSubview(scrollView)
        scrollView.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: nil, height: nil)
        scrollView.contentSize = CGSize(width: view.frame.width, height: view.frame.height + 100)
        
        scrollView.addSubview(plusPhotoButton)
        plusPhotoButton.anchor(top: scrollView.topAnchor, left: nil, bottom: nil, right: nil, paddingTop: 20, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 140, height: 140)
        plusPhotoButton.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        
        let stackView = UIStackView(arrangedSubviews: [
            firstNameTextField,
            lastNameTextField,
            emailTextField,
            passwordOneTextField,
            passwordTwoTextField,
            signUpButton
            ])
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        
        scrollView.addSubview(stackView)
        stackView.anchor(top: plusPhotoButton.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 20, paddingLeft: 40, paddingBottom: 0, paddingRight: -40, width: nil, height: 250)
        
        scrollView.addSubview(switchToLoginButton)
        switchToLoginButton.anchor(top: nil, left: view.leftAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: nil, height: 50)
    }
    
    func disableAndActivate(_ bool: Bool) {
        if bool {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
        
        plusPhotoButton.isEnabled = !bool
        firstNameTextField.isEnabled = !bool
        lastNameTextField.isEnabled = !bool
        emailTextField.isEnabled = !bool
        passwordOneTextField.isEnabled = !bool
        passwordTwoTextField.isEnabled = !bool
        signUpButton.isEnabled = !bool
        switchToLoginButton.isEnabled = !bool
    }
    
    func okayAlert(title: String, message: String) -> UIAlertController {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Okay", style: .cancel , handler: nil)
        alertController.addAction(okAction)
        
        return alertController
    }
}

//MARK: UITextFieldDelegate Methods
extension SignUpVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.isFirstResponder {
            textField.resignFirstResponder()
        }
        return true
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}
