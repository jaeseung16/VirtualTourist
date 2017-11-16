//
//  VTMapViewController.swift
//  VirtualTourist
//
//  Created by Jae-Seung Lee on 11/16/17.
//  Copyright © 2017 Jae-Seung Lee. All rights reserved.
//

import UIKit
import MapKit

class VTMapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {

        if let region = UserDefaults.standard.object(forKey: "Region") as? [Double] {
            mapView.setVisibleMapRect(MKMapRectMake(region[0], region[1], region[3], region[2]), animated: true)
        } else {
            let origin = mapView.visibleMapRect.origin
            let size = mapView.visibleMapRect.size
            let region = [origin.x, origin.y, size.height, size.width]
            UserDefaults.standard.set(region, forKey: "Region")
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

    @IBAction func addPin(_ sender: UILongPressGestureRecognizer) {
        let location = sender.location(in: mapView)
        let coordinate = mapView.convert(location,toCoordinateFrom: mapView)
        
        // Add annotation:
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        
        print("\(location), \(coordinate)")
    }
}

// MARK: - MKMapViewDelegate
extension VTMapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let origin = mapView.visibleMapRect.origin
        let size = mapView.visibleMapRect.size
        let region = [origin.x, origin.y, size.height, size.width]
        UserDefaults.standard.set(region, forKey: "Region")
    }
}
