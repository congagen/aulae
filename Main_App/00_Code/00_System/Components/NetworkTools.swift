//
//  NetworkTools.swift
//  aulae
//
//  Created by Tim Sandgren on 2019-02-23.
//  Copyright © 2019 Abstraqata. All rights reserved.
//

import Foundation


class NetworkTools {
    
    func postReq(completion: @escaping (_ resp: Dictionary<String, AnyObject>) -> (), apiHeaderValue: String, apiHeaderFeild: String, apiUrl: String, reqParams: Dictionary<String, String>) {
        print("postReq")

        if URL(string: apiUrl) != nil {
            var request: URLRequest? = URLRequest(url: ( URL(string: apiUrl)!   ))
            
            if request != nil {
                if (apiHeaderValue != "" && apiHeaderFeild != "") {
                    request!.setValue(apiHeaderValue, forHTTPHeaderField: apiHeaderFeild)
                }
                
                request!.httpMethod = "POST"
                request!.httpBody = try? JSONSerialization.data(withJSONObject: reqParams, options: [])
                request!.addValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let urlSession = URLSession.shared
                let task = urlSession.dataTask(with: request!, completionHandler: { data, response, error -> Void in
                    do {
                        if data != nil {
                            let json = try JSONSerialization.jsonObject(with: data!)
                            if let resp = json as? Dictionary<String, AnyObject> {
                                completion(resp)
                            }
                        }
                    } catch {
                        print(error)
                    }
                })
                
                task.resume()
            }
        }
        
        
    }

    
}
