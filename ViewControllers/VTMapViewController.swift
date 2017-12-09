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
    
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?  {
        didSet {
            fetchedResultsController?.delegate = self
            
            if let fc = fetchedResultsController {
                do {
                    try fc.performFetch()
                    print(".")
                } catch {
                    print("Error while performing search: \n\(error)\n\(String(describing: fetchedResultsController))")
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
            
            let pin = Pin(longitude: coordinate.longitude, latitude: coordinate.latitude, context: context)
            context.insert(pin)
            
            do {
                try context.save()
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
        
        guard let pins = fetchedResultsController?.fetchedObjects as? [Pin] else {
            print("Cannot convert fetchedObjects into [Pin]")
            return
        }
        
        let index = pins.index(where: { ($0.longitude == annotation.coordinate.longitude) && ($0.latitude == annotation.coordinate.latitude) } )!

        let pinForAlbumView = pins[index]
        
        print("VTMap \(pinForAlbumView.latitude), \(pinForAlbumView.longitude)")
        
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fr.sortDescriptors = [NSSortDescriptor(key: "created", ascending: true)]

        let pred = NSPredicate(format: "pin = %@", argumentArray: [pinForAlbumView])
        fr.predicate = pred
        
        let fc = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: fetchedResultsController!.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try fc.performFetch()
        } catch let e as NSError {
            print("Error while trying to perform a search: \n\(e)\n\(fetchedResultsController)")
        }
        
        let photos = fc.fetchedObjects as! [Photo]
        albumViewController.pin = pinForAlbumView

        if photos.count == 0 {
            let _ = client.searchPhotos(longitude: annotation.coordinate.longitude, latitude: annotation.coordinate.latitude, completionHandler: { (urlArray, error) in
                
                guard (error == nil) else {
                    print("\(String(describing: error))")
                    return
                }
                
                print("array \(urlArray!.count)")
            
                DispatchQueue.main.async {
                    for url in urlArray! {
                        let photo = Photo(url: url, pin: pinForAlbumView, context: fc.managedObjectContext)
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
                    
                    albumViewController.fetchedResultsController = fc
                    //albumViewController.photos = photos
                    self.present(albumViewController, animated: true)
                }
            })
        } else {
            albumViewController.fetchedResultsController = fc
            //albumViewController.photos = photos
            self.present(albumViewController, animated: true)
        }
    }
}
