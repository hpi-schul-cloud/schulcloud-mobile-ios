//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Foundation
import BrightFutures
import Result

public struct ContentResourceHelper {
    // Lazy variable für den URLRequest
    // session auch hier rein...
    
    // getData -> fetchdata
    public static func getData(using request_blueprint: URLRequest, with session: URLSession = URLSession.shared) -> Future<[ContentResource], NoError> {
        // SCError -> Gibt Klasse im Projekt cmd+shift+o suchen
        let promise = Promise<[ContentResource], NoError>()
        
        session.dataTask(with: request_blueprint, completionHandler: {
            (data: Data?, response: URLResponse?, error: Error?) in
            // anderen error case abh von error=nil, data != nil usw.
            // Guard let für error
            if let data = data {
                let decoder = JSONDecoder()
                let resources = try! decoder.decode(ContentResources.self, from: data).data
                promise.success(resources)
            }
        }).resume()
        return promise.future
    }
}
