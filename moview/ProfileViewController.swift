//
//  ProfileViewController.swift
//  moview
//
//  Created by АИДА on 16.06.2025.
//

import UIKit
import FirebaseAuth

class ProfileViewController: UIViewController {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Profil fotoğrafı (sistemden)
        profileImageView.image = UIImage(systemName: "person.crop.circle")
        profileImageView.tintColor = .systemGray // isteğe bağlı
        
        loadUserInfo()
    }
    
    @IBAction func didTapLogout(_ sender: UIButton) {
        do {
            try Auth.auth().signOut()
            
            // LoginVC'yi XIB'den oluştur
            let loginVC = LoginViewController(nibName: "LoginViewController", bundle: nil)
            loginVC.modalPresentationStyle = .fullScreen // isteğe bağlı: tam ekran olarak göster

            self.present(loginVC, animated: true)
            
        } catch let signOutError as NSError {
            print("Çıkış hatası: %@", signOutError)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
        profileImageView.clipsToBounds = true
    }

    func loadUserInfo() {
        if let user = Auth.auth().currentUser {
            nameLabel.text = "Ad Soyad: \(user.displayName ?? "-")"
            emailLabel.text = "E-posta: \(user.email ?? "-")"
        } else {
            nameLabel.text = "Ad Soyad: Giriş yapılmamış"
            emailLabel.text = "E-posta: Giriş yapılmamış"
        }
    }
}
