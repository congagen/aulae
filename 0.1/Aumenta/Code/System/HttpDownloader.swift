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
    

    func downloadFileSync(fURL: String, filename: String) -> String {
        
        let documentsUrl:URL =  (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first as URL?)!
        let destinationFileUrl = documentsUrl.appendingPathComponent(filename)
        
        let fileURL = URL(string: fURL)
        
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        let request = URLRequest(url:fileURL!)
        
        let task = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
            if let tempLocalUrl = tempLocalUrl, error == nil {
                
                if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                    print("Successfully downloaded. Status code: \(statusCode)")
                }
                
                do {
                    try FileManager.default.copyItem(at: tempLocalUrl, to: destinationFileUrl)
                    
                } catch (let writeError) {
                    print("Error creating a file \(destinationFileUrl) : \(writeError)")
                }
                
            } else {
                print("Error took place while downloading a file. Error description: %@", error?.localizedDescription as Any);
            }
        }
        task.resume()
        
        if (destinationFileUrl.isFileURL) {
            return destinationFileUrl.absoluteString
        } else {
            return ""
        }
    }
    
    
    @objc func completion(filePath: String) {
        print(filePath)
        print(filePath)
        print(filePath)
        print(filePath)
        print(filePath)
        print(filePath)
    }
    
    
//    func verifyUrl (url: NSURL) -> Bool {
//        //Check for nil
//        var exists: Bool = false
//        let request: NSMutableURLRequest = NSMutableURLRequest(url: url as URL)
//        request.httpMethod = "HEAD"
//        let response: URLResponse = URLResponse()
//
//        if let httpResponse = response as? HTTPURLResponse {
//            if httpResponse.statusCode == 200 {
//                exists =  true
//            }else{
//                exists  = false
//            }
//        }
//        return exists
//    }
    

    func load(url: URL, completion: @escaping () -> ()) {
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        
        let request = try! URLRequest(url: url, cachePolicy: .reloadRevalidatingCacheData)
        
        let task = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
            if let tempLocalUrl = tempLocalUrl, error == nil {
                // Success
                if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                    print("Success: \(statusCode)")
                }
                
                let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! as NSURL
                //let destinationUrl = documentsUrl.appendingPathComponent(url.lastPathComponent)
                let destinationUrl = documentsUrl.appendingPathComponent(".json")
                
//                if FileManager.default.fileExists(atPath: destinationUrl!.path) {
//                    try! FileManager.default.removeItem(at: destinationUrl!)
//                }
            
                do {
                    try FileManager.default.copyItem(at: tempLocalUrl, to: destinationUrl!)
                    completion()
                } catch (let writeError) {
                    print(writeError)
                }
                
            } else {
                print(error)
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
                let error = NSError(domain:"Error saving file", code:1001, userInfo:nil)
                completion(destinationUrl!.path, error)
            }
        } else {
            let error = NSError(domain:"Error downloading file", code:1002, userInfo:nil)
            completion(destinationUrl!.path, error)
        }
    }
    
    
    static func loadFileAsync(url: URL, completion: @escaping (String?, Error?) -> Void) {
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationUrl = documentsUrl.appendingPathComponent(url.lastPathComponent)
        
        if FileManager().fileExists(atPath: destinationUrl.path)
        {
            completion(destinationUrl.path, nil)
        }
        else
        {
            let session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: nil)
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            
            let task = session.dataTask(with: request, completionHandler:
            {
                data, response, error in
                if error == nil
                {
                    if let response = response as? HTTPURLResponse
                    {
                        if response.statusCode == 200
                        {
                            if let data = data
                            {
                                if let _ = try? data.write(to: destinationUrl, options: Data.WritingOptions.atomic)
                                {
                                    completion(destinationUrl.path, error)
                                }
                                else
                                {
                                    completion(destinationUrl.path, error)
                                }
                            }
                            else
                            {
                                completion(destinationUrl.path, error)
                            }
                        }
                    }
                }
                else
                {
                    completion(destinationUrl.path, error)
                }
            })
            task.resume()
        }
    }
    
    
}
