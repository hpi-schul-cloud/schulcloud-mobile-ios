//
//  Alamofire+BrightFutures.swift
//  Pods
//
//  Created by Carl Julius Gödecken on 26.05.17.
//
//

import Foundation
import Alamofire
import BrightFutures

// TODO: Move this to an independent pod as soon as conforming to Error using Error is supported
extension Alamofire.DataRequest {
    
    /// Returns a future that is completed once the request has finished.
    ///
    /// - parameter queue:             The queue on which the completion handler is dispatched.
    public func responseFuture(queue: DispatchQueue? = nil) -> Future<DefaultDataResponse, SCError> {
        let promise = Promise<DefaultDataResponse, SCError>()
        
        let completionHandler = { (response: DefaultDataResponse) -> Void in
            promise.success(response)
        }
        
        response(queue: queue, completionHandler: completionHandler)
        
        return promise.future
    }
    
    /// Returns a future that is completed once the request has finished.
    ///
    /// - parameter queue:              The queue on which the completion handler is dispatched.
    /// - parameter responseSerializer: The serializer responsible for serializing the response
    ///
    
    public func responseFuture<T: DataResponseSerializerProtocol, E: Error>(
        queue: DispatchQueue? = nil,
        responseSerializer: T)
        -> Future<DataResponse<T.SerializedObject>, E>
    {
        let promise = Promise<DataResponse<T.SerializedObject>, E>()
        
        let completionHandler = { (response: DataResponse<T.SerializedObject>) -> Void in
            promise.success(response)
        }
        
        response(queue: queue, responseSerializer: responseSerializer, completionHandler: completionHandler)
        
        return promise.future
    }
}

extension Alamofire.DownloadRequest {
    /// Returns a future that is completed once the request has finished. If no error occurs and no value is present, the future succeeds with a null value.
    ///
    /// - parameter queue:              The queue on which the completion handler is dispatched.
    ///
    public func responseDataFuture(queue: DispatchQueue? = nil) -> Future<Data, SCError> {
        let promise = Promise<Data, SCError>()
        
        let completionHandler = { (response: DownloadResponse<Data>) -> Void in
            if let error = response.error {
                promise.failure(.network(error))
            } else {
                promise.success(response.value ?? Data())
            }
        }
        
        responseData(queue: queue, completionHandler: completionHandler)
        
        return promise.future
    }
}

extension Alamofire.DataRequest {
    /// Returns a future that is completed once the request has finished. If no error occurs and no value is present, the future succeeds with a null value.
    ///
    /// - parameter queue:              The queue on which the completion handler is dispatched.
    ///
    public func responseDataFuture(queue: DispatchQueue? = nil) -> Future<Data, SCError> {
        let promise = Promise<Data, SCError>()
        
        let completionHandler = { (response: DataResponse<Data>) -> Void in
            switch response.result {
            case .success(let data):
                promise.success(data)
            case .failure(let error):
                promise.failure(.network(error))
            }
        }
        
        responseData(queue: queue, completionHandler: completionHandler)
        
        return promise.future
    }
    
    /// Returns a future that is completed once the request has finished. If no error occurs and no value is present, the future succeeds with a null value.
    ///
    /// - parameter queue:              The queue on which the completion handler is dispatched.
    ///
    public func responseStringFuture(queue: DispatchQueue? = nil) -> Future<String, SCError> {
        let promise = Promise<String, SCError>()
        
        let completionHandler = { (response: DataResponse<String>) -> Void in
            switch response.result {
            case .success(let str):
                promise.success(str)
            case .failure(let error):
                promise.failure(.network(error))
            }
        }
        
        responseString(queue: queue, completionHandler: completionHandler)
        
        return promise.future
    }
    
    /// Returns a future that is completed once the request has finished. If no error occurs and no value is present, the future succeeds with a null value.
    ///
    /// - parameter queue:              The queue on which the completion handler is dispatched.
    ///
    public func responseJSONFuture(queue: DispatchQueue? = nil, options: JSONSerialization.ReadingOptions = .allowFragments) -> Future<Any, SCError> {
        let promise = Promise<Any, SCError>()
        
        let completionHandler = { (response: DataResponse<Any>) -> Void in
            switch response.result {
            case .success(let json):
                promise.success(json)
            case .failure(let error):
                promise.failure(.network(error))
            }
        }
        
        responseJSON(queue: queue, options: options, completionHandler: completionHandler)
        
        return promise.future
    }
}
