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

        self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        if currentFolder == nil {
            currentFolder = FileHelper.rootFolder
        }
        
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
        
        guard let sec = fetchedResultsController.sections?[section],
            let count = sec.objects?.count else {
            log.error("Error loading object count in section \(section)")
            return 0
        }
        return count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let object = fetchedResultsController.object(at: indexPath)
        
        let reuseIdentifier = object.isDirectory ? "folder" : "file"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! FileListCell
        
        cell.titleLabel.text = object.displayName
        if let size = object.size {
            cell.subtitleLabel.text = ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .binary)
        } else {
            cell.subtitleLabel.text = nil
        }

        return cell
    }
 

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let selectedCell = sender as! UITableViewCell
        guard let indexPath = tableView.indexPath(for: selectedCell) else { return }
        let selectedItem = fetchedResultsController.object(at: indexPath)
        
        switch(segue.identifier) {
        case .some("filePreview"):
            let destination = segue.destination as! LoadingViewController
            destination.file = selectedItem
            break
        case .some("subfolder"):
            let destination = segue.destination as! FilesViewController
            destination.currentFolder = selectedItem
        default:
            break
        }
    }
    

}
