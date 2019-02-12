//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Foundation
import BrightFutures
import Result

public struct ContentResourceHelper {
    public static func getData(using request_blueprint: URLRequest, with session: URLSession) -> Future<[ContentResource], NoError> {
        return Future { complete in
            DispatchQueue.global(qos: .userInitiated).async {
                session.dataTask(with: request_blueprint, completionHandler: {
                    (data: Data?, response: URLResponse?, error: Error?) in
                    
                    if let data = data {
                        let decoder = JSONDecoder()
                        let resources = try! decoder.decode(ContentResources.self, from: data).data
                        complete(.success(resources))
                    }
                }).resume()
            }
        }
    }
}
