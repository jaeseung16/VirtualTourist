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
    
    // Variables
    let client = VTFlickrSearch()
    
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    
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
            
            let pin = Pin(longitude: coordinate.longitude, latitude: coordinate.latitude, context: context)
            context.insert(pin)
            
            do {
                try context.save()
                print("A pin saved.")
            } catch {
                print("Error while saving the added pin.")
            }
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
        fetchedResultsController?.delegate = self
 
        performFetch(with: fetchedResultsController)
        
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
                print(".")
            } catch {
                print("Error while performing search: \n\(error)\n\(String(describing: fc))")
            }
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
        
        // Getting a Pin from the selected annotation
        performFetch(with: fetchedResultsController)
        
        guard let fc = fetchedResultsController, let pins = fc.fetchedObjects as? [Pin] else {
            print("Cannot convert fetchedObjects into [Pin]")
            return
        }

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
        let photos = fcForAlbumVC.fetchedObjects as! [Photo]
        albumViewController.pin = pinForAlbumVC
    
        if photos.count == 0 {
            let _ = client.searchPhotos(longitude: annotation.coordinate.longitude, latitude: annotation.coordinate.latitude, completionHandler: { (urlArray, error) in
                
                guard (error == nil) else {
                    print("\(String(describing: error))")
                    return
                }

                DispatchQueue.main.async {
                    for url in urlArray! {
                        let photo = Photo(url: url, pin: pinForAlbumVC, context: fcForAlbumVC.managedObjectContext)
                        fcForAlbumVC.managedObjectContext.insert(photo)
                        
                        if fcForAlbumVC.managedObjectContext.hasChanges {
                            do {
                                try fcForAlbumVC.managedObjectContext.save()
                                print("Saved before present")
                            } catch {
                                print("Error while saving ....")
                            }
                        }
                    }
                    
                    albumViewController.fetchedResultsController = fcForAlbumVC
                    self.present(albumViewController, animated: true) {
                        mapView.deselectAnnotation(view.annotation, animated: false)
                    }
                }
            })
        } else {
            albumViewController.fetchedResultsController = fcForAlbumVC
            self.present(albumViewController, animated: true) {
                mapView.deselectAnnotation(view.annotation, animated: false)
            }
        }
    }

}
