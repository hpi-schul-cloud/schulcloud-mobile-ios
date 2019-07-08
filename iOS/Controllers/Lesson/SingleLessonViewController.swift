//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Common
import UIKit

/// TODO(permissions):
///     contentView? Should we not display the content of lesson if no permission? Seems off
class SingleLessonViewController: UITableViewController {

    var lesson: Lesson! {
        didSet {
            self.contents = self.lesson!.contents.sorted { $0.insertDate < $1.insertDate }
            self.buildContentCache()
        }
    }

    private func buildContentCache() {
        for content in self.contents {
            guard content.type == .text else { continue }
            self.renderedHTMLCache[content.id] = self.htmlHelper.attributedString(for: content.text!).value
        }
    }

    let htmlHelper = HTMLHelper.default
    private var renderedHTMLCache: [String: NSAttributedString] = [:]
    private var contents: [LessonContent] = []

    private var observer: NSObjectProtocol?

    let textCellVerticalMargin: CGFloat = 25
    let textCellLabelHeight: CGFloat = 20

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = lesson.name
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.observer = NotificationCenter.default.addObserver(forName: UIContentSizeCategory.didChangeNotification,
                                                               object: nil,
                                                               queue: .main) { [unowned self] _ in
            self.buildContentCache()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self.observer)
        super.viewDidDisappear(animated)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.contents.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let content = self.contents[indexPath.row]

        switch content.type {
        case .other:
            let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.unknownCell, for: indexPath)!
            let font = UIFont.italicSystemFont(ofSize: 15.0)
            cell.textLabel?.text = content.title
            cell.detailTextLabel?.attributedText = NSAttributedString(string: "This content type isn't supported yet",
                                                                      attributes: [NSAttributedString.Key.font: font])
            return cell
        case .text:

            if let renderedHTML = self.renderedHTMLCache[content.id] {
                let textCell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.textCell, for: indexPath)!
                textCell.configure(title: content.title ?? "", text: renderedHTML)
                return textCell
            } else {
                let errorCell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.errorCell, for: indexPath)!
                let font = UIFont.italicSystemFont(ofSize: 15.0)
                errorCell.textLabel?.attributedText = NSAttributedString(string: "An error was found processing the content",
                                                                         attributes: [NSAttributedString.Key.font: font])
                return errorCell
            }
        }
    }
}
