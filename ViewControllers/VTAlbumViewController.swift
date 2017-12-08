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
        
        let photos = fetchedResultsController?.fetchedObjects as! [Photo]
        
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
        if let fc = fetchedResultsController {
            do {
                try fc.performFetch()
            } catch let e as NSError {
                print("Error while trying to perform a search: \n\(e)\n\(fetchedResultsController)")
            }
        }
        
        let photos = fetchedResultsController?.fetchedObjects as! [Photo]
        
        print("2 \(photos.count)")
        
        for photo in photos {
            let indexPath = fetchedResultsController?.indexPath(forObject: photo)
            let object = fetchedResultsController?.object(at: indexPath!) as! Photo
            
            self.client.downloadPhoto(with: object.imageURL, completionHandler: { (data, error) in
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
                    object.setValue(data as NSData, forKey: "imageData")
                    /*
                    if (self.fetchedResultsController?.managedObjectContext.hasChanges)! {
                        do {
                            try self.fetchedResultsController?.managedObjectContext.save()
                            print("Saved before renewal")
                            self.doneButton.isEnabled = true
                            self.newCollectionButton.isEnabled = true
                        } catch {
                            print("Error while saving ....")
                        }
                    }*/
                }
            })
        }
    }
    
    @IBAction func renewImages(_ sender: UIBarButtonItem) {
        if let fc = fetchedResultsController {
            do {
                try fc.performFetch()
            } catch let e as NSError {
                print("Error while trying to perform a search: \n\(e)\n\(fetchedResultsController)")
            }
        }
        
        var photos = fetchedResultsController?.fetchedObjects as! [Photo]
        
        print("2 \(photos.count)")
        
        if let context = fetchedResultsController?.managedObjectContext {
            for photo in photos{
                context.delete(photo)
                
                if context.hasChanges {
                    do {
                        try context.save()
                        print("Saved before renewal")
                        self.doneButton.isEnabled = true
                        self.newCollectionButton.isEnabled = true
                    } catch {
                        print("Error while saving ....")
                    }
                }
            }
        }
        
        if let fc = fetchedResultsController {
            do {
                try fc.performFetch()
            } catch let e as NSError {
                print("Error while trying to perform a search: \n\(e)\n\(fetchedResultsController)")
            }
        }
        
        photos = fetchedResultsController?.fetchedObjects as! [Photo]
        print("\(photos.count)")
        
        let _ = client.searchPhotos(longitude: annotation.coordinate.longitude, latitude: annotation.coordinate.latitude, completionHandler: { (urlArray, error) in
            
            guard (error == nil) else {
                print("\(String(describing: error))")
                return
            }
            
            print("array \(urlArray!.count)")
            
            DispatchQueue.main.async {
                let fc = self.fetchedResultsController!
                photos = fc.fetchedObjects as! [Photo]
                print("queue \(photos.count)")
                
                for url in urlArray! {
                    let photo = Photo(url: url, pin: self.pin, context: fc.managedObjectContext)
                    
                    fc.managedObjectContext.insert(photo)
                    
                    if fc.managedObjectContext.hasChanges {
                        do {
                            try fc.managedObjectContext.save()
                            print("Saved before present")
                        } catch {
                            print("Error while saving ....")
                        }
                    }
                }
                
                if fc.managedObjectContext.hasChanges {
                    do {
                        try fc.managedObjectContext.save()
                        print("Saved before present")
                    } catch {
                        print("Error while saving ....")
                    }
                }
                
                if let fc = self.fetchedResultsController {
                    do {
                        try fc.performFetch()
                    } catch let e as NSError {
                        print("Error while trying to perform a search: \n\(e)\n\(self.fetchedResultsController)")
                    }
                }
                
                photos = self.fetchedResultsController?.fetchedObjects as! [Photo]
                print("queue \(photos.count)")
                
                self.downloadImages()
            }
            
        })
        
        /*
        photos.removeAll()
        print("\(photos.count)")
        
        do {
            try stack.saveContext()
        } catch {
            print("error....")
        }
        
        if let fc = fetchedResultsController {
            do {
                try fc.performFetch()
            } catch let e as NSError {
                print("Error while trying to perform a search: \n\(e)\n\(fetchedResultsController)")
            }
        }*/
        
        
        /*
        for photo in photos {
            if let context = fetchedResultsController?.managedObjectContext {
                fetchedResultsController?.managedObjectContext.delete(photo)
                
                if context.hasChanges {
                    do {
                        try context.save()
                        print("Saved before renewal")
                        self.doneButton.isEnabled = true
                        self.newCollectionButton.isEnabled = true
                    } catch {
                        print("Error while saving ....")
                    }
                }
            }
        }
        
        print("\(photos.count)")
        
        
        let _ = client.searchPhotos(longitude: annotation.coordinate.longitude, latitude: annotation.coordinate.latitude, completionHandler: { (urlArray, error) in
            
            guard (error == nil) else {
                print("\(String(describing: error))")
                return
            }
            
            print("array \(urlArray!.count)")
            for url in urlArray! {
                let photo = Photo(url: url, pin: self.pins[index], context: fc.managedObjectContext)
                photos.append(photo)
            }
            
        })*/
        
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
            cell.imageView.image = nil
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
        if let context = fetchedResultsController?.managedObjectContext {
            if context.hasChanges {
                do {
                    try context.save()
                    print("Saved after content changed")
                    self.doneButton.isEnabled = true
                    self.newCollectionButton.isEnabled = true
                } catch {
                    print("Error while saving ..")
                }
            }
        }
    }
}
