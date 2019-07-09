//
//  NetworkTools.swift
//  aulae
//
//  Created by Tim Sandgren on 2019-02-23.
//  Copyright © 2019 Abstraqata. All rights reserved.
//

import Foundation


extension String {
    func toJSON() -> Any? {
        guard let data = self.data(using: .utf8, allowLossyConversion: false) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
    }
}


class NetworkTools {
    
    func postReq(completion: @escaping (_ resp: Dictionary<String, AnyObject>) -> (), apiHeaderValue: String, apiHeaderFeild: String, apiUrl: String, reqParams: Dictionary<String, String>) {
        print("postReq")

        if URL(string: apiUrl) != nil {
            var request: URLRequest? = URLRequest(url: ( URL(string: apiUrl)! ))
            
            if request != nil {
                print(request!)

                if (apiHeaderValue != "" && apiHeaderFeild != "") {
                    request!.setValue(apiHeaderValue, forHTTPHeaderField: apiHeaderFeild)
                }
                
                request!.httpMethod = "POST"
                request!.httpBody = try? JSONSerialization.data(withJSONObject: reqParams, options: [])
                // request!.addValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let urlSession = URLSession.shared
                let task = urlSession.dataTask(with: request!, completionHandler: { data, response, error -> Void in
                    do {
                        if data != nil {
                            let d_json = try JSONSerialization.jsonObject(with: data!)
                            
                            if let resp = d_json as? Dictionary<String, AnyObject> {
                                completion(resp)
                            }
                        }
                    } catch {
                        print("ERROR")
                        print(error)
                    }
                })
                print(task)
                task.resume()
            } else {
                print("Error: request == nil")
            }
        }
    }

    
}
