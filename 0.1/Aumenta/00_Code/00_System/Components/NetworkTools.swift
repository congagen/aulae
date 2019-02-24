//
//  NetworkTools.swift
//  Aumenta
//
//  Created by Tim Sandgren on 2019-02-23.
//  Copyright © 2019 Abstraqata. All rights reserved.
//

import Foundation


class NetworkTools {
    
    func postReq(completion: @escaping (_ resp: Dictionary<String, AnyObject>) -> (), apiHeaderValue: String, apiHeaderFeild: String, apiUrl: String, reqParams: Dictionary<String, String>) {
        print("postReq")

        var resp: Dictionary<String, AnyObject> = [:]
        var request = URLRequest(url: URL(string: apiUrl)!)
        
        if (apiHeaderValue != "" && apiHeaderFeild != "") {
            request.setValue(apiHeaderValue, forHTTPHeaderField: apiHeaderFeild)
        }
        
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: reqParams, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
            
            do {
                if data != nil {
                    let json = try JSONSerialization.jsonObject(with: data!)
                    resp = json as! Dictionary<String, AnyObject>
                    completion(resp)
                }
            } catch {
                print("error")
            }
            
        })
        
        task.resume()
    }
    
}
