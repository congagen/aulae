//
//  HttpDownloader.swift
//  ArkitTest
//
//  Created by Tim Sandgren on 2018-05-19.
//  Copyright © 2018 Abstraqata. All rights reserved.
//

import Foundation


class HttpDownloader {
    

    func deviceRemainingFreeSpaceInBytes() -> Int64? {
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last!
        guard
            let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: documentDirectory),
            let freeSize = systemAttributes[.systemFreeSize] as? NSNumber
            else {
                return nil
        }
        return freeSize.int64Value
    }
    
    
    func loadFileAsync(removeExisting: Bool, url: URL, destinationUrl: URL, completion: @escaping () -> ()) {
        let sessionConfig = URLSessionConfiguration.default
        let urlSession = URLSession(configuration: sessionConfig)
        let request = URLRequest(url: url, cachePolicy: .reloadRevalidatingCacheData)

        if removeExisting && FileManager.default.fileExists(atPath: destinationUrl.path) {
            do {
                try FileManager.default.removeItem(atPath: destinationUrl.path )
            } catch let error {
                print("\(error)")
            }
        }
        
        let task = urlSession.downloadTask(with: request) { (tempLocalUrl, response, error) in
            if let tempLocalUrl = tempLocalUrl, error == nil {

                if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                    print("Success: \(statusCode)")
                }
                
                do {
                    if !FileManager.default.fileExists(atPath: destinationUrl.path) {
                        try FileManager.default.copyItem(at: tempLocalUrl, to: destinationUrl)
                    } else {
                        _ = try FileManager.default.replaceItemAt(destinationUrl, withItemAt: tempLocalUrl)
                    }
                    completion()
                } catch (let writeError) {
                    print(writeError)
                }
                
            } else {
                print(error!)
                print(url.absoluteString)
            }
        }
        task.resume()
        
    }

    
    func loadFileSync(url: NSURL, completion:(_ path:String, _ error:NSError?) -> Void) {
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as NSURL
        let destinationUrl = documentsUrl.appendingPathComponent(url.lastPathComponent!)
        if FileManager().fileExists(atPath: destinationUrl!.path) {
            completion(destinationUrl!.path, nil)
        } else if let dataFromURL = NSData(contentsOf: url as URL){
            if dataFromURL.write(to: destinationUrl!, atomically: true) {
                completion(destinationUrl!.path, nil)
            } else {
                let error = NSError(domain:"Error saving file", code:1001, userInfo: nil)
                completion(destinationUrl!.path, error)
            }
        } else {
            let error = NSError(domain:"Error downloading file", code:1002, userInfo: nil)
            completion(destinationUrl!.path, error)
        }
    }
    
    
}
