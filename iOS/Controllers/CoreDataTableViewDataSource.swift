//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

import Common
import CoreData
import UIKit

protocol CoreDataTableViewDataSourceDelegate: AnyObject {

    associatedtype Object: NSFetchRequestResult
    associatedtype Cell: UITableViewCell

    func configure(_ cell: Cell, for object: Object)
    func titleForDefaultHeader(forSection section: Int) -> String?

}

extension CoreDataTableViewDataSourceDelegate {

    func titleForDefaultHeader(forSection section: Int) -> String? {
        return nil
    }

}

class CoreDataTableViewDataSource<Delegate: CoreDataTableViewDataSourceDelegate> : NSObject, UITableViewDataSource, NSFetchedResultsControllerDelegate {

    typealias Object = Delegate.Object
    typealias Cell = Delegate.Cell

    private weak var tableView: UITableView?
    private let fetchedResultsController: NSFetchedResultsController<Object>
    private let cellReuseIdentifier: String
    private weak var delegte: Delegate?

    required init(_ tableView: UITableView,
                  fetchedResultsController: NSFetchedResultsController<Object>,
                  cellReuseIdentifier: String,
                  delegate: Delegate) {
        self.tableView = tableView
        self.fetchedResultsController = fetchedResultsController
        self.cellReuseIdentifier = cellReuseIdentifier
        self.delegte = delegate
        super.init()

        do {
            self.fetchedResultsController.delegate = self
            try self.fetchedResultsController.performFetch()
        } catch {
            log.error("Failed fetch resource of type: %@", String(describing: Delegate.Object.self), error: error)
        }

        self.tableView?.dataSource = self
        self.tableView?.reloadData()
    }

    func object(at indexPath: IndexPath) -> Object {
        return self.fetchedResultsController.object(at: indexPath)
    }

    // MARK: NSFetchedResultsControllerDelegate
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView?.beginUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange sectionInfo: NSFetchedResultsSectionInfo,
                    atSectionIndex sectionIndex: Int,
                    for type: NSFetchedResultsChangeType) {
        let sectionIndex = IndexSet(integer: sectionIndex)
        switch type {
        case .insert:
            self.tableView?.insertSections(sectionIndex, with: .fade)
        case .delete:
            self.tableView?.deleteSections(sectionIndex, with: .fade)
        case .move:
            break
        case .update:
            break
        @unknown default:
            fatalError()
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            let newIndexPath = newIndexPath.require(hint: "newIndexPath is required for table view cell insert")
            self.tableView?.insertRows(at: [newIndexPath], with: .fade)
        case .delete:
            let indexPath = indexPath.require(hint: "indexPath is required for table view cell delete")
            self.tableView?.deleteRows(at: [indexPath], with: .fade)
        case .update:
            let indexPath = indexPath.require(hint: "indexPath is required for table view cell update")
            self.tableView?.reloadRows(at: [indexPath], with: .fade)
        case .move:
            let indexPath = indexPath.require(hint: "indexPath is required for table view cell move")
            let newIndexPath = newIndexPath.require(hint: "newIndexPath is required for table view cell move")
            self.tableView?.deleteRows(at: [indexPath], with: .fade)
            self.tableView?.insertRows(at: [newIndexPath], with: .fade)
        @unknown default:
            fatalError()
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView?.endUpdates()
    }

    // MARK: UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let someCell = tableView.dequeueReusableCell(withIdentifier: self.cellReuseIdentifier, for: indexPath) as? Cell
        let cell = someCell.require(hint: "Unexpected cell type at \(indexPath), expected cell of type \(Cell.self)")
        let object = self.fetchedResultsController.object(at: indexPath)
        self.delegte?.configure(cell, for: object)
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.delegte?.titleForDefaultHeader(forSection: section)
    }

}
