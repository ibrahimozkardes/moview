//
//  LoginViewController.swift
//  moview
//
//  Created by АИДА on 15.06.2025.
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func didTapLogin() {
        guard let email = emailField.text, !email.isEmpty,
                let password = passwordField.text, !password.isEmpty else {
            print("Email/şifre boş")
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                print("Giriş hatası: \(error.localizedDescription)")
            } else {
                print("Giriş başarılı")
                
                //Ana sayfa ekranı
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "MainVC")
                
                // Navigation varsa push, yoksa root olarak göster
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                    let sceneDelegate = windowScene.delegate as? SceneDelegate {
                    let nav = UINavigationController(rootViewController: vc)
                    sceneDelegate.window?.rootViewController = nav
                    sceneDelegate.window?.makeKeyAndVisible()
                }
            }
        }
    }
    
    @IBAction func didTapGoToRegister() {
        let vc = RegisterViewController(nibName: "RegisterViewController", bundle: nil)
        present(vc, animated: true)
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
