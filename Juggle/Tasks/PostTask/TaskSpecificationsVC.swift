//
//  TaskSpecificationsVC.swift
//  Juggle
//
//  Created by Nathaniel Remy on 22/07/2018.
//  Copyright © 2018 Nathaniel Remy. All rights reserved.
//

import UIKit

class TaskSpecificationsVC: UIViewController {
    
    //MARK: Stored properties
    var taskCategory: String?
    
    let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.bounces = true
        sv.backgroundColor = .white
        
        return sv
    }()
    
    let taskTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Task Title"
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textColor = UIColor.mainBlue()
        
        return label
    }()
    
    lazy var taskTitleTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Minimum 10 characters, max 40 characters"
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.borderStyle = .roundedRect
        tf.tintColor = UIColor.mainBlue()
        tf.layer.borderColor = UIColor.black.cgColor
        tf.delegate = self
        
        return tf
    }()
    
    let taskDescriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        
        var attributedText = NSMutableAttributedString(string: "Description\n", attributes: [.font : UIFont.boldSystemFont(ofSize: 18), .foregroundColor : UIColor.mainBlue()])
        attributedText.append(NSAttributedString(string: "(Minimum 25 charcaters, max 250 characters)", attributes: [.font : UIFont.systemFont(ofSize: 12), .foregroundColor : UIColor.mainBlue()]))
        
        label.attributedText = attributedText
        
        return label
    }()
    
    lazy var taskDescriptionTextView: UITextView = {
        let tv = UITextView()
        tv.tintColor = UIColor.mainBlue()
        tv.layer.borderWidth = 0.5
        tv.layer.borderColor = UIColor.lightGray.cgColor
        tv.font = UIFont.systemFont(ofSize: 14)
        
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action: #selector(handleTextFieldDoneButton))
        
        toolBar.setItems([flexibleSpace, doneButton], animated: false)
        
        tv.inputAccessoryView = toolBar
        
        return tv
    }()
    
    let budgetLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        
        let attributedText = NSMutableAttributedString(string: "Budget $\n", attributes: [.font : UIFont.boldSystemFont(ofSize: 18), .foregroundColor : UIColor.mainBlue()])
        attributedText.append(NSAttributedString(string: "(How much you are willing to pay for this task to be accomplished)", attributes: [.font : UIFont.systemFont(ofSize: 12), .foregroundColor : UIColor.mainBlue()]))
        
        label.attributedText = attributedText
        
        return label
    }()
    
    lazy var budgetTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "$$$"
        tf.keyboardType = .numberPad
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.borderStyle = .roundedRect
        tf.tintColor = UIColor.mainBlue()
        tf.layer.borderColor = UIColor.black.cgColor
        tf.delegate = self
        
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action: #selector(handleTextFieldDoneButton))
        
        toolBar.setItems([flexibleSpace, doneButton], animated: false)
        
        tf.inputAccessoryView = toolBar
        
        return tf
    }()
    
    lazy var nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor.mainBlue()
        button.setTitle("Next", for: .normal)
        button.tintColor = .white
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.addTarget(self, action: #selector(handleNext), for: .touchUpInside)
        
        return button
    }()
    
    @objc func handleNext() {
        if let inputs = areInputsValid() {
            
            let taskLocationVC = TaskLocationVC()
            taskLocationVC.taskCategory = inputs.category
            taskLocationVC.taskDescription = inputs.description
            taskLocationVC.taskTitle = inputs.title
            taskLocationVC.taskBudget = inputs.budget
            
            navigationController?.pushViewController(taskLocationVC, animated: true)
            
        } else {
            let alert = okayAlert(title: "Invalid Entry", message: "Please make sure that you have entered the correct credentials.")
            present(alert, animated: true, completion: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationItem.title = "Task Details"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(handleNext))
        
        setupViews()
    }
    
    fileprivate func areInputsValid() -> (title: String, description: String, category: String, budget: Int)? {
        guard let title = taskTitleTextField.text, title.count > 9, title.count < 41 else {
            let alert = self.okayAlert(title: "Error with title", message: "Title must be between 10-40 characters.")
            present(alert, animated: true, completion: nil); return nil
        }
        guard let description = taskDescriptionTextView.text, description.count > 24, description.count < 251 else {
            let alert = self.okayAlert(title: "Error with description", message: "Description must be between 25-250 characters.")
            present(alert, animated: true, completion: nil); return nil
        }
        guard let category = self.taskCategory else {
            self.navigationController?.popViewController(animated: true)
            return nil
        }
        guard let budget = Int(budgetTextField.text!) else {
            let alert = self.okayAlert(title: "Error with budget", message: "Please enter integer values for your budget.")
            present(alert, animated: true, completion: nil); return nil
        }
        
        return (title, description, category, budget)
    }
    
    fileprivate func setupViews() {
        view.addSubview(scrollView)
        scrollView.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: nil, height: nil)
        scrollView.contentSize = CGSize(width: view.frame.width, height: 850)
        
        scrollView.addSubview(taskTitleLabel)
        taskTitleLabel.anchor(top: scrollView.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 8, paddingLeft: 25, paddingBottom: 0, paddingRight: -25, width: nil, height: 50)
        
        scrollView.addSubview(taskTitleTextField)
        taskTitleTextField.anchor(top: taskTitleLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 8, paddingLeft: 25, paddingBottom: 0, paddingRight: -25, width: nil, height: 50)
        
        scrollView.addSubview(taskDescriptionLabel)
        taskDescriptionLabel.anchor(top: taskTitleTextField.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 25, paddingLeft: 25, paddingBottom: 0, paddingRight: -25, width: nil, height: 50)
        
        scrollView.addSubview(taskDescriptionTextView)
        taskDescriptionTextView.anchor(top: taskDescriptionLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 8, paddingLeft: 25, paddingBottom: 0, paddingRight: -25, width: nil, height: 200)
        
        scrollView.addSubview(budgetLabel)
        budgetLabel.anchor(top: taskDescriptionTextView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 25, paddingLeft: 25, paddingBottom: 0, paddingRight: -25, width: nil, height: 60)
        
        scrollView.addSubview(budgetTextField)
        budgetTextField.anchor(top: budgetLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 8, paddingLeft: 25, paddingBottom: 0, paddingRight: -25, width: nil, height: 50)
        
        scrollView.addSubview(nextButton)
        nextButton.anchor(top: budgetTextField.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 35, paddingLeft: 45, paddingBottom: 0, paddingRight: -45, width: nil, height: 50)
        nextButton.layer.cornerRadius = 25
        
    }
    
    func okayAlert(title: String, message: String) -> UIAlertController {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Okay", style: .cancel , handler: nil)
        alertController.addAction(okAction)
        
        return alertController
    }
}

//MARK: UITextFieldDelegate Methods
extension TaskSpecificationsVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.isFirstResponder {
            textField.resignFirstResponder()
        }
        return true
    }
    
    // When done button is clicked on keyboard input accessory view
    @objc func handleTextFieldDoneButton() {
        view.endEditing(true)
    }
}
