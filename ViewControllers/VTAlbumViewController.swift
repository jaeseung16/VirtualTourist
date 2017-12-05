//
//  VTAlbumViewController.swift
//  VirtualTourist
//
//  Created by Jae-Seung Lee on 11/19/17.
//  Copyright © 2017 Jae-Seung Lee. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class VTAlbumViewController: UIViewController {

    @IBOutlet weak var photosCollectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!

    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var noImagesLabel: UILabel!
    
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    
    var pin: Pin!
    var photos = [Photo]()
    var annotation = MKPointAnnotation()
    
    let client = VTFlickrSearch()
    
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            fetchedResultsController?.delegate = self
            
            if let fc = fetchedResultsController {
                do {
                    try fc.performFetch()
                } catch let e as NSError {
                    print("Error while trying to perform a search: \n\(e)\n\(fetchedResultsController)")
                }
            }
            print(".")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        annotation.coordinate = CLLocationCoordinate2DMake(pin.latitude, pin.longitude)
        
        mapView.addAnnotation(annotation)
        mapView.setCenter(annotation.coordinate, animated: true)

        noImagesLabel.isHidden = true
        doneButton.isEnabled = false
        
        newCollectionButton.isEnabled = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("VTAlbum \(photos.count)")
        print("VTAlbum \(pin.latitude), \(pin.longitude)")
        
        if ( photos.count > 0 ) && ( photos[0].imageData == nil ) {
            downloadImages()
        } else if (photos.count == 0) {
            noImagesLabel.isHidden = false
            doneButton.isEnabled = true
        } else {
            doneButton.isEnabled = true
            newCollectionButton.isEnabled = true
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func dismiss(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func downloadImages() {
        print("2 \(photos.count)")
        
        for photo in self.photos {
            self.client.downloadPhoto(with: photo.imageURL, completionHandler: { (data, error) in
                guard (error == nil) else {
                    print("There is an error: \(error!)")
                    return
                }
                
                guard let data = data else {
                    print("There is no data")
                    return
                }
                
                //print("\(self.fetchedResultsController?.indexPath(forObject: photo)!)")
                
                DispatchQueue.main.async {
                    photo.setValue(data as NSData, forKey: "imageData")
                }
            })
        }
    }
}

extension VTAlbumViewController: MKMapViewDelegate {

}

extension VTAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //print("section: \(section)")
        //print("photos.count: \(photos.count)")
        
        if let fc = fetchedResultsController {
            return fc.sections![section].numberOfObjects
        } else {
            return 0
        }
        
        // return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        //print("\(collectionView)")
        /*
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoImage", for: indexPath) as? VTPhotoCollectionViewCell {
            print("okay")
            return cell
        } else {
            print("bad")
            return UICollectionViewCell()
        }
        */
        
        let photo = fetchedResultsController?.object(at: indexPath) as! Photo
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoImage", for: indexPath) as! VTPhotoCollectionViewCell
        
        // print("\(photos[indexPath.item])")
        
        if let imageData = photo.imageData {
            cell.imageView.image = UIImage(data: imageData as Data)
        } else {
            cell.imageView.backgroundColor = .black
        }

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? VTPhotoCollectionViewCell {
            cell.imageView.backgroundColor = .black
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let context = fetchedResultsController?.managedObjectContext {
            let photo = fetchedResultsController?.object(at: indexPath) as! Photo
            context.delete(photo)
            
            if context.hasChanges {
                do {
                    try context.save()
                    print("Saved after deletion")
                    self.doneButton.isEnabled = true
                    self.newCollectionButton.isEnabled = true
                } catch {
                    print("Error while saving ...")
                }
            }
        }
    }
}

extension VTAlbumViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.doneButton.isEnabled = false
        self.newCollectionButton.isEnabled = false
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let set = IndexSet(integer: sectionIndex)
        
        switch type {
        case .insert:
            photosCollectionView.insertSections(set)
        case .delete:
            photosCollectionView.deleteSections(set)
        default:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            photosCollectionView.insertItems(at: [newIndexPath!])
        case .delete:
            photosCollectionView.deleteItems(at: [indexPath!])
        case .update:
            photosCollectionView.reloadItems(at: [indexPath!])
        case .move:
            photosCollectionView.deleteItems(at: [indexPath!])
            photosCollectionView.insertItems(at: [newIndexPath!])
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        do {
            try fetchedResultsController?.managedObjectContext.save()
            print("Saved")
            self.doneButton.isEnabled = true
            self.newCollectionButton.isEnabled = true
        } catch {
            print("Error while saving ..")
        }
    }
}
