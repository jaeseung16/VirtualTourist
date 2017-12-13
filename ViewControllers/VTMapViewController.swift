//
//  VTMapViewController.swift
//  VirtualTourist
//
//  Created by Jae-Seung Lee on 11/16/17.
//  Copyright © 2017 Jae-Seung Lee. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class VTMapViewController: UIViewController, NSFetchedResultsControllerDelegate {
    // MARK: Properties
    // Outlets
    @IBOutlet weak var mapView: MKMapView!
    
    // Client to search and download photos from Flickr
    let client = VTFlickrSearch()
    
    // Variables
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
    
    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchPins()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let region = UserDefaults.standard.object(forKey: "Region") as? [String: Double] {
            loadRegion(region)
        } else {
            saveRegion()
        }
    }
    
    // IBActions
    @IBAction func addPin(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .ended {
            let location = sender.location(in: mapView)
            let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
            
            // Add annotation
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            mapView.addAnnotation(annotation)
            
            guard let context = fetchedResultsController?.managedObjectContext else {
                print("Cannot find the property 'managedObejctContext' from \(String(describing: fetchedResultsController))")
                return
            }
            
            let _ = Pin(longitude: coordinate.longitude, latitude: coordinate.latitude, context: context)
           
            if save(context: context) {
                print("A pin saved.")
            } else {
                print("Error while saving the added pin.")
            }
            
            // Update fetchedResultsController
            performFetch(with: fetchedResultsController)
        }
    }
    
    // Other methods
    func fetchPins() {
        // Get the stack
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let stack = delegate.stack
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "created", ascending: false)]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
        
        if let fetchedObjects = fetchedResultsController?.fetchedObjects {
            let count = fetchedObjects.count
            
            for item in 0..<count {
                let pin = fetchedObjects[item] as! Pin
                
                let coordinate = CLLocationCoordinate2DMake(pin.latitude, pin.longitude)
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                
                mapView.addAnnotation(annotation)
            }
        }
    }
    
    func performFetch(with fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?) {
        if let fc = fetchedResultsController {
            do {
                try fc.performFetch()
            } catch {
                print("Error while performing search: \n\(error)\n\(String(describing: fc))")
            }
        }
    }
    
    func save(context: NSManagedObjectContext) -> Bool {
        if context.hasChanges {
            do {
                try context.save()
                return true
            } catch {
                return false
            }
        } else {
            print("Context has not changed.")
            return false
        }
    }
    
    func loadRegion(_ region: [String: Double]) {
        mapView.setVisibleMapRect(MKMapRectMake(region["x"]!, region["y"]!, region["width"]!, region["height"]!), animated: true)
    }
    
    func saveRegion() {
        let origin = mapView.visibleMapRect.origin
        let size = mapView.visibleMapRect.size
        let region = ["x": origin.x, "y": origin.y, "width": size.width, "height": size.height]
        UserDefaults.standard.set(region, forKey: "Region")
        UserDefaults.standard.synchronize()
    }
}

// MARK: - MKMapViewDelegate
extension VTMapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveRegion()
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        var albumViewController: VTAlbumViewController
        
        albumViewController = self.storyboard?.instantiateViewController(withIdentifier: "albumViewController") as! VTAlbumViewController
        
        guard let annotation = view.annotation else {
            print("Cannot get the annotation.")
            return
        }

        guard let fc = fetchedResultsController, let pins = fc.fetchedObjects as? [Pin] else {
            print("Cannot convert fetchedObjects into [Pin]")
            return
        }

        // Find the selected pin, which will be passed to VTAlbumViewController
        let index = pins.index(where: { ($0.longitude == annotation.coordinate.longitude) && ($0.latitude == annotation.coordinate.latitude) } )!
        let pinForAlbumVC = pins[index]

        // Fetching [Photo] attached to the Pin
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fr.sortDescriptors = [NSSortDescriptor(key: "created", ascending: true)]

        let pred = NSPredicate(format: "pin = %@", argumentArray: [pinForAlbumVC])
        fr.predicate = pred
        
        let fcForAlbumVC = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: fc.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        performFetch(with: fcForAlbumVC)
        
        // Preparing AlbumViewController with Pin and [Photo]
        albumViewController.pin = pinForAlbumVC
        
        let photos = fcForAlbumVC.fetchedObjects as! [Photo]
        if photos.count > 0 {
            // When there are already photos attached to the selected pin
            albumViewController.fetchedResultsController = fcForAlbumVC
            self.present(albumViewController, animated: true) {
                mapView.deselectAnnotation(view.annotation, animated: false)
            }
        } else {
            // When there are no photos attached to the selected pin
            let _ = client.searchPhotos(longitude: pinForAlbumVC.longitude, latitude: pinForAlbumVC.latitude, completionHandler: { (urlArray, error) in
                
                guard (error == nil) else {
                    print("\(String(describing: error))")
                    return
                }
                
                DispatchQueue.main.async {
                    let context = fcForAlbumVC.managedObjectContext
                    for url in urlArray! {
                        let _ = Photo(url: url, pin: pinForAlbumVC, context: context)
                        // It works without explicitly saving the context.
                    }
                    
                    albumViewController.fetchedResultsController = fcForAlbumVC
                    self.present(albumViewController, animated: true) {
                        mapView.deselectAnnotation(view.annotation, animated: false)
                    }
                }
            })
        }
    }

}
