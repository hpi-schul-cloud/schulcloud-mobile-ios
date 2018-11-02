//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import CoreData
import Foundation
import UIKit

final class TableViewFetchedControllerDelegate: NSObject, NSFetchedResultsControllerDelegate {

    weak var tableView: UITableView?

    init(tableView: UITableView?) {
        super.init()
        self.tableView = tableView
    }

    public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView?.beginUpdates()
    }

    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView?.endUpdates()
    }

    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                           didChange anObject: Any,
                           at indexPath: IndexPath?,
                           for type: NSFetchedResultsChangeType,
                           newIndexPath: IndexPath?) {
        guard let indexPath = indexPath else { return }
        switch type {
        case .delete:
            self.tableView?.deleteRows(at: [indexPath], with: .automatic)
        case .insert:
            self.tableView?.insertRows(at: [indexPath], with: .automatic)
        case .update:
            self.tableView?.reloadRows(at: [indexPath], with: .automatic)
        case .move:
            guard let newIndexPath = newIndexPath else { return }
            self.tableView?.moveRow(at: indexPath, to: newIndexPath)
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .delete:
            self.tableView?.deleteSections(IndexSet(integer: sectionIndex), with: .automatic)
        case .insert:
            self.tableView?.insertSections(IndexSet(integer: sectionIndex), with: .automatic)
        case .move:
            break
        case .update:
            break
        }
    }
}
