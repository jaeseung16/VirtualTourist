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

class VTAlbumViewController: UIViewController, MKMapViewDelegate {
    // MARK: Properties
    // Outlets
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var photosCollectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
   
    @IBOutlet weak var noImagesLabel: UILabel!
    
    // Constants
    let client = VTFlickrSearch()
    let space: CGFloat = 3.0
    
    // Variables
    var pin: Pin!
    
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            fetchedResultsController?.delegate = self
            
            if let fc = fetchedResultsController {
                do {
                    try fc.performFetch()
                } catch {
                    print("Error while trying to perform a search: \n\(error)\n\(String(describing: fetchedResultsController))")
                }
            }
        }
    }
    
    // MARK: - Methods for UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()

        setMKMapView()
        setCollectionView()
        setButtons(on: false)
        noImagesLabel.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadImages()
    }
    
    func loadImages() {
        guard let photos = fetchedResultsController?.fetchedObjects as? [Photo] else {
            print("Cannot fetch [Photo]'s.")
            return
        }
        
        print("VTAlbum \(photos.count)")
        
        if ( photos.count > 0 ) && ( photos[0].imageData == nil ) {
            downloadImages()
        } else if (photos.count == 0) {
            noImagesLabel.isHidden = false
            doneButton.isEnabled = true
        } else {
            setButtons(on: true)
        }
    }
    
    func setMKMapView() {
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2DMake(pin.latitude, pin.longitude)
        
        mapView.addAnnotation(annotation)
        mapView.setCenter(annotation.coordinate, animated: true)
        
        print("VTAlbum \(pin.latitude), \(pin.longitude)")
    }
    
    func setCollectionView() {
        adjustFlowLayoutSize(size: self.view.frame.size)
    }
    
    func setButtons(on: Bool) {
        doneButton.isEnabled = on
        newCollectionButton.isEnabled = on
    }

    // MARK: - IBActions
    @IBAction func dismiss(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
        
        // Probably save context
        // Better have a function to save
    }
    
    func downloadImages() {
        /*if let fc = fetchedResultsController {
            do {
                try fc.performFetch()
            } catch let e as NSError {
                print("Error while trying to perform a search: \n\(e)\n\(fetchedResultsController)")
            }
        }
        */
        setButtons(on: false)
        
        guard let fetchedObjects = fetchedResultsController?.fetchedObjects else {
            return
        }
        
        let count = fetchedObjects.count
        
        let photos = fetchedResultsController?.fetchedObjects as! [Photo]
        
        print("2 \(photos.count)")
        
        for k in 0..<count {
            // let indexPath = fetchedResultsController?.indexPath(forObject: photo)
            let indexPath = IndexPath(item: k, section: 0)
            let object = fetchedResultsController?.object(at: indexPath) as! Photo
            
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
        setButtons(on: false)
        
        var photos = fetchedResultsController?.fetchedObjects as! [Photo]
 
        print("Before renew \(photos[0].imageURL)")
        
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
        print("2 count \(photos.count)")
        
        setButtons(on: false)
        
        let _ = client.searchPhotos(longitude: pin.longitude, latitude: pin.latitude, completionHandler: { (urlArray, error) in
            
            guard (error == nil) else {
                print("\(String(describing: error))")
                return
            }
            
            print("array \(urlArray!.count)")
            
            DispatchQueue.main.async {
                let fc = self.fetchedResultsController!
                //self.photos = fc.fetchedObjects as! [Photo]
                print("First url \(urlArray![0])")
                
                for url in urlArray! {
                    let photo = Photo(url: url, pin: self.pin, context: fc.managedObjectContext)
                    
                    // fc.managedObjectContext.insert(photo)
                    
                    if fc.managedObjectContext.hasChanges {
                        do {
                            try fc.managedObjectContext.save()
                            print("Saved before present")
                        } catch {
                            print("Error while saving during inserting a photo")
                        }
                    }
                }
                
                if fc.managedObjectContext.hasChanges {
                    do {
                        try fc.managedObjectContext.save()
                        print("Saved before present..")
                    } catch {
                        print("Error while saving after inserting photos")
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
                print("After renew \(photos[0].imageURL)")
            }
            
        })
        
    }
}

// MARK: - UICollectionViewDelegate and UICollectionViewData Source
extension VTAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let fc = fetchedResultsController {
            return fc.sections![section].numberOfObjects
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoImage", for: indexPath) as! VTPhotoCollectionViewCell
        
        cell.imageView.image = nil
        cell.imageView.backgroundColor = .black
        cell.activityIndicator.startAnimating()
        
        if let fc = fetchedResultsController {
            let photo = fc.object(at: indexPath) as! Photo
            
            if let imageData = photo.imageData {
                cell.imageView.image = UIImage(data: imageData as Data)
                cell.activityIndicator.stopAnimating()
            }
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
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        // This method is called when the orientaition of a device changes even before the view controller is loaded.
        // So checking whether flowLayout exists before updating the collection view
        if self.flowLayout != nil {
            self.flowLayout.invalidateLayout()
            adjustFlowLayoutSize(size: size)
        }
    }
    
    func adjustFlowLayoutSize(size: CGSize) {
        let dimension = cellSize(size: size, space: self.space)
        
        self.flowLayout.minimumInteritemSpacing = self.space
        self.flowLayout.minimumLineSpacing = self.space
        self.flowLayout.itemSize = CGSize(width: dimension, height: dimension)
    }
    
    func cellSize(size: CGSize, space: CGFloat) -> CGFloat {
        let height = size.height
        let width = size.width
        
        let numberInRowPortrait = 4.0
        let numberInRowLandscape = 6.0
        
        let numberInRow = height > width ? CGFloat(numberInRowPortrait) : CGFloat(numberInRowLandscape)
        
        return ( width - (numberInRow - 1) * space ) / numberInRow
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension VTAlbumViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // setButtons(on: false)
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
                    setButtons(on: true)
                } catch {
                    print("Error while saving ..")
                }
            }
        }
    }
}
