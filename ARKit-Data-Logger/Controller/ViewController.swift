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
import Accelerate


class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
    // cellphone screen UI outlet objects
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet weak var numberOfFeatureLabel: UILabel!
    @IBOutlet weak var trackingStatusLabel: UILabel!
    @IBOutlet weak var worldMappingStatusLabel: UILabel!
    @IBOutlet weak var updateRateLabel: UILabel!
    
    // constants for collecting data
    let numTextFiles = 2
    let ARKIT_CAMERA_POSE = 0
    let ARKIT_POINT_CLOUD = 1
    var isRecording: Bool = false
    let customQueue: DispatchQueue = DispatchQueue(label: "pyojinkim.me")
    var accumulatedPointCloud = AccumulatedPointCloud()
    
    
    // variables for measuring time in iOS clock
    var recordingTimer: Timer = Timer()
    var secondCounter: Int64 = 0 {
        didSet {
            statusLabel.text = interfaceIntTime(second: secondCounter)
        }
    }
    var previousTimestamp: Double = 0
    let mulSecondToNanoSecond: Double = 1000000000
    
    
    // text file input & output
    var fileHandlers = [FileHandle]()
    var fileURLs = [URL]()
    var fileNames: [String] = ["ARKit_camera_pose.txt", "ARKit_point_cloud.txt"]
    
    
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
                
                // save ARKit 3D point cloud only for visualization
                for i in 0...(self.accumulatedPointCloud.count - 1) {
                    let ARKitPointData = String(format: "%.6f %.6f %.6f %d %d %d \n",
                                                self.accumulatedPointCloud.points[i].x,
                                                self.accumulatedPointCloud.points[i].y,
                                                self.accumulatedPointCloud.points[i].z,
                                                self.accumulatedPointCloud.colors[i].x,
                                                self.accumulatedPointCloud.colors[i].y,
                                                self.accumulatedPointCloud.colors[i].z)
                    if let ARKitPointDataToWrite = ARKitPointData.data(using: .utf8) {
                        self.fileHandlers[self.ARKIT_POINT_CLOUD].write(ARKitPointDataToWrite)
                    } else {
                        os_log("Failed to write data record", log: OSLog.default, type: .fault)
                    }
                }
                
                // close the file handlers
                if (self.fileHandlers.count == self.numTextFiles) {
                    for handler in self.fileHandlers {
                        handler.closeFile()
                    }
                    DispatchQueue.main.async {
                        let activityVC = UIActivityViewController(activityItems: self.fileURLs, applicationActivities: nil)
                        self.present(activityVC, animated: true, completion: nil)
                    }
                }
            }
            
            // initialize UI on the screen
            self.numberOfFeatureLabel.text = ""
            self.trackingStatusLabel.text = ""
            self.worldMappingStatusLabel.text = ""
            self.updateRateLabel.text = ""
            
            self.startStopButton.setTitle("Start", for: .normal)
            self.statusLabel.text = "Ready"
            
            // resume screen lock
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
    
    
    // define if ARSession is didUpdate (callback function)
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
        // obtain current transformation 4x4 matrix
        let timestamp = frame.timestamp * self.mulSecondToNanoSecond
        let updateRate = self.mulSecondToNanoSecond / Double(timestamp - previousTimestamp)
        previousTimestamp = timestamp
        
        let imageFrame = frame.capturedImage
        let imageResolution = frame.camera.imageResolution
        let K = frame.camera.intrinsics
        
        let ARKitWorldMappingStatus = frame.worldMappingStatus.rawValue
        let ARKitTrackingState = frame.camera.trackingState
        let T_gc = frame.camera.transform
        
        let r_11 = T_gc.columns.0.x
        let r_12 = T_gc.columns.1.x
        let r_13 = T_gc.columns.2.x
        
        let r_21 = T_gc.columns.0.y
        let r_22 = T_gc.columns.1.y
        let r_23 = T_gc.columns.2.y
        
        let r_31 = T_gc.columns.0.z
        let r_32 = T_gc.columns.1.z
        let r_33 = T_gc.columns.2.z
        
        let t_x = T_gc.columns.3.x
        let t_y = T_gc.columns.3.y
        let t_z = T_gc.columns.3.z
        
        // dispatch queue to display UI
        DispatchQueue.main.async {
            self.numberOfFeatureLabel.text = String(format:"%05d", self.accumulatedPointCloud.count)
            self.trackingStatusLabel.text = "\(ARKitTrackingState)"
            self.updateRateLabel.text = String(format:"%.3f Hz", updateRate)
            
            var worldMappingStatus = ""
            switch ARKitWorldMappingStatus {
            case 0:
                worldMappingStatus = "notAvailable"
            case 1:
                worldMappingStatus = "limited"
            case 2:
                worldMappingStatus = "extending"
            case 3:
                worldMappingStatus = "mapped"
            default:
                worldMappingStatus = "switch default?"
            }
            self.worldMappingStatusLabel.text = "\(worldMappingStatus)"
        }
        
        // custom queue to save ARKit processing data
        self.customQueue.async {
            if ((self.fileHandlers.count == self.numTextFiles) && self.isRecording) {
                
                // 1) record ARKit 6-DoF camera pose
                let ARKitPoseData = String(format: "%.0f %.6f %.6f %.6f %.6f %.6f %.6f %.6f %.6f %.6f %.6f %.6f %.6f \n",
                                           timestamp,
                                           r_11, r_12, r_13, t_x,
                                           r_21, r_22, r_23, t_y,
                                           r_31, r_32, r_33, t_z)
                if let ARKitPoseDataToWrite = ARKitPoseData.data(using: .utf8) {
                    self.fileHandlers[self.ARKIT_CAMERA_POSE].write(ARKitPoseDataToWrite)
                } else {
                    os_log("Failed to write data record", log: OSLog.default, type: .fault)
                }
                
                // 2) record ARKit 3D point cloud only for visualization
                if let rawFeaturePointsArray = frame.rawFeaturePoints {
                    
                    // constants for feature points
                    let points = rawFeaturePointsArray.points
                    let identifiers = rawFeaturePointsArray.identifiers
                    let pointsCount = points.count
                    
                    let kDownscaleFactor: CGFloat = 16.0
                    let scale = Double(1 / kDownscaleFactor)
                    
                    var projectedPoints = [CGPoint]()
                    var validPoints = [vector_float3]()
                    var validIdentifiers = [UInt64]()
                    
                    
                    // project all feature points into image 2D coordinate
                    for i in 0...(pointsCount - 1) {
                        let projectedPoint = frame.camera.projectPoint(points[i], orientation: .landscapeRight, viewportSize: imageResolution)
                        if ((projectedPoint.x >= 0 && projectedPoint.x <= imageResolution.width - 1) &&
                            (projectedPoint.y >= 0 && projectedPoint.y <= imageResolution.height - 1)) {
                            projectedPoints.append(projectedPoint)
                            validPoints.append(points[i])
                            validIdentifiers.append(identifiers[i])
                        }
                    }
                    
                    
                    // compute scaled YCbCr image buffer
                    let scaledBuffer = self.IBASampleScaledCapturedPixelBuffer(imageFrame: imageFrame, scale: scale)
                    let scaledLumaBuffer = scaledBuffer.0
                    let scaledCbcrBuffer = scaledBuffer.1
                    
                    
                    // perform YCbCr image sampling
                    for i in 0...(projectedPoints.count - 1) {
                        let projectedPoint = projectedPoints[i]
                        let lumaPoint = CGPoint(x: Double(projectedPoint.x) * scale, y: Double(projectedPoint.y) * scale)
                        let cbcrPoint = CGPoint(x: Double(projectedPoint.x) * scale, y: Double(projectedPoint.y) * scale)
                        
                        let lumaPixelAddress = scaledLumaBuffer.data + scaledLumaBuffer.rowBytes * Int(lumaPoint.y) + Int(lumaPoint.x)
                        let cbcrPixelAddress = scaledCbcrBuffer.data + scaledCbcrBuffer.rowBytes * Int(cbcrPoint.y) + Int(cbcrPoint.x) * 2;
                        
                        let luma = lumaPixelAddress.load(as: UInt8.self)
                        let cb = cbcrPixelAddress.load(as: UInt8.self)
                        let cr = (cbcrPixelAddress + 1).load(as: UInt8.self)
                        
                        let color = simd_make_uint3(UInt32(luma), UInt32(cb), UInt32(cr))
                        self.accumulatedPointCloud.appendPointCloud(validPoints[i], validIdentifiers[i], color)
                    }
                }
            }
        }
    }
    
    
    // some useful functions
    private func errorMsg(msg: String) {
        DispatchQueue.main.async {
            let fileAlert = UIAlertController(title: "ARKit-Data-Logger", message: msg, preferredStyle: .alert)
            fileAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(fileAlert, animated: true, completion: nil)
        }
    }
    
    
    private func createFiles() -> Bool {
        
        // initialize file handlers
        self.fileHandlers.removeAll()
        self.fileURLs.removeAll()
        
        // create ARKit result text files
        let startHeader = ""
        for i in 0...(self.numTextFiles - 1) {
            var url = URL(fileURLWithPath: NSTemporaryDirectory())
            url.appendPathComponent(fileNames[i])
            self.fileURLs.append(url)
            
            // delete previous text files
            if (FileManager.default.fileExists(atPath: url.path)) {
                do {
                    try FileManager.default.removeItem(at: url)
                } catch {
                    os_log("cannot remove previous file", log:.default, type:.error)
                    return false
                }
            }
            
            // create new text files
            if (!FileManager.default.createFile(atPath: url.path, contents: startHeader.data(using: String.Encoding.utf8), attributes: nil)) {
                self.errorMsg(msg: "cannot create file \(self.fileNames[i])")
                return false
            }
            
            // assign new file handlers
            let fileHandle: FileHandle? = FileHandle(forWritingAtPath: url.path)
            if let handle = fileHandle {
                self.fileHandlers.append(handle)
            } else {
                return false
            }
        }
        
        // write current recording time information
        let timeHeader = "# Created at \(timeToString()) in Burnaby Canada \n"
        for i in 0...(self.numTextFiles - 1) {
            if let timeHeaderToWrite = timeHeader.data(using: .utf8) {
                self.fileHandlers[i].write(timeHeaderToWrite)
            } else {
                os_log("Failed to write data record", log: OSLog.default, type: .fault)
                return false
            }
        }
        
        // return true if everything is alright
        return true
    }
    
    
    private func IBAPixelBufferGetPlanarBuffer(pixelBuffer: CVPixelBuffer, planeIndex: size_t) -> vImage_Buffer {
        
        // assumes that pixel buffer base address is already locked
        let baseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, planeIndex)
        let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, planeIndex)
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex)
        
        return vImage_Buffer(data: baseAddress, height: vImagePixelCount(height), width: vImagePixelCount(width), rowBytes: bytesPerRow)
    }
    
    
    private func IBASampleScaledCapturedPixelBuffer(imageFrame: CVPixelBuffer, scale: Double) -> (vImage_Buffer, vImage_Buffer) {
        
        // calculate scaled size for buffers
        let baseWidth = Double(CVPixelBufferGetWidth(imageFrame))
        let baseHeight = Double(CVPixelBufferGetHeight(imageFrame))
        
        let scaledWidth = vImagePixelCount(ceil(baseWidth * scale))
        let scaledHeight = vImagePixelCount(ceil(baseHeight * scale))
        
        
        // lock the source pixel buffer
        CVPixelBufferLockBaseAddress(imageFrame, CVPixelBufferLockFlags.readOnly)
        
        // allocate buffer for scaled Luma & retrieve address of source Luma and scale it
        var scaledLumaBuffer = vImage_Buffer()
        var sourceLumaBuffer = self.IBAPixelBufferGetPlanarBuffer(pixelBuffer: imageFrame, planeIndex: 0)
        vImageBuffer_Init(&scaledLumaBuffer, scaledHeight, scaledWidth, 8, vImage_Flags(kvImagePrintDiagnosticsToConsole))
        vImageScale_Planar8(&sourceLumaBuffer, &scaledLumaBuffer, nil, vImage_Flags(kvImagePrintDiagnosticsToConsole))
        
        // allocate buffer for scaled CbCr & retrieve address of source CbCr and scale it
        var scaledCbcrBuffer = vImage_Buffer()
        var sourceCbcrBuffer = self.IBAPixelBufferGetPlanarBuffer(pixelBuffer: imageFrame, planeIndex: 1)
        vImageBuffer_Init(&scaledCbcrBuffer, scaledHeight, scaledWidth, 8, vImage_Flags(kvImagePrintDiagnosticsToConsole))
        vImageScale_CbCr8(&sourceCbcrBuffer, &scaledCbcrBuffer, nil, vImage_Flags(kvImagePrintDiagnosticsToConsole))
        
        // unlock source buffer now
        CVPixelBufferUnlockBaseAddress(imageFrame, CVPixelBufferLockFlags.readOnly)
        
        
        // return the scaled Luma and CbCr buffer
        return (scaledLumaBuffer, scaledCbcrBuffer)
    }
}
