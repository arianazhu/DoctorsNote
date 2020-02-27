//
//  RequestAccountTableViewController.swift
//  DoctorsNote
//
//  Created by Benjamin Hardin on 2/15/20.
//  Copyright © 2020 Benjamin Hardin. All rights reserved.
//

import UIKit
import AWSCognito
import AWSMobileClient
import PopupKit

//
//
//
class AccountRegisterViewController: UIViewController {
    
    @IBOutlet weak var emailField: CustomTextField!
    @IBOutlet weak var passwordField: CustomTextField!
    @IBOutlet weak var confirmField: CustomTextField!
    @IBOutlet weak var errorLabel: UILabel!
    
    var p: PopupView?
    var activityIndicator = UIActivityIndicatorView()
    
    override func viewDidLoad() {
        self.navigationItem.hidesBackButton = true
        super.viewDidLoad()
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.style = .gray
        view.addSubview(activityIndicator)
        // TODO: REMOVE LATER
        AWSMobileClient.default().signOut()
    }
    
    @IBAction func goBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func goForward(_ sender: Any) {
        if (fieldsCorrect()) {
            self.activityIndicator.startAnimating()
            // Sign up user with attributes to be added in the next controller
            AWSMobileClient.default().signUp(username: emailField.text!, password: passwordField.text!, userAttributes: ["name":"", "middle_name":"", "family_name":"", "gender":"", "birthdate":"", "address":"", "phone_number":""]) { (res, err) in
                if let err = err as? AWSMobileClientError {
                    switch err {
                    case .usernameExists, .invalidPassword:
                        DispatchQueue.main.async {
                            self.activityIndicator.stopAnimating()
                            self.errorLabel.text = "Error: " + err.message
                        }
                        return
                    default:
                        print("\(err.message)")
                    }
                }
                DispatchQueue.main.async {
                    self.errorLabel.text = ""
                    self.activityIndicator.stopAnimating()
                    self.performSegue(withIdentifier: "show_verification", sender: self)
                    return
                }
            }
        }
    }
    
    func showPopup(_ message: String) {
        let width : Int = Int(self.view.frame.width - 20)
        let height = 200

        let contentView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: width, height: height))
        contentView.backgroundColor = UIColor.white
        let maskLayer = CAShapeLayer()
        maskLayer.path = UIBezierPath(roundedRect: contentView.bounds, cornerRadius: 38.5).cgPath
        contentView.layer.mask = maskLayer

        p = PopupView.init(contentView: contentView)
        p?.maskType = .dimmed

        let label = UILabel(frame: CGRect(x: 20, y: 20, width: width - 40, height: 100))
        label.text = message
        label.numberOfLines = 5

        let closeButton = UIButton(frame: CGRect(x: width/2 - 45, y: height - 75, width: 90, height: 40))
        closeButton.setTitle("Done", for: .normal)
        closeButton.backgroundColor = UIColor.systemBlue
        let layer = CAShapeLayer()
        layer.path = UIBezierPath(roundedRect: closeButton.bounds, cornerRadius: DefinedValues.fieldRadius).cgPath
        closeButton.layer.mask = layer
        closeButton.addTarget(self, action: #selector(dismissPopup), for: .touchUpInside)

        contentView.addSubview(closeButton)
        contentView.addSubview(label)

        let xPos = self.view.frame.width / 2
        let yPos = self.view.frame.height - (CGFloat(height) / 2) - 10
        let location = CGPoint.init(x: xPos, y: yPos)
        p?.showType = .slideInFromBottom
        p?.maskType = .dimmed
        p?.dismissType = .slideOutToBottom
        p?.show(at: location, in: self.navigationController!.view)
    }
        
    func fieldsCorrect() -> Bool {
        let emailEmpty = emailField.isEmpty()
        let emailValid = emailField.isValidEmail()
        let passwordEmpty = passwordField.isEmpty()
        let confirmEmpty = confirmField.isEmpty()
        let passwordsEqual = (passwordField.text! == confirmField.text!)
        if (passwordsEqual) {
            errorLabel.text = ""
        } else {
            errorLabel.text = "Error: Password entries do not match."
        }
        
        return (!emailEmpty && !passwordEmpty && !confirmEmpty && emailValid && passwordsEqual)
    }
    
    @objc func dismissPopup(sender: UIButton!) {
        p?.dismissType = .slideOutToBottom
        p?.dismiss(animated: true)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let nextVC = segue.destination as! ConfirmAccountViewController
        nextVC.email = emailField.text!
    }
    
    @IBAction func hasCode(_ sender: Any) {
        self.performSegue(withIdentifier: "show_verification", sender: self)
    }
    

}









