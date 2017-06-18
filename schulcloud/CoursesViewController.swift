//
//  CoursesViewController.swift
//  schulcloud
//
//  Created by Carl Julius Gödecken on 31.05.17.
//  Copyright © 2017 Hasso-Plattner-Institut. All rights reserved.
//

import UIKit
import CoreData

class CoursesViewController: UICollectionViewController, NSFetchedResultsControllerDelegate, UICollectionViewDelegateFlowLayout {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        performFetch()
        updateData()
    }

    @IBAction func didTriggerRefresh() {
        updateData()
    }
    
    func updateData() {
        CourseHelper.fetchFromServer()
            .onSuccess { _ in
                self.performFetch()
            }
            .onFailure { error in
                log.error(error)
            }
    }
    
    // MARK: - Table view data source
    
    fileprivate lazy var fetchedResultsController: NSFetchedResultsController<Course> = {
        // Create Fetch Request
        let fetchRequest: NSFetchRequest<Course> = Course.fetchRequest()
        
        // Configure Fetch Request
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
        collectionView?.reloadData()
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        guard let sec = fetchedResultsController.sections?[section],
            let count = sec.objects?.count else {
                log.error("Error loading object count in section \(section)")
                return 0
        }
        return count
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                            cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let reuseIdentifier = "courseCell"
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! CourseCell
        
        let course = fetchedResultsController.object(at: indexPath)
        cell.configure(for: course)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let cellsAcross: CGFloat = 2
        let spaceBetweenCells: CGFloat = 1
        let width = (collectionView.bounds.width - (cellsAcross - 1) * spaceBetweenCells) / cellsAcross
        
        return CGSize(width: width, height: width * 1.3)
    }
    
    
    /*
     // Override to support conditional editing of the table view.
     override func collectionView(_ collectionView: UIcollectionView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func collectionView(_ collectionView: UIcollectionView, commit editingStyle: UIcollectionViewCellEditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     collectionView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch(segue.identifier) {
        case .some("courseDetail"):
            let selectedCell = sender as! UICollectionViewCell
            guard let indexPath = self.collectionView!.indexPath(for: selectedCell) else { return }
            let selectedCourse = fetchedResultsController.object(at: indexPath)
            let destination = segue.destination as! LessonsViewController
            destination.course = selectedCourse
        default:
            break
        }
    }

}