//
//  ViewController.swift
//  ARLocations
//
//  Created by Premkumar  on 10/04/19.
//  Copyright © 2019 Kathiresan. All rights reserved.
//

import UIKit
import SceneKit

import ARKit
import CoreLocation

/// ViewController for AR Locations. Location based AR
class ViewController: UIViewController {
    
    /// All Places
    var places: [Place] = [Place(name: "L", lati: 11.053791, lngi: 76.990920, id: 1),
                           Place(name: "R", lati: 11.051854, lngi: 76.991360, id: 2),
                           Place(name: "F", lati: 11.052917, lngi: 76.990507, id: 3),
                           Place(name: "B", lati: 11.053418, lngi: 76.992725, id: 4)]
    
    /// AR Scene View
    @IBOutlet var sceneView: ARSCNView!
    
    /// Information View
    @IBOutlet weak var infoView: UIView!
    
    /// Core Location manager
    var locationMananger = CLLocationManager()
    
    /// User location
    var userLocation: CLLocation {
        return locationMananger.location ?? CLLocation()
    }
    
    /// Model nodes
    var modelNodes = [SCNNode]() //= Array.init(repeating: SCNNode.self, count: places.count)
    
    /// Original Transformations
    var originalTransform: SCNMatrix4!
    
    /// AR World Tracking Configuration
    let configuration = ARWorldTrackingConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        scene.rootNode.name = "Root node"
        // Set the scene to the view
        sceneView.scene = scene
        
        // Location manager Configuration
        locationMananger.delegate = self
        locationMananger.desiredAccuracy = kCLLocationAccuracyBest
        locationMananger.requestWhenInUseAuthorization()
        
        print("Getting current location")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DispatchQueue.main.async {
            self.infoView.isHidden = true
        }
        
        // Create a session configuration
        configuration.worldAlignment = .gravityAndHeading
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    /// Fetch Places from Static or Dynamic in this method.
    func fetchPlace() {
        print("Setting Places.")
        updateLocation(places)
    }
}

// MARK: - CLLocationManagerDelegate
extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error on fetch location: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationMananger.requestLocation() // Fetch location at once.
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.fetchPlace()
    }
}

// MARK: - Utility Methods
extension ViewController {
    
    /// Update locations.
    ///
    /// - Parameter places: Places.
    func updateLocation(_ places: [Place]) {
        // Enumerating places.
        places.enumerated().forEach { (offset, place) in
            
            var localPlace = place
            localPlace.distance = Float(place.location.distance(from: self.userLocation)) // Calculate estimated distance from userlocation to
            self.places[offset].distance = localPlace.distance // Saving Distance to places.
            
            //  if self.modelNode == nil {
            // Creating Model Scene
            let modelScene = SCNScene() //named: "art.scnassets/Car.dae")!
            
            // Creating node.
            let node = SCNNode()
            node.name = "BaseNode: \(localPlace.name)"
            
            // Add Child node to rootnode of model scene.
            modelScene.rootNode.addChildNode(node)
            
            // append Child node to modelNodes.
            modelNodes.append(modelScene.rootNode.childNode(withName: "BaseNode: \(localPlace.name)", recursively: true)! )
            
            // Move model's pivot to its center in the Y axis
            let (minBox, maxBox) = self.modelNodes.last!.boundingBox
            self.modelNodes.last!.pivot = SCNMatrix4MakeTranslation(0, (maxBox.y - minBox.y)/2, 0)
            
            // Save original transform to calculate future rotations
            self.originalTransform = self.modelNodes.last!.transform
            
            // Position the model in the correct place
            positionModel(localPlace)
            
            // Add the model to the scene
            sceneView.scene.rootNode.addChildNode(self.modelNodes.last!)
            
            // Create arrow from the emoji
            let boardNode = makeBillboardNode(localPlace.name.image()!)
            // Position it on top of the car
            boardNode.position = SCNVector3Make(0, 4, 0)
            boardNode.name = localPlace.name
            // Add it as a child of the car model
            self.modelNodes.last!.addChildNode(boardNode)
            //            } else {
            //                // Begin animation
            //                SCNTransaction.begin()
            //                SCNTransaction.animationDuration = 1.0
            //
            //                // Position the model in the correct place
            //                positionModel(localPlace)
            //
            //                // End animation
            //                SCNTransaction.commit()
            //            }
        }
        
    }
    
    /// Position Model. Setting node in position
    ///
    /// - Parameter place: place
    func positionModel(_ place: Place) {
        // Rotate node
        self.modelNodes.last!.transform = rotateNode(Float(-1 * (place.heading - 180).toRadians()), self.originalTransform)
        
        // Translate node
        self.modelNodes.last!.position = translateNode(place)
        
        // Scale node
        self.modelNodes.last!.scale = scaleNode(place)
    }
    
    func rotateNode(_ angleInRadians: Float, _ transform: SCNMatrix4) -> SCNMatrix4 {
        let rotation = SCNMatrix4MakeRotation(angleInRadians, 0, 1, 0)
        return SCNMatrix4Mult(transform, rotation)
    }
    
    func translateNode (_ place: Place) -> SCNVector3 {
        let locationTransform = transformMatrix(matrix_identity_float4x4, userLocation, place)
        return positionFromTransform(locationTransform)
    }
    
