import UIKit
import Foundation

class UpdateProfileTableInfoView : UITableViewController, UITextFieldDelegate {
    
    @IBOutlet weak var cityInfo: UITextField!
    @IBOutlet weak var countryInfo: UITextField!
    @IBOutlet weak var bdayInfo: UITextField!
    @IBOutlet weak var emailInfo: UITextField!
    @IBOutlet weak var phoneInfo: UITextField!

    @IBOutlet weak var sexPicker: UISegmentedControl!
    @IBOutlet weak var surnameInfo: UITextField!
    @IBOutlet weak var nameInfo: UITextField!

    var cityString = ""
    var countryString = ""
    var bdayString = ""
    var emailString = ""
    var phoneString = ""
    var nameString = ""
    var surnameString = ""
    var sexInt: Int32 = 0

    private var observerUpdateProfile: NSObjectProtocol!

    let datePicker = UIDatePicker()

    @objc func endEditing() {
        self.view.endEditing(true)
    }

    func updateProfile(notification: Notification) {

        User.currentUser!.city = cityInfo.text
        if (!phoneInfo.text!.isEmpty) {
            User.currentUser!.phoneNumber = Int64(phoneInfo.text!)
        } else {
            User.currentUser!.phoneNumber = 0
        }
        User.currentUser!.email = emailInfo.text
        User.currentUser!.birthdate = bdayInfo.text
        User.currentUser!.country = countryInfo.text

        User.currentUser!.first_name = nameInfo.text
        User.currentUser!.last_name = surnameInfo.text

        if (sexPicker.selectedSegmentIndex == 0) {
            User.currentUser!.gender! = 1
        } else if (sexPicker.selectedSegmentIndex == 1) {
            User.currentUser!.gender! = 2
        }

        NetworkManager.instance.sendPacket(User.currentUser!) { response, error in
            if (response != nil) {
                User.saveConfig()
                NotificationCenter.default.post(name: NSNotification.Name("hideIndicator"), object: nil)

                DispatchQueue.main.async() {
                    self.updateView()
                }

                print("profile update success")
            } else {
                print("profile update error")
            }
        }
    }

    func createDatePicker() {

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat="yyyy-MM-dd"
        let minDate = dateFormatter.date(from: "1917-01-01")!
        let maxDate = dateFormatter.date(from: "2017-01-01")!


        datePicker.datePickerMode = .date
        datePicker.maximumDate = maxDate
        datePicker.minimumDate = minDate

        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: #selector(datePickerDonePressed))
        toolbar.setItems([doneButton], animated: false)

        bdayInfo.inputAccessoryView = toolbar

        bdayInfo.inputView = datePicker


    }

