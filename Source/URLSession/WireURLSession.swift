//
//  WireURLSession.swift
//  ZMTransport
//
//  Created by Marco Conti on 17/10/16.
//  Copyright © 2016 Wire. All rights reserved.
//

import Foundation

import Foundation
import ZMCSystem

public let WireURLSessionBackgroundIdentifier: String = "com.wire.zmessaging"

@objc public class WireURLSession : NSObject {
    
    let taskIdentifierToRequest = ZMTaskIdentifierMap()
    let taskIdentifierToTimeoutTimer = ZMTaskIdentifierMap()
    let taskIdentifierToData = ZMTaskIdentifierMap()

    fileprivate weak var delegate : WireURLSessionDelegate?
    
    fileprivate(set) var identifier : String!

    private let backingSession : URLSession

    private var temporaryFiles = TemporaryFileListForBackgroundRequests()

    private var tornDown : Bool = false
    
    
    public init(configuration: URLSessionConfiguration,
                            delegate: WireURLSessionDelegate,
                            delegateQueue queue: OperationQueue,
                            identifier: String) {
        self.delegate = delegate
        self.identifier = identifier
        self.backingSession = URLSession(configuration: configuration, delegate: self, delegateQueue: queue)
    }
    
    deinit {
        if !self.tornDown {
            fatal("Did not tear down \(type(of: self))")
        }
    }
    
    public func tearDown() {
        self.cancelAndRemoveAllTimers()
        self.backingSession.invalidateAndCancel()
        self.tornDown = true
    }
}

extension WireURLSession {
    
    open func setTimeoutTimer(_ timer: ZMTimer, for task: URLSessionTask)
    
    
    open func cancelAndRemoveAllTimers()
    
    open func cancelAllTasks(completionHandler handler: @escaping () -> Swift.Void)
    
    open func countTasks(completionHandler handler: @escaping (UInt) -> Swift.Void)
    
    open func getTasksWithCompletionHandler(_ completionHandler: @escaping ([URLSessionTask]) -> Swift.Void)
    
    open func tearDown()
    
    
    /// The completion handler will be called with YES if the task was cancelled.
    open func cancelTask(withIdentifier taskIdentifier: UInt, completionHandler handler: (@escaping (Bool) -> Swift.Void)? = nil)
    
    open var configuration: URLSessionConfiguration { get }
}

extension WireURLSession {
    
    
    open var isBackgroundSession: Bool { get }
    
    open func task(with request: URLRequest, bodyData: Data?, transportRequest request: ZMTransportRequest?) -> URLSessionTask?
}

public protocol WireURLSessionDelegate : class {
    
    public func urlSession(_ URLSession: ZMURLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Swift.Void)
    
    public func urlSessionDidReceiveData(_ URLSession: ZMURLSession)
    
    public func urlSession(_ URLSession: ZMURLSession, taskDidComplete task: URLSessionTask, transportRequest: ZMTransportRequest, responseData: Data)
    
    
    public func urlSessionDidFinishEvents(forBackgroundURLSession URLSession: ZMURLSession)
}