    func scaleNode (_ place: Place) -> SCNVector3 {
        let scale = max( min( Float(1000/place.distance), 1.5 ), 3 )
        return SCNVector3(x: scale, y: scale, z: scale)
    }
    
    func positionFromTransform(_ transform: simd_float4x4) -> SCNVector3 {
        return SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
    }
    
    func transformMatrix(_ matrix: simd_float4x4, _ originLocation: CLLocation, _ localPlace: Place) -> simd_float4x4 {
        let bearing = bearingBetweenLocations(userLocation, localPlace.location)
        let rotationMatrix = rotateAroundY(matrix_identity_float4x4, Float(bearing))
        
        let position = vector_float4(0.0, 0.0, -localPlace.distance, 0.0)
        let translationMatrix = getTranslationMatrix(matrix_identity_float4x4, position)
        
        let transformMatrix = simd_mul(rotationMatrix, translationMatrix)
        
        return simd_mul(matrix, transformMatrix)
    }
    
    func getTranslationMatrix(_ matrix: simd_float4x4, _ translation : vector_float4) -> simd_float4x4 {
        var matrix = matrix
        matrix.columns.3 = translation
        return matrix
    }
    
    func rotateAroundY(_ matrix: simd_float4x4, _ degrees: Float) -> simd_float4x4 {
        var matrix = matrix
        
        matrix.columns.0.x = cos(degrees)
        matrix.columns.0.z = -sin(degrees)
        
        matrix.columns.2.x = sin(degrees)
        matrix.columns.2.z = cos(degrees)
        return matrix.inverse
    }
    
    func bearingBetweenLocations(_ originLocation: CLLocation, _ driverLocation: CLLocation) -> Double {
        let lat1 = originLocation.coordinate.latitude.toRadians()
        let lon1 = originLocation.coordinate.longitude.toRadians()
        
        let lat2 = driverLocation.coordinate.latitude.toRadians()
        let lon2 = driverLocation.coordinate.longitude.toRadians()
        
        let longitudeDiff = lon2 - lon1
        
        let y = sin(longitudeDiff) * cos(lat2);
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(longitudeDiff);
        
        return atan2(y, x)
    }
    
    
    /// Creating Image to Node
    ///
    /// - Parameter image: image
    /// - Returns: Scene node.
    func makeBillboardNode(_ image: UIImage) -> SCNNode {
        
        /// Creating plane
        let plane = SCNPlane(width: 10, height: 10)
        plane.firstMaterial!.diffuse.contents = image
        
        // Creating node.
        let node = SCNNode(geometry: plane)
        node.constraints = [SCNBillboardConstraint()]
        return node
    }
}


extension ViewController: ARSCNViewDelegate {
    
    /// Restart Session without Delete
    func restartSessionWithoutDelete() {
        // Restart session with a different worldAlignment - prevents bug from crashing app
        self.sceneView.session.pause()
        
        self.sceneView.session.run(configuration, options: [
            .resetTracking,
            .removeExistingAnchors])
    }
    
    // MARK: - ARSCNViewDelegate
    
    // Override to create and configure nodes for anchors added to the view's session.
    /*  func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
     let node = SCNNode()
     
     return node
     }
     */
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // Auto trigger always.
        
        if let pointOfView = sceneView.pointOfView {
            let visibleNodes = sceneView.nodesInsideFrustum(of: pointOfView)
            
            if visibleNodes.isEmpty {
                DispatchQueue.main.async {
                    self.infoView.isHidden = true
                }
            } else {
                let results = visibleNodes.filter({ $0.name != nil })
                
                for result in results {
                    if let nodeName = result.name {
                        showInfoView(nodeName)
                    }
                }
            }
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
        if let arError = error as? ARError {
            if arError.errorCode == 102 {
                configuration.worldAlignment = .gravityAndHeading
                restartSessionWithoutDelete()
            } else {
                restartSessionWithoutDelete()
                
            }
        }
    }
    /*
     func sessionWasInterrupted(_ session: ARSession) {
     // Inform the user that the session has been interrupted, for example, by presenting an overlay
     
     }
     
     func sessionInterruptionEnded(_ session: ARSession) {
     // Reset tracking and/or remove existing anchors if consistent tracking is required
     }
     */
}


extension ViewController {
    
    /// Fetch node and show node information in InfoView
    ///
    /// - Parameter name: Node name
    fileprivate func showInfoView(_ name: String) {
        DispatchQueue.main.async {
            self.infoView.isHidden = false
            
            let label = self.infoView.subviews.first as! UILabel
            
            if let selectedNode = self.places.filter({$0.name == name}).first {
                label.text = "Object name: \(name)\nDistance to reach: \(selectedNode.distance.rounded(.toNearestOrEven)) M"
            }
        }
    }
    /*
    
    // If User Tapped InfoView will automatically show or hide.
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        guard let touch = touches.first ,let touchedSCNView = touch.view as? ARSCNView else { return }
        let touchedLocation = touch.location(in: touchedSCNView)
        
        let results = touchedSCNView.hitTest(touchedLocation, options: [SCNHitTestOption.searchMode : 1]).filter({ $0.node.name != nil })
        
        for result in results {
            if let nodeName = result.node.name {
                showInfoView(nodeName)
            }
        }
    }
    */
}
