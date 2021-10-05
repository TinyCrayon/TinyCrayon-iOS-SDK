//
//  WebViewController.swift
//  TinyCrayon
//
//  Created by Xin Zeng on 6/2/16.
//
//

import UIKit

class WebViewController : UIViewController {
    
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var navBarTitle: UINavigationItem!
    @IBOutlet weak var webView: UIWebView!
    
    var urlString: String!
    var request: URLRequest!
    
    override func viewDidLoad() {
//        webView.scalesPageToFit = true
       
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if (request == nil) {
            let url = URL(string: urlString)!
            let request = URLRequest(url: url)
            webView.loadRequest(request)
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    func setup(_ urlStr: String) {
        self.urlString = urlStr
    }
    
    @IBAction func backButtonTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: {})
    }
    
}
