//
//  CommentsViewModel.swift
//  weekly
//
//  Created by Cooper Senior on 1/20/25.
//

import Foundation
import UIKit
import SwiftUI

class CommentsViewModel: UIViewController {
    let post: Post
    
    init(post: Post) {
        self.post = post
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        // return nil if not using a storyboard
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Create the SwiftUI view
        let commentsView = CommentsView(post: post)
        
        // Create a UIHostingController with your SwiftUI view
        let hostingController = UIHostingController(rootView: commentsView)
        
        // Add the hostingController as a child view controller
        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        // Set up layout constraints for the SwiftUI view
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
