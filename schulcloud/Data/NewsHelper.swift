//
//  NewsHelper.swift
//  schulcloud
//
//  Created by Florian Morel on 04.01.18.
//  Copyright © 2018 Hasso-Plattner-Institut. All rights reserved.
//

import BrightFutures
import CoreData

struct NewsArticleHelper {

    static func syncNewsArticles() -> Future<SyncEngine.SyncMultipleResult, SCError> {
        let fetchRequest = NewsArticle.fetchRequest() as NSFetchRequest<NewsArticle>
        let query = MultipleResourcesQuery(type: NewsArticle.self)
        return SyncHelper.syncResources(withFetchRequest: fetchRequest, withQuery: query)
    }

}
