//
//  Extensions.swift
//  ARLocations
//
//  Created by Premkumar  on 11/04/19.
//  Copyright © 2019 Kathiresan. All rights reserved.
//

import Foundation
import UIKit


// MARK: - Floarting point Extension functions.
extension FloatingPoint {
    
    func toRadians() -> Self {
        return self * .pi / 180
    }
    
    func toDegrees() -> Self {
        return self * 180 / .pi
    }
}

// MARK: - String Extension functions.
extension String {
    
    /// Convert String to Image
    ///
    /// - Returns: image.
    func image() -> UIImage? {
        // Size of Image
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIColor.white.set() //clear.set()
        
        let rect = CGRect(origin: CGPoint(), size: size)
        UIRectFill(CGRect(origin: CGPoint(), size: size))
        (self as NSString).draw(in: rect, withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 90)])
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
