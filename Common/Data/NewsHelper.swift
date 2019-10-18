//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import BrightFutures
import CoreData
import SyncEngine

public enum NewsArticleHelper {

    @discardableResult public static func syncNewsArticles() -> Future<SyncEngine.SyncMultipleResult, SCError> {
        let fetchRequest = NewsArticle.fetchRequest() as NSFetchRequest<NewsArticle>
        let query = MultipleResourcesQuery(type: NewsArticle.self)
        return SyncHelper.syncResources(withFetchRequest: fetchRequest, withQuery: query)
    }

}
