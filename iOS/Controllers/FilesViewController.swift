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

    lazy var currentFolder: File = FileHelper.rootFolder
    var fileSync = FileSync.default
    weak var delegate: FilePickerDelegate?

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

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.coreDataTableViewDataSource = CoreDataTableViewDataSource(self.tableView,
                                                                       fetchedResultsController: self.fetchedResultsController,
                                                                       cellReuseIdentifier: R.reuseIdentifier.itemDetail.identifier ,
                                                                       delegate: self)

        self.navigationItem.title = self.currentFolder.name

        performFetch()
        didTriggerRefresh()
    }

    @IBAction private func didTriggerRefresh() {
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

    @objc public func dismissController() {
        self.dismiss(animated: true)
    }
}

// MARK: TableView Delegate/DataSource
extension FilesViewController {
    override public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard let currentUser = Globals.currentUser else { return false }
        let file = self.fetchedResultsController.object(at: indexPath)
        guard file.id != FileHelper.rootDirectoryID,
            file.parentDirectory?.id != FileHelper.rootDirectoryID,
            file.parentDirectory?.id != FileHelper.coursesDirectoryID else { return false }

        return currentUser.permissions.contains(.movingFiles) || currentUser.permissions.contains(.deletingFiles) // && file.permissions.contains(.write)
    }

    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }

        let item = fetchedResultsController.object(at: indexPath)

        if item.isDirectory {
            guard let folderVC = R.storyboard.tabFiles.folderVC() else {
                return
            }

            folderVC.currentFolder = item
            folderVC.navigationItem.rightBarButtonItem = self.navigationItem.rightBarButtonItem
            folderVC.delegate = self.delegate

            self.navigationController?.pushViewController(folderVC, animated: true)
        } else {
            guard let previewController = R.storyboard.tabFiles.filePreviewVC() else { return }
            previewController.item = item
            previewController.pickerDelegate = self.delegate
            previewController.navigationItem.rightBarButtonItem = self.navigationItem.rightBarButtonItem
            self.navigationController?.pushViewController(previewController, animated: true)
        }
    }
}

extension FilesViewController: CoreDataTableViewDataSourceDelegate {
    func configure(_ cell: UITableViewCell, for object: File) {
        cell.textLabel?.text = object.name
        cell.detailTextLabel?.text = object.detail
        cell.accessoryType = object.isDirectory ? .disclosureIndicator : .none
        cell.imageView?.image = UIImage(resource: object.isDirectory ? R.image.folder : R.image.document)
        cell.imageView?.tintColor = object.isDirectory ? Brand.default.colors.secondary : Brand.default.colors.primary
        cell.imageView?.contentMode = .scaleAspectFit
        if #available(iOS 11.0, *) {
            cell.imageView?.adjustsImageSizeForAccessibilityContentSizeCategory = true
        }
    }
}
