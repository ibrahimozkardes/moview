//
//  ChatViewController.swift
//  moview
//
//  Created by АИДА on 17.06.2025.
//

import UIKit

enum Sender {
    case user
    case bot
}

struct Message {
    let text: String
    let sender: Sender
}

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var chatTableView: UITableView!
    @IBOutlet weak var messageField: UITextField!

    var messages: [Message] = [
        Message(text: "Merhaba! Size nasıl yardımcı olabilirim?", sender: .bot)
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        chatTableView.delegate = self
        chatTableView.dataSource = self
        chatTableView.separatorStyle = .none
    }

    // MARK: - UITableView DataSource & Delegate

    func numberOfSections(in tableView: UITableView) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 5
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let spacer = UIView()
        spacer.backgroundColor = .clear
        return spacer
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.section]

        let cell = UITableViewCell()
        cell.selectionStyle = .none
        cell.backgroundColor = .clear

        let bubbleView = UIView()
        bubbleView.layer.cornerRadius = 15
        bubbleView.layer.masksToBounds = true

        switch message.sender {
        case .user:
            bubbleView.backgroundColor = UIColor(red: 64/255, green: 64/255, blue: 64/255, alpha: 0.9)
        case .bot:
            bubbleView.backgroundColor = .systemGray6
        }

        let messageLabel = UILabel()
        messageLabel.numberOfLines = 0
        messageLabel.font = .systemFont(ofSize: 16)
        messageLabel.text = message.text

        switch message.sender {
        case .user:
            messageLabel.textColor = .white
            messageLabel.textAlignment = .right
        case .bot:
            messageLabel.textColor = .black
            messageLabel.textAlignment = .left
        }

        bubbleView.addSubview(messageLabel)
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        cell.contentView.addSubview(bubbleView)

        let horizontalPadding: CGFloat = 16
        let verticalPadding: CGFloat = 8
        let maxBubbleWidth = tableView.frame.width * 0.7

        if message.sender == .user {
            NSLayoutConstraint.activate([
                bubbleView.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: verticalPadding),
                bubbleView.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -horizontalPadding),
                bubbleView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -verticalPadding),
                bubbleView.widthAnchor.constraint(lessThanOrEqualToConstant: maxBubbleWidth),

                messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 8),
                messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
                messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
                messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -8),
            ])
        } else {
            NSLayoutConstraint.activate([
                bubbleView.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: verticalPadding),
                bubbleView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: horizontalPadding),
                bubbleView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -verticalPadding),
                bubbleView.widthAnchor.constraint(lessThanOrEqualToConstant: maxBubbleWidth),

                messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 8),
                messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
                messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
                messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -8),
            ])
        }

        return cell
    }

    // MARK: - Mesaj Gönderme

    @IBAction func didTapSend(_ sender: UIButton) {
        guard let message = messageField.text, !message.isEmpty else { return }

        messages.append(Message(text: message, sender: .user))
        chatTableView.reloadData()
        scrollToBottom()
        messageField.text = ""

        fetchBotReply(for: message)
    }

    func scrollToBottom() {
        let lastSection = messages.count - 1
        guard lastSection >= 0 else { return }
        let indexPath = IndexPath(row: 0, section: lastSection)
        chatTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }

    // MARK: - API Çağrısı

    func fetchBotReply(for prompt: String) {
        let apiKey = "AIzaSyBX9h8mQ3F7i9ZHx0DlEBABC87Nw2wY_EQ"
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = [
            "contents": [
                ["parts": [["text": prompt]]]
            ]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            print("Error encoding request: \(error)")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                print("API Error: \(error?.localizedDescription ?? "Unknown")")
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let candidates = json?["candidates"] as? [[String: Any]],
                   let content = candidates.first?["content"] as? [String: Any],
                   let parts = content["parts"] as? [[String: Any]],
                   let replyText = parts.first?["text"] as? String {
                    
                    DispatchQueue.main.async {
                        let cleanedReply = replyText
                            .replacingOccurrences(of: "**", with: "")
                            .replacingOccurrences(of: "*", with: "• ")
                            .replacingOccurrences(of: "\n\n", with: "\n")
                            .replacingOccurrences(of: "\n", with: "\n\n")

                        self.messages.append(Message(text: cleanedReply, sender: .bot))
                        self.chatTableView.reloadData()
                        self.scrollToBottom()
                    }
                } else {
                    print("Response parsing failed")
                }
            } catch {
                print("Decoding error: \(error)")
            }

        }.resume()
    }
}

struct GeminiRequest: Codable {
    let contents: [Content]
}

struct Content: Codable {
    let parts: [Part]
    let role: String
}

struct Part: Codable {
    let text: String
}

struct GeminiResponse: Codable {
    let candidates: [Candidate]
}

struct Candidate: Codable {
    let content: Content
}
