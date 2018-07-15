//
// Created by Vladislav on 24/08/2017.
// Copyright (c) 2017 Paymon. All rights reserved.
//

import UIKit

extension UIView {
    func addBackground() {
        // screen width and height:
//        let width = UIScreen.mainScreen().bounds.size.width
//        let height = UIScreen.mainScreen().bounds.size.height

        let imageViewBackground = UIImageView(frame: UIScreen.main.bounds)
        imageViewBackground.image = UIImage(named: "back_auth1")

        // you can change the content mode:
        imageViewBackground.contentMode = UIViewContentMode.scaleAspectFill

        self.addSubview(imageViewBackground)
        self.sendSubview(toBack: imageViewBackground)
    }}


class StartViewController: UIViewController {

    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var paymonLogoView: UIImageView!

    @IBOutlet weak var haveAccountLabel: UILabel!
    @IBAction func presentAuthView(_ sender: UIButton) {
        let authView = storyboard?.instantiateViewController(withIdentifier: "AuthViewController") as! AuthViewController
        present(authView, animated: true)
    }

    @IBAction func presentRegistrationView(_ sender: UIButton) {
        let registrationView = storyboard?.instantiateViewController(withIdentifier: "RegistrViewController") as! RegistrViewController
        present(registrationView, animated: true)
    }


    override func viewDidLoad() {
        super.viewDidLoad()


        signInButton.layer.cornerRadius = 15
        signUpButton.layer.cornerRadius = 15

        haveAccountLabel.text = "Already have an account?".localized

        signInButton.setTitle("sign in".localized, for: .normal)
        signUpButton.setTitle("sign up".localized, for: .normal)

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.view.addBackground()
//        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "back_auth1")!)

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

}
