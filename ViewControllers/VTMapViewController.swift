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

    @IBOutlet weak var mapView: MKMapView!
    
    var pins = [Pin]()
    
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        // Get the stack
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let stack = delegate.stack
        
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        fr.sortDescriptors = []
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: (stack?.context)!, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController?.delegate = self
        search()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let region = UserDefaults.standard.object(forKey: "Region") as? [String: Double] {
            loadRegion(region)
        } else {
            saveRegion()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func addPin(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .ended {
            let location = sender.location(in: mapView)
            let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
            
            // Add annotation:
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            mapView.addAnnotation(annotation)
            
            if let context = fetchedResultsController?.managedObjectContext {
                let pin = Pin(longitude: coordinate.longitude, latitude: coordinate.latitude, context: context)
                pins.append(pin)
            }
            
            print("\(pins.count) \(mapView.annotations.count)")
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
            print("No annotation")
            return
        }
        
        print("\(annotation)")
        albumViewController.annotation = annotation as MKAnnotation
        
        present(albumViewController, animated: true)
    }
}

// MARK: - CoreData, Fetches

extension VTMapViewController {
    func search() {
        if let fc = fetchedResultsController {
            do {
                try fc.performFetch()
            } catch let error as NSError {
                print("Error while trying to perform a search: \n\(error)\n\(String(describing: fetchedResultsController))")
            }
        }
    }
}
