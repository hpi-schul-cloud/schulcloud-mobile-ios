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
    
    static func updateData(includingAuthorization authorize: Bool = true) {
        DispatchQueue.global(qos: .utility).async {
            (authorize ? LoginHelper.renewAccessToken() : Future(value: Void()))
                .flatMap {
                    HomeworkHelper.fetchFromServer()
                }
                .onFailure { log.error($0) }
        }
    }
    
}

extension Alamofire.DataRequest {
    
    public func jsonArrayFuture(keyPath: String?) -> Future<[[String: Any]], SCError> {
        return self.responseJSONFuture().flatMap { json -> Future<[[String: Any]], SCError> in
            let array: [[String: Any]]?
            if let keyPath = keyPath {
                array = (json as? [String: Any])?[keyPath] as? [[String : Any]]
            } else {
                array = json as? [[String : Any]]
            }
            
            if let array = array {
                return Future(value: array)
            } else {
                return Future(error: .jsonDeserialization("Could not find array at keyPath \(keyPath ?? "nil")"))
            }
        }
    }
    
    public func jsonObjectFuture() -> Future<[String: Any], SCError> {
        return self.responseJSONFuture().flatMap { json -> Future<[String: Any], SCError> in
            if let object = json as? [String: Any] {
                return Future(value: object)
            } else {
                return Future(error: .jsonDeserialization("Could not cast \(json) to JSON object"))
            }
        }
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
                promise.failure(.jsonDeserialization("Not a dictionary"))
                return
            }
            do {
                let object: T = try json.value(for: keyPath)
                promise.success(object)
            } catch let error {
                promise.failure(.jsonDeserialization(error.localizedDescription))
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
                    promise.failure(.jsonDeserialization("Not a dictionary"))
                    return
            }
            do {
                let object: [T] = try json.value(for: keyPath)
                promise.success(object)
            } catch let error {
                promise.failure(.jsonDeserialization(error.localizedDescription))
            }
        }
        
        response(queue: queue, completionHandler: completionHandler)
        
        return promise.future
    }
    
}
