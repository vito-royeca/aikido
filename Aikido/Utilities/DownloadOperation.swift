//
//  DownloadOperation.swift
//  Aikido
//
//  Created by Vito Royeca on 4/1/25.
//

import Foundation

class DownloadOperation: Operation, @unchecked Sendable {
    
    private var task : URLSessionDownloadTask!
    
    enum OperationState : Int {
        case ready
        case executing
        case finished
    }
    
    private var state : OperationState = .ready {
        willSet {
            self.willChangeValue(forKey: "isExecuting")
            self.willChangeValue(forKey: "isFinished")
        }
        
        didSet {
            self.didChangeValue(forKey: "isExecuting")
            self.didChangeValue(forKey: "isFinished")
        }
    }
    
    override var isReady: Bool { return state == .ready }
    override var isExecuting: Bool { return state == .executing }
    override var isFinished: Bool { return state == .finished }
  
    init(session: URLSession,
         downloadTaskURL: URL,
         completionHandler: ((URL?, URLResponse?, Error?) -> Void)?) {
        super.init()
        
        task = session.downloadTask(with: downloadTaskURL, completionHandler: { [weak self] (localURL, response, error) in
            
            if let completionHandler = completionHandler {
                completionHandler(localURL, response, error)
            }
            self?.state = .finished
        })
        
//        task = session.downloadTask(with: downloadTaskURL)
    }

    override func start() {
        if(self.isCancelled) {
            state = .finished
            return
        }
      
        state = .executing
      
        print("downloading: \(task.originalRequest?.url?.absoluteString ?? "")")
        task.resume()
    }

    override func cancel() {
        super.cancel()
        task.cancel()
    }
}
