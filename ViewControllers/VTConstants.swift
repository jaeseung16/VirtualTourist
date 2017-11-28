//
//  VTConstants.swift
//  VirtualTourist
//
//  Created by Jae Seung Lee on 11/27/17.
//  Copyright © 2017 Jae-Seung Lee. All rights reserved.
//

import Foundation

extension VTFlickrSearch {
    // MARK: Key and Secret for Flickr API
    static let keyForAPI = "1a9583d866ddba940dde065c1528f782"
    static let secretForAPI = "17170ad252ace78c"
    
    // MARK: - Constants for URLComponents
    struct Constant {
        static let scheme = "https"
        static let host = "api.flickr.com"
        static let path = "/services/rest/"
    }
    
    struct QueryKey {
        static let Method = "method"
        static let APIKey = "api_key"
        static let Format = "format"
        static let Longitude = "lon"
        static let Latitude = "lat"
        static let Extras = "extras"
        static let NoJSONCallBack = "nojsoncallback"
    }
    
    struct QueryValue {
        static let Method = "flickr.photos.search"
        static let Format = "json"
        static let MediumURL = "url_m"
        static let DisableJSONCallBack = "1"
    }
    
}