//
//  DashboardNewsCell.swift
//  schulcloud
//
//  Created by Florian Morel on 19.03.18.
//  Copyright © 2018 Hasso-Plattner-Institut. All rights reserved.
//

import UIKit

final class DashboardNewsCell : UICollectionViewCell {

    @IBOutlet var title: UILabel!
    @IBOutlet var date: UILabel!
    @IBOutlet var content: UITextView!

    static var dateFormatter : DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale.current
        return formatter
    }()

    static func height(for news: NewsArticle, boundingWidth: CGFloat) -> CGFloat {
        let boundingRect = CGSize(width: boundingWidth, height: CGFloat.infinity)

        let titleAttributes : [NSAttributedStringKey : Any] = [NSAttributedStringKey.font : UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline) ]
        let attributedTitle = NSAttributedString(string: news.title, attributes: titleAttributes)

        let dateAttributes : [NSAttributedStringKey : Any] = [NSAttributedStringKey.font : UIFont.preferredFont(forTextStyle: UIFontTextStyle.subheadline) ]
        let attributedDate = NSAttributedString(string: dateFormatter.string(from:news.displayAt), attributes: dateAttributes)

        let attributedContent = news.content.convertedHTML!

        let titleRenderSize = attributedTitle.boundingRect(with: boundingRect, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        let dateRenderSize = attributedDate.boundingRect(with: boundingRect, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        let contentRenderSize = attributedContent.boundingRect(with: boundingRect, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        return 40 + titleRenderSize.height + dateRenderSize.height + contentRenderSize.height
    }
}
