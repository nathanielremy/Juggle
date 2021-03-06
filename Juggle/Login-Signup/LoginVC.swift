//
//  LoginVC.swift
//  Juggle
//
//  Created by Nathaniel Remy on 22/07/2018.
//  Copyright © 2018 Nathaniel Remy. All rights reserved.
//

import UIKit
import Firebase

class LogInVC: UIViewController {
    
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
    
    let logoContainerView: UIView = {
        let view = UIView()
        
        let logoImage = UIImageView(image: #imageLiteral(resourceName: "logo1").withRenderingMode(.alwaysOriginal))
        logoImage.clipsToBounds = true
        logoImage.contentMode = .scaleToFill
        
        view.addSubview(logoImage)
        logoImage.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 30, paddingLeft: 50, paddingBottom: -30, paddingRight: -50, width: nil, height: nil)
        
        let seperatorView = UIView()
        seperatorView.backgroundColor = .lightGray
        
        view.addSubview(seperatorView)
        seperatorView.anchor(top: nil, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 15, paddingBottom: 0, paddingRight: -15, width: nil, height: 0.5)
        
        return view
    }()
    
    lazy var emailTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Email"
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.borderStyle = .roundedRect
        tf.tintColor = UIColor.mainBlue()
        tf.delegate = self
        tf.addTarget(self, action: #selector(handleTextInputChanges), for: .editingChanged)
        
        return tf
    }()
    
    lazy var passwordTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Password (atleast 6 characters)"
        tf.isSecureTextEntry = true
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.borderStyle = .roundedRect
        tf.tintColor = UIColor.mainBlue()
        tf.delegate = self
        tf.addTarget(self, action: #selector(handleTextInputChanges), for: .editingChanged)
        
        return tf
    }()
    
    @objc fileprivate func handleTextInputChanges() {
        
        let isFormValid = emailTextField.text?.count ?? 0 > 0 && passwordTextField.text?.count ?? 0 > 5
        
        if isFormValid {
            loginButton.backgroundColor = UIColor.mainBlue().withAlphaComponent(1)
            loginButton.isEnabled = true
        } else {
            loginButton.backgroundColor = UIColor.mainBlue().withAlphaComponent(0.3)
            loginButton.isEnabled = false
        }
        
    }
    
    let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Login", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.tintColor = .white
        button.backgroundColor = UIColor.mainBlue().withAlphaComponent(0.3)
        button.layer.cornerRadius = 5
        button.isEnabled = false
        button.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
        
        return button
    }()
    
    @objc func handleLogin() {
        disableAndActivate(true)
        
        guard let email = emailTextField.text, let password = passwordTextField.text else { print("Must fill out all input fields"); return }
        
        Auth.auth().signIn(withEmail: email, password: password) { (user, err) in
            
            if let error = err {
                if error.localizedDescription == Constants.ErrorDescriptions.invalidPassword {
                    let alert = self.okayAlert(title: "Invalid Password", message: "Please enter the correct password for this user.")
                    self.display(alert: alert)
                    
                } else if error.localizedDescription == Constants.ErrorDescriptions.invalidEmailAddress {
                    let alert = self.okayAlert(title: "Invalid Email", message: "There are no users with this corresponding email address")
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
            
            if let user = user {
                print("Succesfully logged back in", user.uid)
                
                DispatchQueue.main.async {
                    self.disableAndActivate(false)
                    // Delete and refresh info in mainTabBar controllers
                    guard let mainTabBarController = UIApplication.shared.keyWindow?.rootViewController as? MainTabBarController else { fatalError() }
                    mainTabBarController.setupViewControllers()
                    
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
    
    fileprivate func display(alert: UIAlertController) {
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    let switchToSignupButton: UIButton = {
        let button = UIButton(type: .system)
        
        let attributedTitle = NSMutableAttributedString(string: "Don't have an account?  ", attributes: [.font : UIFont.systemFont(ofSize: 14), .foregroundColor : UIColor.lightGray])
        attributedTitle.append(NSAttributedString(string: "Signup.", attributes: [.font : UIFont.boldSystemFont(ofSize: 14), .foregroundColor : UIColor.mainBlue()]))
        
        button.setAttributedTitle(attributedTitle, for: .normal)
        button.addTarget(self, action: #selector(handleSwitchToLogin), for: .touchUpInside)
        
        return button
    }()
    
    @objc fileprivate func handleSwitchToLogin() {
        let signUpVC = SignUpVC()
        navigationController?.pushViewController(signUpVC, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
        
        setupViews()
    }
    
    fileprivate func setupViews() {
        view.addSubview(logoContainerView)
        logoContainerView.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: nil, height: 150)
        
        view.addSubview(scrollView)
        scrollView.anchor(top: logoContainerView.bottomAnchor, left: view.leftAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: nil, height: nil)
        scrollView.contentSize = CGSize(width: view.frame.width, height: view.frame.height - 120)
        
        let stackView = UIStackView(arrangedSubviews: [
            emailTextField,
            passwordTextField,
            loginButton
            ])
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 10
        
        scrollView.addSubview(stackView)
        stackView.anchor(top: scrollView.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 30, paddingLeft: 40, paddingBottom: 0, paddingRight: -40, width: nil, height: 150)
        
        scrollView.addSubview(switchToSignupButton)
        switchToSignupButton.anchor(top: nil, left: view.leftAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: nil, height: 50)
    }
    
    func disableAndActivate(_ bool: Bool) {
        if bool {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
        
        emailTextField.isEnabled = !bool
        passwordTextField.isEnabled = !bool
        loginButton.isEnabled = !bool
        switchToSignupButton.isEnabled = !bool
    }
    
    func okayAlert(title: String, message: String) -> UIAlertController {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Okay", style: .cancel , handler: nil)
        alertController.addAction(okAction)
        
        return alertController
    }
}

//MARK: UITextFieldDelegate methods
extension LogInVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.isFirstResponder {
            textField.resignFirstResponder()
        }
        return true
    }
}
