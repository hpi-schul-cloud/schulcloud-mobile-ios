//
//  LessonsViewController.swift
//  schulcloud
//
//  Created by Carl Julius Gödecken on 31.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import UIKit
import CoreData

class LessonsViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    var course: Course!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        self.title = course.name
        performFetch()
        updateData()
    }
    
    @IBAction func didTriggerRefresh() {
        updateData()
    }
    
    func updateData() {
        LessonHelper.fetchFromServer(belongingTo: course)
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
    
    fileprivate lazy var fetchedResultsController: NSFetchedResultsController<Lesson> = {
        // Create Fetch Request
        let fetchRequest: NSFetchRequest<Lesson> = Lesson.fetchRequest()
        
        // Configure Fetch Request
        fetchRequest.predicate = NSPredicate(format: "course == %@", self.course)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
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
    
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = "lessonCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        
        let lesson = fetchedResultsController.object(at: indexPath)
        cell.textLabel?.text = lesson.name
        cell.detailTextLabel?.text = lesson.descriptionString
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
        
        switch(segue.identifier) {
        case .some("singleLesson"):
            let selectedCell = sender as! UITableViewCell
            guard let indexPath = tableView.indexPath(for: selectedCell) else { return }
            let selectedLesson = fetchedResultsController.object(at: indexPath)
            let destination = (segue.destination as! UINavigationController).viewControllers.first! as! SingleLessonViewController
            destination.lesson = selectedLesson
        default:
            break
        }
    }
    
}
