//
//  FilesViewController.swift
//  
//
//  Created by Carl Gödecken on 19.05.17.
//
//

import UIKit
import CoreData

class FilesViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    var currentFolder: File!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if currentFolder == nil {
            currentFolder = FileHelper.rootFolder
        }

        self.navigationItem.title = self.currentFolder.displayName

        performFetch()
        didTriggerRefresh()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didTriggerRefresh() {
        FileHelper.updateDatabase(forFolder: currentFolder)
            .onSuccess { _ in
                self.performFetch()
            }
            .onFailure { error in
                log.error(error)
            }
            .onComplete { _ in
                self.refreshControl?.endRefreshing()
            }
    }

    // MARK: - Table view data source
    
    fileprivate lazy var fetchedResultsController: NSFetchedResultsController<File> = {
        // Create Fetch Request
        let fetchRequest: NSFetchRequest<File> = File.fetchRequest()
        
        // Configure Fetch Request
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "displayName", ascending: true)]
        let parentFolderPredicate = NSPredicate(format: "parentDirectory == %@", self.currentFolder)
        fetchRequest.predicate = parentFolderPredicate
        
        // Create Fetched Results Controller
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: CoreDataHelper.persistentContainer.viewContext,
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

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = fetchedResultsController.object(at: indexPath)

        let reuseIdentifier = item.detail == nil ? "item" : "item detail"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) //as! FileListCell

        cell.textLabel?.text = item.displayName
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
