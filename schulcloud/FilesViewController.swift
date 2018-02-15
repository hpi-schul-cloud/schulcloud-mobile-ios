//
//  FilesViewController.swift
//  
//
//  Created by Carl Gödecken on 19.05.17.
//
//

import UIKit
import CoreData
import BrightFutures

class FilesViewController: UITableViewController, NSFetchedResultsControllerDelegate {

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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didTriggerRefresh() {
        
        let successBlock : () -> () = {
            DispatchQueue.main.async {
                self.performFetch()
            }
        }
        let completeBlock : () -> () = {
            DispatchQueue.main.async {
                self.refreshControl?.endRefreshing()
            }
        }
        
        if [FileHelper.rootDirectoryID, FileHelper.coursesDirectoryID].contains(currentFolder.id) {
            FileHelper.updateDatabase(forFolder: currentFolder)
            .onSuccess { _ in
                self.performFetch()
            }.onFailure { error in
                log.error(error)
            }.onComplete { _ in
                self.refreshControl?.endRefreshing()
            }
        } else if FileHelper.sharedDirectoryID == currentFolder.id {
            fileSync.sharedDownload()
            .map { (objects) -> Void in
                for json in objects {
                    FileHelper.updateDatabase(contentsOf: self.currentFolder, using: json)
                }
                return ()
            }
            .onSuccess(callback: successBlock)
            .onFailure(callback: { (error) in
                print("failure: \(error)")
            }).onComplete(callback: { (_) in
                completeBlock()
            })
        } else {
            fileSync.downloadContent(for: currentFolder)
            .map { json -> () in
                FileHelper.updateDatabase(contentsOf: self.currentFolder, using: json)
                return ()
            }.onSuccess(callback: successBlock)
            .onFailure { (error) in
                log.error(error)
            }.onComplete { (_) in
                completeBlock()
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
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
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
        guard let file = self.fetchedResultsController.sections?[indexPath.section].objects?[indexPath.row] as? File else { return false }
        return file.permissions.contains(.write)
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            guard let file = self.fetchedResultsController.sections?[indexPath.section].objects?[indexPath.row] as? File else { return }
            FileHelper.delete(file: file)
            .onSuccess { _ in
                managedObjectContext.delete(file)
                try! managedObjectContext.save()
                DispatchQueue.main.async {
                    try! self.fetchedResultsController.performFetch()
                    tableView.deleteRows(at: [indexPath], with: .automatic)
                }
            }
            .onFailure { error in
                managedObjectContext.rollback()
                DispatchQueue.main.async {
                    let alertVC = UIAlertController(title: "Something unexpected happened", message: error.localizedDescription, preferredStyle: .alert)
                    let dismissAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    alertVC.addAction(dismissAction)
                    self.present(alertVC, animated: true) {}
                }
            }
        }
        
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = fetchedResultsController.object(at: indexPath)

        let reuseIdentifier = item.detail == nil ? "item" : "item detail"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) //as! FileListCell

        cell.textLabel?.text = item.name
        cell.detailTextLabel?.text = item.detail
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
