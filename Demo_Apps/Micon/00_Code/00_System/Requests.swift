//
//  Requests.swift
//  MeIcon
//
//  Created by Tim Sandgren on 2018-11-21.
//  Copyright © 2018 Tim Sandgren. All rights reserved.
//

import Foundation


class Requests {
    
    func Call(params: Dictionary<String, String>, url:String) -> Dictionary<String, AnyObject> {
        
        var rslt = Dictionary<String, AnyObject>()
        
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
            print(response!)
            do {
                rslt = try JSONSerialization.jsonObject(with: data!) as! Dictionary<String, AnyObject>
                print(rslt)
            } catch {
                print("error")
            }
        })
        
        task.resume()
        
        return rslt

    }
    
    
}
