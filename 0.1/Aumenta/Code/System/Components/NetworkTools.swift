//
//  NetworkTools.swift
//  Aumenta
//
//  Created by Tim Sandgren on 2019-02-23.
//  Copyright © 2019 Abstraqata. All rights reserved.
//

import Foundation


class NetworkTools {
    
    func postReq(apiHeaderValue:String, apiHeaderFeild:String, apiUrl: String, reqParams: Dictionary<String, String>) -> Dictionary<String, AnyObject> {
        var resp: Dictionary<String, AnyObject> = [:]
        
        var request = URLRequest(url: URL(string: apiUrl)!)
        request.setValue(apiHeaderValue, forHTTPHeaderField: apiHeaderFeild)
        
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: reqParams, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
            
            do {
                let json = try JSONSerialization.jsonObject(with: data!)
                resp = json as! Dictionary<String, AnyObject>
            } catch {
                print("error")
            }
            
        })
        
        task.resume()
        return resp
    }
    
}
