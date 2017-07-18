//
//  ViewController.swift
//  MemoryLeakTest
//
//  Created by Marco Conti on 17.07.17.
//  Copyright © 2017 Wire. All rights reserved.
//

import UIKit
import WireTransport

class ViewController: UIViewController {

    var session: ZMTransportSession? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func onTapCreate(_ sender: Any) {
        self.onTapDestroy(sender)
        self.session = ZMTransportSession(
            baseURL: URL(string: "https://staging-nginz-https.zinfra.io")!,
            websocketURL: URL(string: "https://staging-nginz-https.zinfra.io")!,
            mainGroupQueue: NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType),
            initialAccessToken: ZMAccessToken(),
            application: nil, sharedContainerIdentifier: nil)
        
    }
    @IBAction func onTapDestroy(_ sender: Any) {
        self.session?.tearDown()
        self.session = nil
    }
}

