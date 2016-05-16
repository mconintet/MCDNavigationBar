//
//  ViewController.swift
//  MCDNavigationBarDemo
//
//  Created by mconintet on 5/11/16.
//  Copyright © 2016 mconintet. All rights reserved.
//

import UIKit
import WebKit
import MCDNavigationBar

class ViewController: UIViewController {
    let wv = WKWebView()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(wv)

        wv.translatesAutoresizingMaskIntoConstraints = false
        wv.topAnchor.constraintEqualToAnchor(view.topAnchor).active = true
        wv.leftAnchor.constraintEqualToAnchor(view.leftAnchor).active = true
        wv.widthAnchor.constraintEqualToAnchor(view.widthAnchor).active = true
        wv.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor).active = true

        wv.loadRequest(NSURLRequest(URL: NSURL(string: "https://www.baidu.com")!))
        wv.allowsBackForwardNavigationGestures = true

        let nav = self.navigationController?.navigationBar as! MCDNavigationBar
        nav.scrollView = wv.scrollView
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