class ConfirmAccountViewController: UIViewController {
    
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var emailField: CustomTextField!
    @IBOutlet weak var codeField: CustomTextField!
    @IBOutlet weak var createButton: UIButton!
    
    var email: String?
    var p: PopupView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.hidesBackButton = true
        
        if (email != "") {
            emailLabel.isHidden = true
            emailField.isHidden = true
            
            emailLabel.isEnabled = false
            emailField.isEnabled = false
        }
        
        let requestLayer = CAShapeLayer()
        requestLayer.path = UIBezierPath(roundedRect: createButton.bounds, cornerRadius: DefinedValues.fieldRadius).cgPath
        createButton.layer.mask = requestLayer
        
    }
    
    @IBAction func createUser(_ sender: Any) {
        // Verify code
            
        var emailEmpty = true
        var emailValid = false
        if (email == "") {
            // Email has not been passed to this controller
            email = emailField.text!
            emailEmpty = emailField.isEmpty()
            emailValid = emailField.isValidEmail()
        } else {
            emailEmpty = false
            emailValid = true
        }
        
        let codeEmpty = codeField.isEmpty()
        
        if (!emailValid || emailEmpty || codeEmpty) {
            self.errorLabel.textColor = UIColor.black
            self.errorLabel.text = "Enter the verification code emailed to you below."
            return
        }
        
        AWSMobileClient.default().confirmSignUp(username: email!, confirmationCode: codeField.text!) { (res, err) in
            if let err = err as? AWSMobileClientError {
                DispatchQueue.main.async {
                    self.errorLabel.textColor = UIColor.systemRed
                    self.errorLabel.text = err.message
                }
            } else {
                DispatchQueue.main.async {
                    self.showPopup()
                }
            }
        }
    }
    
    func showPopup() {
        let width : Int = Int(self.view.frame.width - 20)
        let height = 200

        let contentView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: width, height: height))
        contentView.backgroundColor = UIColor.white
        let maskLayer = CAShapeLayer()
        maskLayer.path = UIBezierPath(roundedRect: contentView.bounds, cornerRadius: 38.5).cgPath
        contentView.layer.mask = maskLayer

        p = PopupView.init(contentView: contentView)
        p?.maskType = .dimmed

        let label = UILabel(frame: CGRect(x: 20, y: 20, width: width - 40, height: 100))
        label.text = "Account has been created! Sign in to finish setting up your profile."
        label.numberOfLines = 5

        let closeButton = UIButton(frame: CGRect(x: width/2 - 45, y: height - 75, width: 90, height: 40))
        closeButton.setTitle("Done", for: .normal)
        closeButton.backgroundColor = UIColor.systemBlue
        let layer = CAShapeLayer()
        layer.path = UIBezierPath(roundedRect: closeButton.bounds, cornerRadius: DefinedValues.fieldRadius).cgPath
        closeButton.layer.mask = layer
        closeButton.addTarget(self, action: #selector(dismissPopup), for: .touchUpInside)

        contentView.addSubview(closeButton)
        contentView.addSubview(label)

        let xPos = self.view.frame.width / 2
        let yPos = self.view.frame.height - (CGFloat(height) / 2) - 10
        let location = CGPoint.init(x: xPos, y: yPos)
        p?.showType = .slideInFromBottom
        p?.maskType = .dimmed
        p?.dismissType = .slideOutToBottom
        p?.show(at: location, in: self.navigationController!.view)
    }
        
    @objc func dismissPopup(sender: UIButton!) {
        p?.dismissType = .slideOutToBottom
        p?.dismiss(animated: true)
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func goBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    
}



