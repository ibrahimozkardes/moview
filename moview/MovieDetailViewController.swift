import UIKit
import FirebaseAuth
import FirebaseFirestore

struct MovieDetail: Codable {
    let Title: String
    let Year: String
    let Genre: String
    let Director: String
    let Plot: String
    let Poster: String
    let imdbRating: String
}

struct Comment {
    let user: String
    let text: String
    let timestamp: Date
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

class MovieDetailViewController: UIViewController {
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var posterImageView: UIImageView!
    @IBOutlet var plotLabel: UILabel!
    @IBOutlet var infoLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var commentField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var watchlistButton: UIButton!
    
    var imdbID: String?
    var movie: MovieDetail?
    var comments: [Comment] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(CommentTableViewCell.nib(), forCellReuseIdentifier: CommentTableViewCell.identifier)
        
        fetchMovieDetail()
        fetchComments()
        checkWatchlistStatus()
    }
    
    func fetchMovieDetail() {
        guard let imdbID = imdbID,
              let url = URL(string: "https://www.omdbapi.com/?apikey=7932d64a&i=\(imdbID)") else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else { return }
            do {
                let movie = try JSONDecoder().decode(MovieDetail.self, from: data)
                DispatchQueue.main.async {
                    self.updateUI(with: movie)
                }
            } catch {
                print("Decode hatası: \(error)")
            }
        }.resume()
    }
    
    func updateUI(with movie: MovieDetail) {
        self.movie = movie
        titleLabel.text = movie.Title
        plotLabel.text = movie.Plot
        infoLabel.text = """
            Year: \(movie.Year)
            Genre: \(movie.Genre)
            Director: \(movie.Director)
            Rating: \(movie.imdbRating)
        """
        
        if let url = URL(string: movie.Poster) {
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: url) {
                    DispatchQueue.main.async {
                        self.posterImageView.image = UIImage(data: data)
                    }
                }
            }
        }
    }
    
    func fetchComments() {
        guard let imdbID = imdbID else { return }
        let db = Firestore.firestore()
        db.collection("comments")
            .whereField("movieID", isEqualTo: imdbID)
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Yorumları alma hatası: \(error.localizedDescription)")
                    return
                }
                guard let documents = snapshot?.documents else { return }
                self.comments = documents.compactMap { doc in
                    let data = doc.data()
                    let user = data["user"] as? String ?? "anonim"
                    let text = data["comment"] as? String ?? ""
                    let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                    return Comment(user: user, text: text, timestamp: timestamp)
                }
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
    }
    
    func saveCommentToFirestore(_ commentText: String) {
        guard let user = Auth.auth().currentUser,
              let imdbID = imdbID else { return }
        user.reload { error in
            if let error = error {
                print("Kullanıcı yeniden yüklenemedi: \(error.localizedDescription)")
                return
            }
            let displayName = Auth.auth().currentUser?.displayName ?? "anonim"
            let db = Firestore.firestore()
            let doc: [String: Any] = [
                "user": displayName,
                "comment": commentText,
                "timestamp": Timestamp(),
                "movieID": imdbID
            ]
            db.collection("comments").addDocument(data: doc) { error in
                if let error = error {
                    print("Yorum ekleme hatası: \(error.localizedDescription)")
                } else {
                    print("Yorum başarıyla kaydedildi")
                    self.fetchComments()
                }
            }
        }
    }
    
    func checkWatchlistStatus() {
        guard let imdbID = imdbID,
              let userID = Auth.auth().currentUser?.uid else { return }
        let ref = Firestore.firestore()
            .collection("users")
            .document(userID)
            .collection("watchlist")
            .document(imdbID)
        ref.getDocument { doc, _ in
            DispatchQueue.main.async {
                if doc?.exists == true {
                    self.watchlistButton.setTitle("✓ Watchlisted", for: .normal)
                } else {
                    self.watchlistButton.setTitle("+ Watchlist", for: .normal)
                }
            }
        }
    }
    
    @IBAction func didTapSendComment(_ sender: UIButton) {
        guard let text = commentField.text, !text.isEmpty else { return }
        saveCommentToFirestore(text)
        commentField.text = ""
    }
    
    @IBAction func didTapWatchlist(_ sender: UIButton) {
        guard let imdbID = imdbID,
              let userID = Auth.auth().currentUser?.uid,
              let movie = movie else { return }
        let db = Firestore.firestore()
        let watchlistRef = db.collection("users").document(userID).collection("watchlist").document(imdbID)
        watchlistRef.getDocument { doc, error in
            if let doc = doc, doc.exists {
                watchlistRef.delete { err in
                    if err == nil {
                        print("Watchlist'ten çıkarıldı")
                        DispatchQueue.main.async {
                            self.watchlistButton.setTitle("+ Watchlist", for: .normal)
                        }
                    }
                }
            } else {
                let movieData: [String: Any] = [
                    "title": movie.Title,
                    "year": movie.Year,
                    "poster": movie.Poster
                ]
                watchlistRef.setData(movieData) { err in
                    if err == nil {
                        print("Watchlist'e eklendi")
                        DispatchQueue.main.async {
                            self.watchlistButton.setTitle("✓ Watchlisted", for: .normal)
                        }
                    }
                }
            }
        }
    }
}

extension MovieDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let comment = comments[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CommentTableViewCell.identifier, for: indexPath) as? CommentTableViewCell else {
            return UITableViewCell()
        }
        cell.configure(with: comment)
        return cell
    }
}
