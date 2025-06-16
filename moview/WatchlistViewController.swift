//
//  WatchlistViewController.swift
//  moview
//
//  Created by АИДА on 16.06.2025.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class WatchlistViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!

    var watchlist: [WatchlistMovie] = []
        
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        fetchWatchlist()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchWatchlist()
    }
    
    func fetchWatchlist() {
            guard let userUID = Auth.auth().currentUser?.uid else {
                print("Kullanıcı oturum açmamış veya UID yok.")
                return
            }

            let db = Firestore.firestore()
            db.collection("users").document(userUID).collection("watchlist")
                .getDocuments { snapshot, error in
                    if let error = error {
                        print("Watchlist alma hatası: \(error.localizedDescription)")
                        return
                    }

                    self.watchlist = snapshot?.documents.compactMap { doc in
                        let data = doc.data()

                        // Guard let yerine doğrudan nil döndürüyoruz
                        guard let title = data["title"] as? String,
                              let poster = data["poster"] as? String,
                              let year = data["year"] as? String else {
                            print("Eksik veri: \(doc.documentID) - \(data)")
                            return nil
                        }

                        let movieID = doc.documentID
                        return WatchlistMovie(movieID: movieID, title: title, posterURL: poster, year: year)
                    } ?? []

                    print("Çekilen Watchlist Filmleri: \(self.watchlist.map { $0.title })")

                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
        }
    

        // MARK: TableView

        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return watchlist.count
        }

        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let movie = watchlist[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath)
            cell.textLabel?.text = movie.title
            return cell
        }
}

struct WatchlistMovie {
    let movieID: String
    let title: String
    let posterURL: String
    let year: String
}
