//
//  ViewController.swift
//  moview
//
//  Created by АИДА on 1.06.2025.
//

import UIKit
import SafariServices

var suggestedMovies: [Movie] = []
var isSearching = false

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {

    @IBOutlet var table: UITableView!
    @IBOutlet var field: UITextField!
    
    
    var  movies = [Movie]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        table.register(MovieTableViewCell.nib(), forCellReuseIdentifier: MovieTableViewCell.identifier)
        table.dataSource = self
        table.delegate = self
        field.delegate = self
        
        loadSuggestions()
    }
    
    //Field
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        isSearching = true
        searchMovies()
        return true
    }

    func textFieldDidChangeSelection(_ textField: UITextField) {
        if let text = textField.text, text.isEmpty {
            isSearching = false
            table.reloadData()
        }
    }

    func searchMovies() {
        field.resignFirstResponder()
        
        guard let text = field.text, !text.isEmpty else {
            return
        }
        
        let query = text.replacingOccurrences(of: " ", with: "%20")
        
        movies.removeAll()
        
        URLSession.shared.dataTask(with: URL(string: "https://www.omdbapi.com/?apikey=7932d64a&s=\(query)")!, completionHandler: {data, response, error in
            
            guard let data = data, error == nil else {
                return
            }
            
            //Convert the data
            var result: MovieResult?
            do {
                result = try JSONDecoder().decode(MovieResult.self, from: data)
            }
            catch {
                print("error")
            }
            
            guard let finalResult = result else {
                return
            }
            
            
            //Update our movies array
            let newMovies = finalResult.Search
            self.movies.append(contentsOf: newMovies)
            
            //Refresh our table
            DispatchQueue.main.async {
                self.table.reloadData()
            }
        }).resume()
    }
    
    //Table
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearching ? movies.count : suggestedMovies.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MovieTableViewCell.identifier, for: indexPath) as! MovieTableViewCell
        let movie = isSearching ? movies[indexPath.row] : suggestedMovies[indexPath.row]
        cell.configure(with: movie)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedMovie = isSearching ? movies[indexPath.row] : suggestedMovies[indexPath.row]
        let detailVC = MovieDetailViewController(nibName: "MovieDetailViewController", bundle: nil)
        detailVC.imdbID = selectedMovie.imdbID
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    func loadSuggestions() {
        let keywords = ["batman", "harry potter", "avengers", "inception", "matrix"]
        suggestedMovies.removeAll()

        let group = DispatchGroup()

        for keyword in keywords {
            group.enter()
            let query = keyword.replacingOccurrences(of: " ", with: "%20")
            guard let url = URL(string: "https://www.omdbapi.com/?apikey=7932d64a&s=\(query)") else {
                group.leave()
                continue
            }

            URLSession.shared.dataTask(with: url) { data, response, error in
                defer { group.leave() }

                guard let data = data, error == nil else {
                    return
                }

                do {
                    let result = try JSONDecoder().decode(MovieResult.self, from: data)
                    // İlk 2 filmi ekle (varsa)
                    suggestedMovies.append(contentsOf: result.Search.prefix(2))
                } catch {
                    print("Decoding failed for keyword: \(keyword)")
                }
            }.resume()
        }

        group.notify(queue: .main) {
            self.table.reloadData()
        }
    }

}

struct MovieResult: Codable {
    let Search: [Movie]
}

struct Movie: Codable {
    let Title: String
    let Year: String
    let imdbID: String
    let _Type: String
    let Poster: String
    
    private enum CodingKeys: String, CodingKey {
        case Title, Year, imdbID, _Type = "Type", Poster
    }
}
