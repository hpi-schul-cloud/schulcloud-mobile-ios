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
import CoreData
import UIKit

class FilesViewController: UITableViewController {

    var currentFolder: File!
    var fileSync = FileSync()

    override func viewDidLoad() {
        super.viewDidLoad()

        if currentFolder == nil {
            currentFolder = FileHelper.rootFolder
        }

        self.navigationItem.title = self.currentFolder.name

        performFetch()
        didTriggerRefresh()
    }

    @IBAction func didTriggerRefresh() {
        let future: Future<Void, SCError>
        if FileHelper.coursesDirectoryID == currentFolder.id {
            future = CourseHelper.syncCourses().asVoid()
        } else if FileHelper.sharedDirectoryID == currentFolder.id {
            future = fileSync.downloadSharedFiles()
            .flatMap { objects -> Future<Void, SCError> in
                var updates: [Future<Void,SCError>] = []
                for json in objects {
                    updates.append(FileHelper.updateDatabase(contentsOf: self.currentFolder, using: json))
                }

                return updates.sequence().asVoid()
            }.asVoid()
        } else {
            future = fileSync.downloadContent(for: currentFolder)
            .flatMap { json -> Future<Void, SCError> in
                return FileHelper.updateDatabase(contentsOf: self.currentFolder, using: json)
            }.asVoid()
        }

        future.onFailure { error in
            print("Failure: \(error)")
        }.onComplete{ _ in
            DispatchQueue.main.async {
                self.refreshControl?.endRefreshing()
            }
        }
    }

    // MARK: - Table view data source

    fileprivate lazy var fetchedResultsController: NSFetchedResultsController<File> = {
        // Create Fetch Request
        let fetchRequest: NSFetchRequest<File> = File.fetchRequest()

        // Configure Fetch Request
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        let parentFolderPredicate = NSPredicate(format: "parentDirectory == %@", self.currentFolder)
        fetchRequest.predicate = parentFolderPredicate

        // Create Fetched Results Controller
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: CoreDataHelper.viewContext,
                                                                  sectionNameKeyPath: nil,
                                                                  cacheName: nil)
        // Configure Fetched Results Controller
        fetchedResultsController.delegate = self

        return fetchedResultsController
    }()

    func performFetch() {
        do {
            try self.fetchedResultsController.performFetch()
        } catch let fetchError as NSError {
            log.error("Unable to Perform Fetch Request: \(fetchError), \(fetchError.localizedDescription)")
        }

        tableView.reloadData()
    }

}

extension FilesViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.reloadData()
    }
}

// MARK: TableView Delegate/DataSource

extension FilesViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let count = fetchedResultsController.sections?[section].objects?.count else {
            log.error("Error loading object count in section \(section)")
            return 0
        }

        return count
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard let currentUser = Globals.currentUser else { return false }
        let file = self.fetchedResultsController.object(at: indexPath)
        guard file.id != FileHelper.rootDirectoryID, file.parentDirectory?.id != FileHelper.rootDirectoryID, file.parentDirectory?.id != FileHelper.coursesDirectoryID
            else { return false }

        return currentUser.permissions.contains(.movingFiles) || currentUser.permissions.contains(.deletingFiles) // && file.permissions.contains(.write)
    }

    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        guard let currentUser = Globals.currentUser else { return nil }
        var actions: [UITableViewRowAction] = []

        // TODO: Implement!
        if false && currentUser.permissions.contains(.deletingFiles) {
            actions.append(UITableViewRowAction(style: .destructive, title: "Delete") { rowAction, indexPath in
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
            actions.append(UITableViewRowAction(style: .normal, title: "Move") { rowAction, indexPath in
            })
        }

        return actions
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = fetchedResultsController.object(at: indexPath)

        let reuseIdentifier = item.detail == nil ? "item" : "item detail"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)

        cell.textLabel?.text = item.name
        cell.detailTextLabel?.text = item.detail
        cell.accessoryType = item.isDirectory ? .disclosureIndicator : .none
        cell.imageView?.image = item.isDirectory ? #imageLiteral(resourceName: "folder") : #imageLiteral(resourceName: "document")
        cell.imageView?.tintColor = item.isDirectory ? UIColor.schulcloudYellow : UIColor.schulcloudRed
        cell.imageView?.contentMode = .scaleAspectFit
        cell.imageView?.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        if #available(iOS 11.0, *){
            cell.imageView?.adjustsImageSizeForAccessibilityContentSizeCategory = true
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
