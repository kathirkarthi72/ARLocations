//
//  Place.swift
//  ARLocations
//
//  Created by Premkumar  on 11/04/19.
//  Copyright © 2019 Kathiresan. All rights reserved.
//

import Foundation
import CoreLocation
import SceneKit

/// Place
struct Place {
    
    /// Show Name.
    var name: String
    
    /// Latitude
    var lati: Double
    /// Longitude
    var lngi: Double
    
    /// Place ID.
    var placeID: Int
    
    /// Heading
    var heading: Double
    
    /// Distance between user location
    var distance: Float
    
    /// Initialize Place
    ///
    /// - Parameters:
    ///   - name: Name
    ///   - lati: Latitude
    ///   - lngi: Longitude
    ///   - id: Place Id
    ///   - heading: Heading
    ///   - distance: Distance
    init(name: String, lati: Double, lngi: Double, id: Int, heading: Double = 0.0, distance: Float = 0.0) {
        
        self.name = name
        self.lati = lati
        self.lngi = lngi
        
        self.placeID = id
        
        self.heading = heading
        self.distance = distance
    }
    
    /// Get location of place
    var location: CLLocation {
        return CLLocation(latitude: lati, longitude: lngi)
    }
    
}
