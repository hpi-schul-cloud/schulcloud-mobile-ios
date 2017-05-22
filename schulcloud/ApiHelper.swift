//
//  ApiHelper.swift
//  schulcloud
//
//  Created by Carl Gödecken on 12.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import Foundation
import Alamofire
import AlamofireObjectMapper
import BrightFutures
import ObjectMapper

class ApiHelper {
    
    internal static func mappedObjectAFRequest<T: Mappable>(
        _ url: URLConvertible,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = URLEncoding.default,
        headers: HTTPHeaders? = nil) -> Future<T, SCError> {
        let promise = Promise<T, SCError>()
        Alamofire.request(url, method: method, parameters: parameters, encoding: encoding, headers: headers).responseObject { (response: DataResponse<T>) in
            
            if let value = response.result.value {
                promise.success(value)
            } else {
                promise.failure(SCError.network(response.error!))
            }
        }
        
        return promise.future
    }
    
    static func request<T: Mappable>(
        _ endpoint: String,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = URLEncoding.default,
        additionalHeaders: HTTPHeaders? = nil,
        authenticated: Bool = true) -> Future<T, SCError> {
        
        let urlString = Constants.backend.url.absoluteString.appending(endpoint)
        var headers = authenticated ? ["Authorization": Globals.account!.accessToken!] : HTTPHeaders()
        
        if let additionalHeaders = additionalHeaders {
            for (key, value) in additionalHeaders {
                headers.updateValue(value, forKey: key)
            }
        }
        return mappedObjectAFRequest(urlString, method: method, parameters: parameters, encoding: encoding, headers: headers)
    }
    
    static func requestBasic(
        _ endpoint: String,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = URLEncoding.default,
        additionalHeaders: HTTPHeaders? = nil,
        authenticated: Bool = true) -> Future<DefaultDataResponse, SCError> {
        
        let urlString = Constants.backend.url.absoluteString.appending(endpoint)
        var headers = authenticated ? ["Authorization": Globals.account!.accessToken!] : HTTPHeaders()
        
        if let additionalHeaders = additionalHeaders {
            for (key, value) in additionalHeaders {
                headers.updateValue(value, forKey: key)
            }
        }
        
        let promise = Promise<DefaultDataResponse, SCError>()
        Alamofire.request(urlString, method: method, parameters: parameters, encoding: encoding, headers: headers).response { (response: DefaultDataResponse) in
            promise.success(response)
        }
        
        return promise.future
    }
}
