//
//  Created for schulcloud-mobile-ios under GPL-3.0 license.
//  Copyright © HPI. All rights reserved.
//

/// TODO: Permissions handling
///    filestorageView -> Allows displaying of files
///    filestorageEdit -> Editing filestorage information
///    filestorageCreate -> Can create or edit internal files or folder
///    filestorageRemove -> Can remove file or folder
///    fileCreate -> Create a file (requires filestorageCreate). Currently not implemented on backend, only requires filestorageCreate.
///    fileDelete -> Delete a file (requires filestorageRemove). Currently not implemented on backend, only requires filestorageRemove.
///    fileMove   -> Move a file in the structure (requires filestorageCreate). Currently not implemented on backend, only requires filestorageCreate.
///    folderCreate -> Create a folder (requires filestorageCreate). Currently not implemented on backend, only requires filestorageCreate.
///    folderDelete -> Delete a folder (requires filestorageRemove). Currently not implemented on backend, only requires filestorageRemove.

import BrightFutures
import Common
import CoreData
import UIKit

public class FilesViewController: UITableViewController {

    var currentFolder: File = FileHelper.rootFolder
    var fileSync = FileSync.default

    private var coreDataTableViewDataSource: CoreDataTableViewDataSource<FilesViewController>?

    private lazy var fetchedResultsController: NSFetchedResultsController<File> = {
        let fetchRequest: NSFetchRequest<File> = File.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        let parentFolderPredicate = NSPredicate(format: "parentDirectory == %@", self.currentFolder)
        fetchRequest.predicate = parentFolderPredicate
        return NSFetchedResultsController(fetchRequest: fetchRequest,
                                          managedObjectContext: CoreDataHelper.viewContext,
                                          sectionNameKeyPath: nil,
                                          cacheName: nil)
    }()

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.coreDataTableViewDataSource = CoreDataTableViewDataSource(self.tableView,
                                                                       fetchedResultsController: self.fetchedResultsController,
                                                                       cellReuseIdentifier: "item detail",
                                                                       delegate: self)

        self.navigationItem.title = self.currentFolder.name

        performFetch()
        didTriggerRefresh()
    }

    @IBAction func didTriggerRefresh() {
        self.fileSync.updateContent(of: self.currentFolder) { result in
            defer {
                DispatchQueue.main.async {
                    self.refreshControl?.endRefreshing()
                }
            }

            guard result.value != nil else {
                log.error("Refreshing files failed", error: result.error)
                return
            }
        }?.resume()
    }

    func performFetch() {
        do {
            try self.fetchedResultsController.performFetch()
        } catch {
            log.error("Unable to perform File FetchRequest", error: error)
        }
    }
}

// MARK: TableView Delegate/DataSource

extension FilesViewController {

    public override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard let currentUser = Globals.currentUser else { return false }
        let file = self.fetchedResultsController.object(at: indexPath)
        guard file.id != FileHelper.rootDirectoryID,
            file.parentDirectory?.id != FileHelper.rootDirectoryID,
            file.parentDirectory?.id != FileHelper.coursesDirectoryID else { return false }

        return currentUser.permissions.contains(.movingFiles) || currentUser.permissions.contains(.deletingFiles) // && file.permissions.contains(.write)
    }

    public override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        guard let currentUser = Globals.currentUser else { return nil }
        var actions: [UITableViewRowAction] = []

        // TODO: Implement!
        if false && currentUser.permissions.contains(.deletingFiles) {
            actions.append(UITableViewRowAction(style: .destructive, title: "Delete") { _, _ in
                // TODO: Implement!
                /*
                guard let file = self.fetchedResultsController.sections?[indexPath.section].objects?[indexPath.row] as? File else { return }

                FileHelper.delete(file: file).onSuccess { _ in
                    CoreDataHelper.persistentContainer.performBackgroundTask { context in
                        context.delete(file)
                        try! context.save()
                        DispatchQueue.main.async {
                            try! self.fetchedResultsController.performFetch()
                            tableView.deleteRows(at: [indexPath], with: .automatic)
                        }
                    }
                }.onFailure { error in
                    DispatchQueue.main.async {
                        let alertVC = UIAlertController(title: "Something unexpected happened", message: error.localizedDescription, preferredStyle: .alert)
                        let dismissAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                        alertVC.addAction(dismissAction)
                        self.present(alertVC, animated: true) {}
                    }
                }*/
            })
        }

        // TODO: Implement!
        if false && currentUser.permissions.contains(.movingFiles) {
            actions.append(UITableViewRowAction(style: .normal, title: "Move") { _, _ in
            })
        }

        return actions
    }

    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }

        let item = fetchedResultsController.object(at: indexPath)
        let storyboard = UIStoryboard(name: "TabFiles", bundle: nil)

        if item.isDirectory {
            guard let folderVC = storyboard.instantiateViewController(withIdentifier: "FolderVC") as? FilesViewController else {
                return
            }

            folderVC.currentFolder = item
            self.navigationController?.pushViewController(folderVC, animated: true)
        } else {
            guard let fileVC = storyboard.instantiateViewController(withIdentifier: "FileVC") as? LoadingViewController else {
                return
            }

            fileVC.file = item
            self.navigationController?.pushViewController(fileVC, animated: true)
        }
    }
}

extension FilesViewController: CoreDataTableViewDataSourceDelegate {
    func configure(_ cell: UITableViewCell, for object: File) {
        cell.textLabel?.text = object.name
        cell.detailTextLabel?.text = object.detail
        cell.accessoryType = object.isDirectory ? .disclosureIndicator : .none
        cell.imageView?.image = object.isDirectory ? UIImage(named: "folder") : UIImage(named: "document")
        cell.imageView?.tintColor = object.isDirectory ? Brand.default.colors.secondary : Brand.default.colors.primary
        cell.imageView?.contentMode = .scaleAspectFit
        if #available(iOS 11.0, *) {
            cell.imageView?.adjustsImageSizeForAccessibilityContentSizeCategory = true
        }
    }
}