//
//
//
class PersonalRegisterViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet weak var firstNameField: CustomTextField!
    @IBOutlet weak var middleNameField: CustomTextField!
    @IBOutlet weak var lastNameField: CustomTextField!
    @IBOutlet weak var DOBButton: UIButton!
    @IBOutlet weak var sexButton: UIButton!
    @IBOutlet weak var phoneField: CustomTextField!
    @IBOutlet weak var streetField: CustomTextField!
    @IBOutlet weak var cityField: CustomTextField!
    @IBOutlet weak var stateField: CustomTextField!
    @IBOutlet weak var zipField: CustomTextField!
    
    var p: PopupView?
    var DOBPicker: UIDatePicker?
    var sexPicker: UIPickerView?
    
    var DOB: String = ""
    var sex: String = ""
    
    let sexes = ["Male", "Female"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.hidesBackButton = true
        
        DOBButton.layer.borderColor = UIColor.systemBlue.cgColor
        sexButton.layer.borderColor = UIColor.systemBlue.cgColor
        
        DOBButton.layer.borderWidth = 2
        sexButton.layer.borderWidth = 2
        
        DOBButton.layer.cornerRadius = DefinedValues.fieldRadius
        sexButton.layer.cornerRadius = DefinedValues.fieldRadius
        
    }
    
    @IBAction func goBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func goForward(_ sender: Any) {
        if (fieldsCorrect()) {
            // TODO ADD PHONE NUMBER VALIDATION
            let address = streetField.text! + " " + cityField.text! + " " + stateField.text! + " " + zipField.text!
            let phone = "+1" + phoneField.text!
            AWSMobileClient.default().updateUserAttributes(attributeMap: ["name":firstNameField.text!, "middle_name":middleNameField.text!, "family_name":lastNameField.text!, "gender":sex, "birthdate":DOB, "address":address, "phone_number":phone]) { (details, err) in
                if let err = err as? AWSMobileClientError {
                    print("\(err.message)")
                } else {
                    print("Info updated correctly!")
                }
            }
            
            
            
            
            self.performSegue(withIdentifier: "show_third", sender: self)
        }
    }
    
    func fieldsCorrect() ->Bool {
        let first = firstNameField.isEmpty()
        let middle = middleNameField.isEmpty()
        let last = lastNameField.isEmpty()
        let phone = phoneField.isEmpty()
        let street = streetField.isEmpty()
        let city = cityField.isEmpty()
        let state = stateField.isEmpty()
        let zip = zipField.isEmpty()
        
        var DOBFilled = true
        if (DOB == "") {
            DOBButton.layer.borderColor = UIColor.systemRed.cgColor
            DOBFilled = false
        } else {
            DOBButton.layer.borderColor = UIColor.systemBlue.cgColor
        }
        
        var sexFilled = true
        if (sex == "") {
            sexButton.layer.borderColor = UIColor.systemRed.cgColor
            sexFilled = false
        } else {
            sexButton.layer.borderColor = UIColor.systemBlue.cgColor
        }
        
        if (first || middle || last || phone || street || city || state || zip || !DOBFilled || !sexFilled) {
            return false
        }
        return true
    }
    
    @IBAction func showDOB(_ sender: Any) {
        pressButton(tag: DOBButton.tag)
    }
    
    @IBAction func showSex(_ sender: Any) {
        pressButton(tag: sexButton.tag)
    }
    
    func pressButton(tag: Int) {
        let width : Int = Int(self.view.frame.width - 20)
        let height = 280
        
        let contentView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: width, height: height))
        contentView.backgroundColor = UIColor.white
        let maskLayer = CAShapeLayer()
        maskLayer.path = UIBezierPath(roundedRect: contentView.bounds, cornerRadius: 38.5).cgPath
        contentView.layer.mask = maskLayer
        
        p = PopupView.init(contentView: contentView)
        p?.maskType = .dimmed
        
        if (tag == 1) {
            DOBPicker = UIDatePicker(frame: CGRect(x: 5, y: 5, width: contentView.frame.width - 10, height: 200))
            DOBPicker?.datePickerMode = .date
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy/MM/dd HH:mm"
            DOBPicker?.minimumDate = formatter.date(from: "1900/01/01 00:00")
            DOBPicker?.maximumDate = Date()
        }
        else if (tag == 2) {
            sexPicker = UIPickerView(frame: CGRect(x: 5, y: 5, width: contentView.frame.width - 10, height: 200))
            sexPicker?.dataSource = self
            sexPicker?.delegate = self
        }
        
        
        let closeButton = UIButton(frame: CGRect(x: width/2 - 45, y: height - 75, width: 90, height: 50))
        closeButton.setTitle("Done", for: .normal)
        closeButton.backgroundColor = UIColor.systemBlue
        let layer = CAShapeLayer()
        layer.path = UIBezierPath(roundedRect: closeButton.bounds, cornerRadius: DefinedValues.fieldRadius).cgPath
        closeButton.layer.mask = layer
        closeButton.addTarget(self, action: #selector(dismissPopup), for: .touchUpInside)
        closeButton.tag = tag
        
        contentView.addSubview(closeButton)
        if (tag == 1) {
            contentView.addSubview(DOBPicker!)
        }
        else if (tag == 2) {
            contentView.addSubview(sexPicker!)
        }
        
        let xPos = self.view.frame.width / 2
        let yPos = self.view.frame.height - (CGFloat(height) / 2) - 10
        let location = CGPoint.init(x: xPos, y: yPos)
        p?.showType = .slideInFromBottom
        p?.maskType = .dimmed
        p?.dismissType = .slideOutToBottom
        p?.show(at: location, in: self.navigationController!.view)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 2
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let row = sexes[row]
        return row
    }
    
    @objc func dismissPopup(sender: UIButton!) {
        if (sender.tag == 1) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/yyyy"
            DOB = dateFormatter.string(from: DOBPicker!.date)
            
            // TODO: ADD DATE FORMATTER
            DOBButton.setTitle(DOB, for: .normal)
            p?.dismissType = .slideOutToBottom
            p?.dismiss(animated: true)
        }
        else if (sender.tag == 2) {
            sex = sexes[(sexPicker?.selectedRow(inComponent: 0))!]
            sexButton.setTitle(sex, for: .normal)
            p?.dismissType = .slideOutToBottom
            p?.dismiss(animated: true)
        }
    }

    
}



