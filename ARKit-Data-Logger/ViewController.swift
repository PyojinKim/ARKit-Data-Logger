//
//  ViewController.swift
//  ARKit-Data-Logger
//
//  Created by kimpyojin on 04/06/2019.
//  Copyright © 2019 Pyojin Kim. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set debug option
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        
        
        // set the view's delegate
        sceneView.delegate = self
        sceneView.showsStatistics = true
        sceneView.session.delegate = self
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    
    // when the ARSession is updated
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        print("Frame updated!")
        // Do something with the new transform
        let currentTransform = frame.camera.transform
        print("x: \(currentTransform.columns.3.x)")
        print("y: \(currentTransform.columns.3.y)")
        print("z: \(currentTransform.columns.3.z)")
        
        //print(currentTransform)
    }
}
