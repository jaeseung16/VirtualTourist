//
//  VTFlickrSearch.swift
//  VirtualTourist
//
//  Created by Jae Seung Lee on 11/27/17.
//  Copyright © 2017 Jae-Seung Lee. All rights reserved.
//

import Foundation

class VTFlickrSearch {
    // MARK: Properties
    var session = URLSession.shared
    
    var imageURLArray = [String]()
    
    // MARK: - Methods
    func downloadPhoto(with imageURL: String, completionHandler: @escaping (_ data: Data?, _ error: String?) -> Void ) {
        guard let url = URL(string: imageURL) else {
            completionHandler(nil, "Invalid URL for an image,")
            return
        }
        
        let _ = dataTask(with: url) { (data, error) in
            guard (error == nil) else {
                guard let errorString = error!.userInfo[NSLocalizedDescriptionKey] as? String else {
                    completionHandler(nil, "There was an unknown error with your request.")
                    return
                }
                
                // Distinguish an error due to time-out from one caused by wrong credentials.
                if errorString.starts(with: "There was an error with your request: ") {
                    completionHandler(nil, "The request timed out.")
                } else if errorString == "Your request returned a status code other than 2xx!" {
                    completionHandler(nil, "Invalid request.")
                } else {
                    completionHandler(nil, "\(errorString)")
                }
                return
            }
            
            guard let data = data else {
                completionHandler(nil, "No data was returned by the request!")
                return
            }
            
            completionHandler(data, nil)
        }
    }
    
    func searchPhotos(longitude: Double, latitude: Double, completionHandler: @escaping (_ urlArray: [String]?, _ error: String?) -> Void) {
        let url = searchURL(longitude: longitude, latitude: latitude, page: 1)
        
        let _ = dataTask(with: url) { (data, error) in
            guard (error == nil) else {
                guard let errorString = error!.userInfo[NSLocalizedDescriptionKey] as? String else {
                    completionHandler(nil, "There was an unknown error with your request.")
                    return
                }
                
                // Distinguish an error due to time-out from one caused by wrong credentials.
                if errorString.starts(with: "There was an error with your request: ") {
                    completionHandler(nil, "The request timed out.")
                } else if errorString == "Your request returned a status code other than 2xx!" {
                    completionHandler(nil, "Invalid request.")
                } else {
                   completionHandler(nil, "\(errorString)")
                }
                return
            }
            
            guard let photosDictionary = self.parseJSON(with: data!) else {
                completionHandler(nil, "Cannot parse the data as JSON")
                return
            }
            
            guard let pages = photosDictionary["pages"] as? Int else {
                completionHandler(nil, "Cannot find the pages key,")
                return
            }
            
            let page = Int(arc4random_uniform(UInt32(pages)) + 1)
            let url = self.searchURL(longitude: longitude, latitude: latitude, page: page)
            
            let _ = self.dataTask(with: url) { (data, error) in
                guard (error == nil) else {
                    guard let errorString = error!.userInfo[NSLocalizedDescriptionKey] as? String else {
                        completionHandler(nil, "There was an unknown error with your request.")
                        return
                    }
                    
                    // Distinguish an error due to time-out from one caused by wrong credentials.
                    if errorString.starts(with: "There was an error with your request: ") {
                        completionHandler(nil, "The request timed out.")
                    } else if errorString == "Your request returned a status code other than 2xx!" {
                        completionHandler(nil, "Invalid request.")
                    } else {
                        completionHandler(nil, "\(errorString)")
                    }
                    return
                }
                
                guard let photosDictionary = self.parseJSON(with: data!) else {
                    completionHandler(nil, "Cannot parse the data as JSON")
                    return
                }
                
                guard let pages = photosDictionary["pages"] as? Int else {
                    return
                }
                
                guard let page = photosDictionary["page"] as? Int else {
                    return
                }
                
                guard let perpage = photosDictionary["perpage"] as? Int else {
                    return
                }
                
                print("page = \(page), pages = \(pages), perpage = \(perpage)")
                
                guard let photosArray = photosDictionary["photo"] as? [ [String: AnyObject] ] else {
                    completionHandler(nil, "Cannot find the photo key.")
                    return
                }
                
                for photo in photosArray {
                    self.imageURLArray.append((photo["url_m"] as? String)!)
                }
                
                completionHandler(self.imageURLArray, nil)
                self.imageURLArray = []
            }
            
        }
    }
    
    func parseJSON(with data: Data) -> [String: AnyObject]? {
        let parsedResult: [String: AnyObject]!
        
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: AnyObject]
        } catch {
            return nil
        }
        
        guard let photosDictionary = parsedResult["photos"] as? [String: AnyObject] else {
            return nil
        }
        
        return photosDictionary
    }
    
    func searchURL(longitude: Double, latitude: Double, page: Int) -> URL {
        var component = URLComponents()
        component.scheme = Constant.scheme
        component.host = Constant.host
        component.path = Constant.path
        component.queryItems = [URLQueryItem]()
        
        let queryMethod = URLQueryItem(name: QueryKey.Method, value: QueryValue.Method)
        let queryAPIKey = URLQueryItem(name: QueryKey.APIKey, value: VTFlickrSearch.keyForAPI)
        let queryFormat = URLQueryItem(name: QueryKey.Format, value: QueryValue.Format)
        let queryAdditionalItem = URLQueryItem(name: QueryKey.NoJSONCallBack, value: QueryValue.DisableJSONCallBack)
        let queryLongitude = URLQueryItem(name: QueryKey.Longitude, value: "\(longitude)")
        let queryLatitude = URLQueryItem(name: QueryKey.Latitude, value: "\(latitude)")
        let queryExtras = URLQueryItem(name: QueryKey.Extras, value: QueryValue.MediumURL)
        let queryPerPage = URLQueryItem(name: QueryKey.PerPage, value: QueryValue.PerPage)
        let queryPage = URLQueryItem(name: QueryKey.Page, value: "\(page)")
        
        component.queryItems!.append(queryMethod)
        component.queryItems!.append(queryAPIKey)
        component.queryItems!.append(queryFormat)
        component.queryItems!.append(queryAdditionalItem)
        component.queryItems!.append(queryLongitude)
        component.queryItems!.append(queryLatitude)
        component.queryItems!.append(queryExtras)
        component.queryItems!.append(queryPerPage)
        component.queryItems!.append(queryPage)
        
        return component.url!
    }
    
    func dataTask(with url: URL, completionHandler: @escaping (_ data: Data?, _ error: NSError?) -> Void) -> URLSessionDataTask {
        
        let request = URLRequest(url: url)
        
        let task = session.dataTask(with: request) { (data, response, error) in
            func sendError(_ error: String) {
                let userInfo = [NSLocalizedDescriptionKey: error]
                completionHandler(nil, NSError(domain: "dataTask", code: 1, userInfo: userInfo))
            }
            
            guard (error == nil) else {
                sendError("There was an error with your request: \(error!)")
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                sendError("Your request returned a status code other than 2xx!")
                return
            }
            
            guard let data = data else {
                sendError("No data was returned by the request!")
                return
            }
            
            completionHandler(data, nil)
        }
        
        task.resume()
        return task
    }
}
