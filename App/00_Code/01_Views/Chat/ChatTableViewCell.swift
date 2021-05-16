//
//  ChatTableViewCell.swift
//  Aulae
//
//  Created by Tim Sandgren on 2019-06-06.
//  Copyright © 2019 Tim Sandgren. All rights reserved.
//

import UIKit

class ChatTableViewCell: UITableViewCell {
    
    let curAgentName = ""
    let messageLabel = UILabel()
    let bubbleBackgroundView = UIView()
    
    var leadingConstraint:  NSLayoutConstraint!
    var trailingConstraint: NSLayoutConstraint!
    
    var outBubbleColor       = UIColor(displayP3Red: 1.0, green: 1.0, blue: 1.0, alpha: 0.9)
    var incommingBubbleColor = UIColor(displayP3Red: 1.0, green: 1.0, blue: 1.0, alpha: 0.9)
    
    var isIncomming: Bool! {
        didSet {
            bubbleBackgroundView.backgroundColor = isIncomming ? incommingBubbleColor : outBubbleColor
            leadingConstraint.isActive = !isIncomming
            trailingConstraint.isActive = isIncomming
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        bubbleBackgroundView.backgroundColor = .yellow
        bubbleBackgroundView.layer.cornerRadius = 5
        bubbleBackgroundView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(bubbleBackgroundView)

        addSubview(messageLabel)
        messageLabel.backgroundColor = .clear
        messageLabel.text = "Message"
        messageLabel.textColor = UIColor.darkGray
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
    
        
        let const = [
            messageLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            messageLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            messageLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 250),
        
            bubbleBackgroundView.topAnchor.constraint(equalTo: messageLabel.topAnchor, constant: -8),
            bubbleBackgroundView.leadingAnchor.constraint(equalTo: messageLabel.leadingAnchor, constant: -16),
            bubbleBackgroundView.bottomAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 8),
            bubbleBackgroundView.trailingAnchor.constraint(equalTo: messageLabel.trailingAnchor, constant: 16)
        ]
    
        NSLayoutConstraint.activate(const)
        
        leadingConstraint = messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24)
        trailingConstraint = messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
