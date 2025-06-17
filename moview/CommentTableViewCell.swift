//
//  CommentTableViewCell.swift
//  moview
//
//  Created by АИДА on 17.06.2025.
//

import UIKit

class CommentTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var timeAgoLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        commentLabel.numberOfLines = 0
    }

    func configure(with comment: Comment) {
        nameLabel.text = comment.user
        timeAgoLabel.text = comment.timeAgo
        commentLabel.text = comment.text
    }

    static let identifier = "CommentTableViewCell"

    static func nib() -> UINib {
        return UINib(nibName: "CommentTableViewCell", bundle: nil)
    }
}