    @objc func datePickerDonePressed() {

        let dateFormatter = DateFormatter()

        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale(identifier: "ja_JP")

        let date = dateFormatter.string(from: datePicker.date)

        bdayInfo.text = ""
        bdayInfo.text = date.replacingOccurrences(of: "/", with: "-")

        self.view.endEditing(true)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)

    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        textField.resignFirstResponder()
        return (true)

    }

    @objc func textFieldDidChanged(_ textField : UITextField) {
        if (nameInfo.text != nameString || surnameInfo.text != surnameString
                || cityInfo.text != cityString || phoneInfo.text != phoneString
                || emailInfo.text != emailString || bdayInfo.text != bdayString
                || countryInfo.text != countryString
                || sexPicker.selectedSegmentIndex != sexInt - 1) {

            NotificationCenter.default.post(name: NSNotification.Name("changeInfoTrue"), object: nil)

        } else {

            NotificationCenter.default.post(name: NSNotification.Name("changeInfoFalse"), object: nil)

        }
    }

    func segmentControlChangeValue(_ segmentControl : UISegmentedControl) {
        if (nameInfo.text != nameString || surnameInfo.text != surnameString
                || cityInfo.text != cityString || phoneInfo.text != phoneString
                || emailInfo.text != emailString || bdayInfo.text != bdayString
                || countryInfo.text != countryString
                || sexPicker.selectedSegmentIndex != sexInt - 1) {

            NotificationCenter.default.post(name: NSNotification.Name("changeInfoTrue"), object: nil)

        } else {

            NotificationCenter.default.post(name: NSNotification.Name("changeInfoFalse"), object: nil)

        }
    }

    func updateView () {
        if (User.currentUser!.gender != nil && User.currentUser!.gender! == 1) {
            sexPicker.selectedSegmentIndex = 0
            sexInt = 1
        } else if (User.currentUser!.gender != nil && User.currentUser!.gender! == 2) {
            sexPicker.selectedSegmentIndex = 1
            sexInt = 2
        } else if (User.currentUser!.gender != nil && User.currentUser!.gender! == 0) {
            sexPicker.selectedSegmentIndex = 0
            sexInt = 1
        }
        if (User.currentUser!.first_name != nil && !User.currentUser!.first_name.isEmpty) {
            nameInfo.text = User.currentUser!.first_name
            nameString = User.currentUser!.first_name
        } else {
            nameInfo.text = ""
            nameString = ""
        }
        if (User.currentUser!.last_name != nil && !User.currentUser!.last_name.isEmpty) {
            surnameInfo.text = User.currentUser!.last_name
            surnameString = User.currentUser!.last_name
        } else {
            surnameInfo.text = ""
            surnameString = ""
        }

        if (User.currentUser!.city != nil && !User.currentUser!.city.isEmpty) {
            cityInfo.text = User.currentUser!.city
            cityString = User.currentUser!.city
        } else {
            cityInfo.text = ""
            cityString = ""
        }

        if (User.currentUser!.phoneNumber != nil && User.currentUser!.phoneNumber != 0) {
            phoneInfo.text = String(User.currentUser!.phoneNumber)
            phoneString = String(User.currentUser!.phoneNumber)
        } else {
            phoneInfo.text = ""
            phoneString = ""
        }
        if (User.currentUser!.email != nil && !User.currentUser!.email.isEmpty) {
            emailInfo.text = User.currentUser!.email
            emailString = User.currentUser!.email
        } else {
            emailInfo.text = ""
            emailString = ""
        }
        if (User.currentUser!.birthdate != nil && !User.currentUser!.birthdate.isEmpty) {
            bdayInfo.text = User.currentUser!.birthdate
            bdayString = User.currentUser!.birthdate

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat="yyyy-MM-dd"
            let date = dateFormatter.date(from: User.currentUser!.birthdate)!
            datePicker.date = date
        } else {
            bdayInfo.text = ""
            bdayString = ""
        }
        if (User.currentUser!.country != nil && !User.currentUser!.birthdate.isEmpty) {
            countryInfo.text = User.currentUser!.country
            countryString = User.currentUser!.country
        } else {
            countryInfo.text = ""
            countryString = ""
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        observerUpdateProfile = NotificationCenter.default.addObserver(forName: NSNotification.Name("updateProfile"), object: nil, queue: nil, using: updateProfile)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {

        switch (section) {
            case 0: return "Information about you".localized
            case 1: return ""
            case 2: return ""
            default: return "Information about you".localized
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let tapper = UITapGestureRecognizer(target: self, action: #selector(endEditing))
        tapper.cancelsTouchesInView = false
        view.addGestureRecognizer(tapper)

        updateView()
        self.cityInfo.delegate = self
        self.countryInfo.delegate = self
        self.bdayInfo.delegate = self
        self.emailInfo.delegate = self
        self.phoneInfo.delegate = self
        self.nameInfo.delegate = self
        self.surnameInfo.delegate = self

        self.cityInfo.placeholder = "City".localized
        self.countryInfo.placeholder = "Country".localized
        self.emailInfo.placeholder = "E-mail".localized
        self.phoneInfo.placeholder = "Phone number".localized
        self.nameInfo.placeholder = "Name".localized
        self.surnameInfo.placeholder = "Surname".localized

        self.sexPicker.setTitle("Male".localized, forSegmentAt: 0)
        self.sexPicker.setTitle("Female".localized, forSegmentAt: 1)

        createDatePicker()

        nameInfo.addTarget(self, action: #selector(textFieldDidChanged(_:)), for: .editingChanged)
        surnameInfo.addTarget(self, action: #selector(textFieldDidChanged(_:)), for: .editingChanged)
        cityInfo.addTarget(self, action: #selector(textFieldDidChanged(_:)), for: .editingChanged)
        phoneInfo.addTarget(self, action: #selector(textFieldDidChanged(_:)), for: .editingChanged)
        bdayInfo.addTarget(self, action: #selector(textFieldDidChanged(_:)), for: .editingDidEnd)
        emailInfo.addTarget(self, action: #selector(textFieldDidChanged(_:)), for: .editingChanged)
        countryInfo.addTarget(self, action: #selector(textFieldDidChanged(_:)), for: .editingChanged)


        sexPicker.addTarget(self, action: #selector(segmentControlChangeValue(_:)), for: .valueChanged)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NotificationCenter.default.removeObserver(observerUpdateProfile)
    }
}
