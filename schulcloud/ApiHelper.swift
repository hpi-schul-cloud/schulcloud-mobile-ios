//
//  ApiHelper.swift
//  schulcloud
//
//  Created by Carl Gödecken on 12.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import Alamofire
import BrightFutures
import Marshal

class ApiHelper {
    
    static func request(
        _ endpoint: String,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = URLEncoding.default,
        additionalHeaders: HTTPHeaders? = nil,
        authenticated: Bool = true) -> Alamofire.DataRequest {
        
        let urlString = Constants.backend.url.absoluteString.appending(endpoint)
        var headers = authenticated ? ["Authorization": Globals.account!.accessToken!] : HTTPHeaders()
        
        if let additionalHeaders = additionalHeaders {
            for (key, value) in additionalHeaders {
                headers.updateValue(value, forKey: key)
            }
        }
        return Alamofire.request(urlString, method: method, parameters: parameters, encoding: encoding, headers: headers)
    }
    
    static func requestBasic(
        _ endpoint: String,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = URLEncoding.default,
        additionalHeaders: HTTPHeaders? = nil,
        authenticated: Bool = true) -> Future<DefaultDataResponse, SCError> {
        
        
        let promise = Promise<DefaultDataResponse, SCError>()
        request(endpoint, method: method, parameters: parameters, encoding: encoding, additionalHeaders: additionalHeaders, authenticated: authenticated).response { (response: DefaultDataResponse) in
            promise.success(response)
        }
        
        return promise.future
    }
    
}

extension Alamofire.DataRequest {
    
    public func dataFuture(queue: DispatchQueue? = nil) -> Future<Data, SCError> {
        let promise = Promise<Data, SCError>()
        
        let completionHandler: ((DefaultDataResponse) -> Void) = { (response: DefaultDataResponse) -> Void in
            guard let data = response.data else {
                promise.failure(SCError.network(response.error))
                return
            }
            promise.success(data)
        } 
        
        response(queue: queue, completionHandler: completionHandler)
        
        return promise.future
    }
    
    public func deserialize<T: Unmarshaling>(keyPath: String, queue: DispatchQueue? = nil) -> Future<T, SCError> {
        let promise = Promise<T, SCError>()
        
        let completionHandler: ((DefaultDataResponse) -> Void) = { (response: DefaultDataResponse) -> Void in
            guard let data = response.data else {
                promise.failure(SCError.network(response.error))
                return
            }
            guard let deserialized = try? JSONSerialization.jsonObject(with: data, options: []),
                let json = deserialized as? [String: Any] else {
                promise.failure(.jsonDeserialization(nil))
                return
            }
            do {
                let object: T = try json.value(for: keyPath)
                promise.success(object)
            } catch let error {
                promise.failure(.jsonDeserialization(error))
            }
        }
        
        response(queue: queue, completionHandler: completionHandler)
        
        return promise.future
    }
    
    public func deserialize<T: Unmarshaling>(keyPath: String, queue: DispatchQueue? = nil) -> Future<[T], SCError> {
        let promise = Promise<[T], SCError>()
        
        let completionHandler: ((DefaultDataResponse) -> Void) = { (response: DefaultDataResponse) -> Void in
            guard let data = response.data else {
                promise.failure(SCError.network(response.error))
                return
            }
            guard let deserialized = try? JSONSerialization.jsonObject(with: data, options: []),
                let json = deserialized as? [String: Any] else {
                    promise.failure(.jsonDeserialization(nil))
                    return
            }
            do {
                let object: [T] = try json.value(for: keyPath)
                promise.success(object)
            } catch let error {
                promise.failure(.jsonDeserialization(error))
            }
        }
        
        response(queue: queue, completionHandler: completionHandler)
        
        return promise.future
    }
    
}