//
//
//
class HealthRegisterViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    @IBOutlet weak var requestButton: UIButton!
    @IBOutlet weak var selectHospitalButton: UIButton!
    @IBOutlet weak var selectHealthcareButton: UIButton!

    var p: PopupView?
    var picker: UIPickerView?
    // To be gathered later from the database
    let hospitals = ["IU Health Arnett Hospital", "Franciscan Health Lafayette East"]
    var hospital: String?
    
    let providers = ["Humana", "Aetna", "Other"]
    var provider: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.hidesBackButton = true
        
        let requestLayer = CAShapeLayer()
        requestLayer.path = UIBezierPath(roundedRect: requestButton.bounds, cornerRadius: DefinedValues.fieldRadius).cgPath
        requestButton.layer.mask = requestLayer
        
        selectHospitalButton.layer.cornerRadius = DefinedValues.fieldRadius
        selectHealthcareButton.layer.cornerRadius = DefinedValues.fieldRadius
        
         selectHospitalButton.layer.borderColor = navigationController?.navigationBar.tintColor.cgColor
         selectHospitalButton.layer.borderWidth = 2
         selectHealthcareButton.layer.borderColor = navigationController?.navigationBar.tintColor.cgColor
         selectHealthcareButton.layer.borderWidth = 2
        
    }
    
    @IBAction func requestAccount(_ sender: Any) {
        
        let hospitalSelected = (hospital != nil)
        let providerSelected = (provider != nil)
        
        if (hospitalSelected) {
            selectHospitalButton.layer.borderColor = UIColor.systemBlue.cgColor
        } else {
            selectHospitalButton.layer.borderColor = UIColor.systemRed.cgColor
        }
        
        if (providerSelected) {
            selectHealthcareButton.layer.borderColor = UIColor.systemBlue.cgColor
        } else {
            selectHealthcareButton.layer.borderColor = UIColor.systemRed.cgColor
        }
        
        if (!hospitalSelected || !providerSelected) {
            return
        }
        
        self.performSegue(withIdentifier: "finish", sender: self)
        
        //AWSMobileClient.default().signUp(username: emailField.text!, password: passwordField.text!, userAttributes: ["name":"", "middle_name":"", "family_name":"", "gender":"", "birthdate":"06/19/2001", "address":"3980 N Graham Rd Madison IN 47250", "phone_number":"+18128017698"]) { (result, err) in
        //            if let err = err as? AWSMobileClientError {
        //                print("\(err.message)")
        //            } else {
        //                print("User signed up successfully.")
        //            }
        //        }
        
    //        AWSMobileClient.default().signOut()
    //        AWSMobileClient.default().signIn(username: email, password: password) { (result, err) in
    //            if let err = err as? AWSMobileClientError {
    //                print("\(err.message)")
    //            } else {
    //                print("user signed in ")
    //            }
    //        }
            
            //let main = UIStoryboard(name: "Main", bundle: nil)
            //let mainVC = main.instantiateInitialViewController()!
            //let presentationStyle : UIModalPresentationStyle = .overCurrentContext
            //self.modalPresentationStyle = presentationStyle
    //        AWSMobileClient.default().confirmSignIn(challengeResponse: "809614") { (signInResult, error) in
    //            if let error = error as? AWSMobileClientError {
    //                print("\(error.message)")
    //            } else if let signInResult = signInResult {
    //                switch (signInResult.signInState) {
    //                case .signedIn:
    //                    print("User is signed in.")
    //
    //                default:
    //                    print("\(signInResult.signInState.rawValue)")
    //                }
    //            }
    //        }
        
        }
    
    @IBAction func selectHospital(_ sender: Any) {
        pressButton(tag: 1)
    }
    
    @IBAction func selectProvider(_ sender: Any) {
        pressButton(tag: 2)
    }
    
    func pressButton(tag: Int) {
        let width : Int = Int(self.view.frame.width - 20)
        let height = 280
        
        let contentView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: width, height: height))
        contentView.backgroundColor = UIColor.white
        let maskLayer = CAShapeLayer()
        maskLayer.path = UIBezierPath(roundedRect: contentView.bounds, cornerRadius: 38.5).cgPath
        contentView.layer.mask = maskLayer
        
        p = PopupView.init(contentView: contentView)
        p?.maskType = .dimmed
        
