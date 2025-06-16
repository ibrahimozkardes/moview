//
//  RegisterViewController.swift
//  moview
//
//  Created by АИДА on 15.06.2025.
//

import UIKit
import FirebaseAuth

class RegisterViewController: UIViewController {
    
    @IBOutlet weak var fullNameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var confirmPasswordField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func didTapRegister() {
        guard let name = fullNameField.text, !name.isEmpty,
              let email = emailField.text, !email.isEmpty,
              let password = passwordField.text, !password.isEmpty,
              let confirmPassword = confirmPasswordField.text, !confirmPassword.isEmpty else {
            print("Boş alan var!")
            return
        }
        
        guard password == confirmPassword else {
            print("Şifreler uyuşmuyor!")
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                print("Kayıt hatası: \(error.localizedDescription)")
            } else {
                // Ad soyad güncelle
                let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                changeRequest?.displayName = name
                changeRequest?.commitChanges { error in
                    if let error = error {
                        print("Ad soyad güncellenemedi: \(error.localizedDescription)")
                    } else {
                        print("Kayıt başarılı ve ad soyad ayarlandı!")
                        self.dismiss(animated: true)
                    }
                }
            }
        }
    }
    
    @IBAction func didTapLogin() {
        self.dismiss(animated: true)
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
