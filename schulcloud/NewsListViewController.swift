//
//  NewsListViewController.swift
//  schulcloud
//
//  Created by Florian Morel on 04.01.18.
//  Copyright © 2018 Hasso-Plattner-Institut. All rights reserved.
//

import UIKit
import CoreData

class NewsListViewController: UITableViewController, UIWebViewDelegate, NSFetchedResultsControllerDelegate {
    
    var news: [NewsCell.News] = []
    
    // Temporary
    var contentHeight: [CGFloat] = [0.0, 0.0, 0.0]
    
    
    override func awakeFromNib() {
        func dateFromString(str: String) -> Date {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXX"
            return formatter.date(from: str)!
        }
        let news1 = NewsCell.News(title: "Willkommen im Schuljahr 2017/18!",
                                  content: "<p>Die Schulleitung hei&szlig;t alle (neuen) Sch&uuml;ler im neuen Schuljahr herzlich willkommen!</p>\r\n\r\n<p>Wir freuen uns auf ein neues spannendes Schuljahr mit vielen interessanten Highlights: Unter anderem ist ein Besuch der 12. Klassen bei der UNESCO sowie ein Sch&uuml;leraustausch mit einer Schule im Silicon Valley der Klassenstufe 10 geplant.</p>\r\n\r\n<p>&nbsp;</p>\r\n\r\n<p>Einen guten Start und viel Erfolg w&uuml;nscht Euch die Schulleitung sowie das Lehrerkolleg!</p>\r\n",
                                  createdAt: dateFromString(str: "2017-10-12T06:44:24.134Z") )
        
        let news2 = NewsCell.News(title: "Willkommen in der Schul-Cloud!",
                                  content: "<p>Liebe Sch&uuml;lerinnen und Sch&uuml;ler,</p>\r\n\r\n<p>um auch im n&auml;chsten Jahrzehnt des 21. Jahrhunderts bildungsm&auml;&szlig;ig spitze aufgestellt zu sein, nutzen wir ab sofort die Schul-Cloud. Mit Hilfe der Schul-Cloud k&ouml;nnen wir uns unter anderem mit den bereits bestehenden Moodle-Accounts anmelden, viele Tools nutzen und auf Bildungsinhalte zugreifen. Weiterhin k&ouml;nnen wir auch die Stundenpl&auml;ne online aktualisieren und Aufgaben erstellen.</p>\r\n",
                                  createdAt: dateFromString(str: "2017-10-12T06:38:59.755Z") )
        
        let news3 = NewsCell.News(title: "Gesunde Schule 2017",
                                  content: "<p>Liebe Sch&uuml;lerinnen und Sch&uuml;ler,</p>\r\n\r\n<p>schon seit einigen Jahren sind wir eine &quot;Gesunde Schule&quot;. Um dieses Motto nun noch verst&auml;rkter umzusetzen, haben wir seit dem Beginn des neuen Schuljahres einen neuen Mensa-Anbieter! So wird eure Mittagspause mit regionalen und gesunden Produkten noch besser!</p>\r\n\r\n<p>Einen guten Appetit w&uuml;nscht euch die Schulleitung und das Lehrerkolleg!</p>\r\n",
                                  createdAt: dateFromString(str:"2017-10-12T06:58:13.541Z"))
        
        news.append(contentsOf: [news1, news2, news3])
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return news.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let index = indexPath.row
        let item = news[index]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "newsCell", for: indexPath) as! NewsCell
        
        cell.title.text = item.title
        
        cell.content.tag = index
        cell.content.delegate = self
        
        cell.content.loadHTMLString(item.content.standardHtml, baseURL: nil)
        cell.heightConstraint.constant = contentHeight[index]

        cell.timeSinceCreated.text = item.timeSinceCreated
        
        return cell
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        
        let index = webView.tag
        let height = webView.scrollView.contentSize.height
        if contentHeight[index] == height {
            return
        }
        
        contentHeight[index] = height
        tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: UITableViewRowAnimation.automatic)
    }
}

extension String {
    func htmlWrapped(style: String?) -> String {
        return "<html><head>\(style ?? "")</head><body> \(self)</body></html>"
    }
    
    var standardHtml : String {
        return htmlWrapped(style: Constants.textStyleHtml)
    }
    
    var localized : String {
        return NSLocalizedString(self, comment: "")
    }
}