//        if (tag == 3) {
//            let label = UILabel(frame: CGRect(x: 20, y: 20, width: width - 40, height: 100))
//            label.text = "Account has been requested! You will receive an email when you have been approved."
//            label.numberOfLines = 5
//        } else {
            picker = UIPickerView(frame: CGRect(x: 5, y: 5, width: contentView.frame.width - 10, height: 200))
            picker?.tag = tag
            picker?.dataSource = self
            picker?.delegate = self
            contentView.addSubview(picker!)
//        }
        
        
        let closeButton = UIButton(frame: CGRect(x: width/2 - 45, y: height - 75, width: 90, height: 50))
        closeButton.setTitle("Done", for: .normal)
        closeButton.backgroundColor = UIColor.systemBlue
        let layer = CAShapeLayer()
        layer.path = UIBezierPath(roundedRect: closeButton.bounds, cornerRadius: DefinedValues.fieldRadius).cgPath
        closeButton.layer.mask = layer
        closeButton.addTarget(self, action: #selector(dismissPopup), for: .touchUpInside)
        
        contentView.addSubview(closeButton)
        
        let xPos = self.view.frame.width / 2
        let yPos = self.view.frame.height - (CGFloat(height) / 2) - 10
        let location = CGPoint.init(x: xPos, y: yPos)
        p?.showType = .slideInFromBottom
        p?.maskType = .dimmed
        p?.dismissType = .slideOutToBottom
        p?.show(at: location, in: (self.view)!)
    }
    
    @IBAction func goBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if (pickerView.tag == 1) {
            return hospitals.count
        }
        else if (pickerView.tag == 2) {
            return providers.count
        }
        return 0
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if (pickerView.tag == 1) {
            let row = hospitals[row]
            return row
        }
        else if (pickerView.tag == 2) {
            let row = providers[row]
            return row
        }
        return ""
    }
    
    @objc func dismissPopup(sender: UIButton!) {
        if (picker?.tag == 1) {
            hospital = hospitals[(picker?.selectedRow(inComponent: 0))!]
            
            selectHospitalButton.setTitle(hospital, for: .normal)
        }
        else if (picker?.tag == 2) {
            provider = providers[(picker?.selectedRow(inComponent: 0))!]
            selectHealthcareButton.setTitle(provider, for: .normal)
        }
        p?.dismissType = .slideOutToBottom
        p?.dismiss(animated: true)
            
    }

}











