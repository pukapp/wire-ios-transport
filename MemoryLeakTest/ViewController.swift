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
    let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.moc.createDispatchGroups()
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
            mainGroupQueue: self.moc,
            initialAccessToken: ZMAccessToken(),
            application: nil, sharedContainerIdentifier: nil)
        
        let request = ZMTransportRequest.init(path: "self", method: .methodGET, payload: nil, authentication: .none)
        request.add(ZMCompletionHandler(on: moc) {
            print($0)
        })
        self.session?.attemptToEnqueueSyncRequest(generator: { return request })

    }
    @IBAction func onTapDestroy(_ sender: Any) {
        self.session?.tearDown()
        self.session = nil
    }
}

