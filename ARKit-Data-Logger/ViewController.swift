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
import os.log


class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
    // cellphone screen UI outlet objects
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet var sceneView: ARSCNView!
    
    
    // constants for collecting data
    var isRecording: Bool = false
    let customQueue: DispatchQueue = DispatchQueue(label: "pyojinkim.me")
    
    
    // variables for measuring time in iOS clock
    var recordingTimer: Timer = Timer()
    var secondCounter: Int64 = 0 {
        didSet {
            statusLabel.text = interfaceIntTime(second: secondCounter)
        }
    }
    let mulSecondToNanoSecond: Double = 1000000000
    
    
    // text file input & output
    var fileHandler = [FileHandle]()
    var fileURL = [URL]()
    var fileName: String = "ARKit_data_collection.txt"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set debug option
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        
        
        // change status text to "Ready"
        statusLabel.text = "Ready"
        
        
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
    
    
    // when the Start/Stop button is pressed
    @IBAction func startStopButtonPressed(_ sender: UIButton) {
        if (self.isRecording == false) {
            
            // start ARKit data recording
            customQueue.async {
                if (self.createFiles()) {
                    DispatchQueue.main.async {
                        // reset timer
                        self.secondCounter = 0
                        self.recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (Timer) -> Void in
                            self.secondCounter += 1
                        })
                        
                        // update UI
                        self.startStopButton.setTitle("Stop", for: .normal)
                        
                        // make sure the screen won't lock
                        UIApplication.shared.isIdleTimerDisabled = true
                    }
                    self.isRecording = true
                } else {
                    self.errorMsg(msg: "Failed to create the file")
                    return
                }
            }
        } else {
            
            // stop recording and share the recorded text file
            if (recordingTimer.isValid) {
                recordingTimer.invalidate()
            }
            
            customQueue.async {
                self.isRecording = false
                for handler in self.fileHandler {
                    handler.closeFile()
                }
                DispatchQueue.main.async {
                    let activityVC = UIActivityViewController(activityItems: self.fileURL, applicationActivities: nil)
                    self.present(activityVC, animated: true, completion: nil)
                }
            }
            
            // initialize UI on the screen
            self.startStopButton.setTitle("Start", for: .normal)
            self.statusLabel.text = "Ready"
            
            // resume screen lock
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
    
    
    // define if ARSession is didUpdate (callback function)
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        print("Frame updated!")
        // Do something with the new transform
        let currentTransform = frame.camera.transform
        print("x: \(currentTransform.columns.3.x)")
        print("y: \(currentTransform.columns.3.y)")
        print("z: \(currentTransform.columns.3.z)")
        
        //print(currentTransform)
    }
    
    
    // some useful functions
    private func errorMsg(msg: String) {
        DispatchQueue.main.async {
            let fileAlert = UIAlertController(title: "IMURecorder", message: msg, preferredStyle: .alert)
            fileAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(fileAlert, animated: true, completion: nil)
        }
    }
    
    
    private func createFiles() -> Bool {
        
        // initialize file handlers
        self.fileHandler.removeAll()
        self.fileURL.removeAll()
        
        // create ARKit result text file
        let header = "Created at \(timeToString())"
        var url = URL(fileURLWithPath: NSTemporaryDirectory())
        url.appendPathComponent(fileName)
        self.fileURL.append(url)
        
        // delete previous text file
        if (FileManager.default.fileExists(atPath: url.path)) {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                os_log("cannot remove previous file", log:.default, type:.error)
                return false
            }
        }
        
        // create new text file
        if (!FileManager.default.createFile(atPath: url.path, contents: header.data(using: String.Encoding.utf8), attributes: nil)) {
            self.errorMsg(msg: "cannot create file \(self.fileName)")
            return false
        }
        
        // assign new file handler
        let fileHandle: FileHandle? = FileHandle(forWritingAtPath: url.path)
        if let handle = fileHandle {
            self.fileHandler.append(handle)
        } else {
            return false
        }
        
        // return true if everything is alright
        return true
    }
}