//
// Segue classes
//
class SegueFromLeft: UIStoryboardSegue
{
    override func perform() {
        let src: UIViewController = self.source
        let dst: UIViewController = self.destination
        let transition: CATransition = CATransition()
        let timeFunc : CAMediaTimingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        transition.duration = 0.25
        transition.timingFunction = timeFunc
        transition.type = CATransitionType.push
        transition.subtype = CATransitionSubtype.fromRight
        src.navigationController!.view.layer.add(transition, forKey: kCATransition)
        src.navigationController!.pushViewController(dst, animated: false)
    }
}

class SegueFromRight: UIStoryboardSegue
{
    override func perform() {
        let src: UIViewController = self.source
        let dst: UIViewController = self.destination
        let transition: CATransition = CATransition()
        let timeFunc : CAMediaTimingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        transition.duration = 0.25
        transition.timingFunction = timeFunc
        transition.type = CATransitionType.push
        transition.subtype = CATransitionSubtype.fromLeft
        src.navigationController!.view.layer.add(transition, forKey: kCATransition)
        src.navigationController!.pushViewController(dst, animated: false)
    }
}

/*
 Adds padding to text fields
 Original source before modifications: https://stackoverflow.com/questions/3727068/set-padding-for-uitextfield-with-uitextborderstylenone
 */

class CustomTextField: UITextField {
    struct Constants {
        static let sidePadding: CGFloat = 15
        static let topPadding: CGFloat = 0
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.borderColor = UIColor.systemBlue.cgColor
        self.layer.borderWidth = 2
        self.layer.cornerRadius = DefinedValues.fieldRadius
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.layer.borderColor = UIColor.systemBlue.cgColor
        self.layer.borderWidth = 2
        self.layer.cornerRadius = DefinedValues.fieldRadius
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(
            x: bounds.origin.x + Constants.sidePadding,
            y: bounds.origin.y,
            width: bounds.size.width - Constants.sidePadding * 2,
            height: bounds.size.height
        )
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return self.textRect(forBounds: bounds)
    }
    
    func isEmpty() -> Bool {
        if (self.text == "") {
            self.layer.borderColor = UIColor.systemRed.cgColor
            return true
        } else {
            self.layer.borderColor = UIColor.systemBlue.cgColor
            return false
        }
    }
    
    /*
     Source:
     https://stackoverflow.com/questions/25471114/how-to-validate-an-e-mail-address-in-swift
     */
    func isValidEmail() -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        let valid = emailPred.evaluate(with: self.text)
        if (valid) {
            self.layer.borderColor = UIColor.systemBlue.cgColor
        } else {
            self.layer.borderColor = UIColor.systemRed.cgColor
        }
        return valid
    }
}

