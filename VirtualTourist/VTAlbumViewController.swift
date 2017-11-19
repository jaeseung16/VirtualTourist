//
//  VTAlbumViewController.swift
//  VirtualTourist
//
//  Created by Jae-Seung Lee on 11/19/17.
//  Copyright © 2017 Jae-Seung Lee. All rights reserved.
//

import UIKit
import MapKit

class VTAlbumViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    var annotation: MKAnnotation!
    
    let keyForFlickerAPI = "1a9583d866ddba940dde065c1528f782"
    let secretForFlickerAPI = "17170ad252ace78c"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        mapView.addAnnotation(annotation)
        mapView.setCenter(annotation.coordinate, animated: true)
        
        searchForPhotos()
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
    
    func searchForPhotos() {
        var component = URLComponents()
        component.scheme = "https"
        component.host = "api.flickr.com"
        component.path = "/services/rest/"
        component.queryItems = [URLQueryItem]()
        
        let queryMethod = URLQueryItem(name: "method", value: "flickr.photos.search")
        let queryAPIKey = URLQueryItem(name: "api_key", value: keyForFlickerAPI)
        let queryFormat = URLQueryItem(name: "format", value: "json")
        let queryAdditionalItem = URLQueryItem(name: "nojsoncallback", value: "1")
        let queryLongitude = URLQueryItem(name: "lon", value: "40")
        let queryLatitude = URLQueryItem(name: "lat", value: "40")
        let queryExtras = URLQueryItem(name: "extras", value: "url_m")
        
        component.queryItems!.append(queryMethod)
        component.queryItems!.append(queryAPIKey)
        component.queryItems!.append(queryFormat)
        component.queryItems!.append(queryAdditionalItem)
        component.queryItems!.append(queryLongitude)
        component.queryItems!.append(queryLatitude)
        component.queryItems!.append(queryExtras)
        
        print("\(component.url)")
        
        let request = URLRequest(url: component.url!)
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                print("error: \(error)")
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                print("statusCode: \((response as? HTTPURLResponse)?.statusCode)")
                return
            }
            
            guard let data = data else {
                print("No data was returned")
                return
            }
            
            let parsedResult: [String: AnyObject]!
            
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: AnyObject]
            } catch {
                print("Cannot parse the data as JSON")
                return
            }
            
            print(parsedResult)
        }
        
        task.resume()
    }
    
}

extension VTAlbumViewController: MKMapViewDelegate {

}

