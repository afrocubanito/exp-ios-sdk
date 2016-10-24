//
//  ResponseCollection.swift
//  Pods
//
//  Created by Cesar on 9/8/15.
//
//

import Foundation
import Alamofire


public protocol ResponseCollection {
    static func collection(response: HTTPURLResponse, representation: AnyObject) -> [Self]
}

extension Alamofire.Request {
    public func responseCollection<T: ResponseCollection>(_ completionHandler: (Response<SearchResults<T>, NSError>) -> Void) -> Self {
        
        let responseSerializer = ResponseSerializer<SearchResults<T>, NSError> { request, response, data, error in
            guard error == nil else { return .Failure(error!) }
            
            let JSONSerializer = Request.JSONResponseSerializer(options: .AllowFragments)
            let result = JSONSerializer.serializeResponse(request, response, data, error)
            
            switch result {
            case .Success(let value):
                if let response = response {
                    let dic = value as! NSDictionary
                    if let _ = dic.objectForKey("code") as? String{
                        let failureReason = dic.objectForKey("message") as! String
                        let error = Error.errorWithCode(.JSONSerializationFailed, failureReason: failureReason)
                        return .Failure(error)
                    }
                    let results: AnyObject? = dic.objectForKey("results")
                    let total: Int64 = (dic.objectForKey("total") as! NSNumber).longLongValue
                    let collection: [T] = T.collection(response: response, representation: results!)
                    let searchResults = SearchResults<T>(results: collection, total: total)
                    return .Success(searchResults!)
                } else {
                    let failureReason = "Response collection could not be serialized due to nil response"
                    let error = Error.errorWithCode(.JSONSerializationFailed, failureReason: failureReason)
                    return .Failure(error)
                }
            case .Failure(let error):
                return .Failure(error)
            }
        }
        return response(responseSerializer: responseSerializer, completionHandler: completionHandler)

    }
}