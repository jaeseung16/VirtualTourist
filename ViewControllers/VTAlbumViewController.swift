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

class VTAlbumViewController: UIViewController, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var photosCollectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    var annotation: MKAnnotation!
    var photos = [UIImage]()
    
    let keyForFlickerAPI = "1a9583d866ddba940dde065c1528f782"
    let secretForFlickerAPI = "17170ad252ace78c"
    
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        mapView.addAnnotation(annotation)
        mapView.setCenter(annotation.coordinate, animated: true)
        
        /*
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let stack = delegate.stack
        
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fr.sortDescriptors = []
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController?.delegate = self
        */
        
        print("\(photos.count)")
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
        let queryLongitude = URLQueryItem(name: "lon", value: "\(annotation.coordinate.longitude)")
        let queryLatitude = URLQueryItem(name: "lat", value: "\(annotation.coordinate.latitude)")
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
            
            guard let photosDictionary = parsedResult["photos"] as? [String: AnyObject] else {
                print("Cannot find \"photos\" key in \(parsedResult).")
                return
            }
            
            guard let photosArray = photosDictionary["photo"] as? [ [String: AnyObject] ] else {
                print("Cannot find photos in \(photosDictionary).")
                return
            }
            
            for photo in photosArray {
                guard let imageURLString = photo["url_m"] as? String else {
                    break
                }
                
                let imageURL = URL(string: imageURLString)
                if let imageData = try? Data(contentsOf: imageURL!) {
                    DispatchQueue.main.async {
                        self.photos.append(UIImage(data: imageData)!)
                        let index = IndexPath(item: self.photos.count - 1, section: 0)
                        self.photosCollectionView.insertItems(at: [index])
                    }
                } else {
                    print("Image does not exist at \(imageURL)")
                }
                
            }
        }
        
        task.resume()
    }
    
}

extension VTAlbumViewController: MKMapViewDelegate {

}

extension VTAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //print("section: \(section)")
        //print("photos.count: \(photos.count)")
        return photos.count
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoImage", for: indexPath) as! VTPhotoCollectionViewCell
        
        print("\(photos[indexPath.item])")
        
        cell.imageView.image = photos[indexPath.item]
       
        return cell
    }
}
