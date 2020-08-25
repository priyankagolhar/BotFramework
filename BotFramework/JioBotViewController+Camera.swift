//
//  JioBotViewController+Camera.swift
//  JioBots
//
//  Created by Supreem Mishra on 16/01/20.
//  Copyright © 2020 RelianceJIO. All rights reserved.
//

import Foundation
import AVFoundation
import CoreImage
import UIKit

// AVCaptureVideoDataOutputSampleBufferDelegate protocol and related methods
extension JioBotViewController:  AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func setupAVCapture(){
        session.sessionPreset = AVCaptureSession.Preset.vga640x480
        guard let device = AVCaptureDevice
            .default(AVCaptureDevice.DeviceType.builtInWideAngleCamera,
                     for: .video,
                     position: AVCaptureDevice.Position.front) else {
                        return
        }
        captureDevice = device
        beginSession()
    }
    
    func beginSession(){
        var deviceInput: AVCaptureDeviceInput!
        
        do {
            deviceInput = try AVCaptureDeviceInput(device: captureDevice)
            guard deviceInput != nil else {
                print("error: cant get deviceInput")
                return
            }
            
            if self.session.canAddInput(deviceInput){
                self.session.addInput(deviceInput)
            }
            
            videoDataOutput = AVCaptureVideoDataOutput()
            videoDataOutput.alwaysDiscardsLateVideoFrames=true
            videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue")
            videoDataOutput.setSampleBufferDelegate(self, queue:self.videoDataOutputQueue)
            
            if session.canAddOutput(self.videoDataOutput){
                session.addOutput(self.videoDataOutput)
            }
            
            videoDataOutput.connection(with: .video)?.isEnabled = true
            
            previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
            previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
            
            let rootLayer :CALayer = self.cameraPreview.layer
            rootLayer.masksToBounds=true
            previewLayer.frame = rootLayer.bounds
            videoInitialFrame = previewLayer.frame
            rootLayer.addSublayer(self.previewLayer)
            session.startRunning()
        } catch let error as NSError {
            deviceInput = nil
            print("error: \(error.localizedDescription)")
        }
    }
    
   public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // do stuff here
        //let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        //print("sampleBuffer->",pixelBuffer)
        //self.didRecognizeCamera(cameraBuffer: sampleBuffer)
        imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
    }
    
    // clean up AVCapture
    func stopImageCapture() {
        let modelName = UIDevice.current.modelName
         if modelName == "iPhone 11" {
        videoInitialFrame?.origin.y = 65
        }
        self.previewLayer.frame = videoInitialFrame ?? CGRect(x: 0, y: 0, width: 0, height: 0)
        if let buffer = imageBuffer {
            let ciimage : CIImage = CIImage(cvPixelBuffer: buffer)
            let image : UIImage? = self.convert(cmage: ciimage)
            if let  capturedImage = image {
                //capturedImageview.image = UIImage.init(cgImage: capturedImage.cgImage!, scale: capturedImage.scale, orientation: .leftMirrored)
                let data = capturedImage.pngData()
                let stringData = data!.base64EncodedString(options: NSData.Base64EncodingOptions())
                self.didRecognizeCamera(cameraBuffer: stringData)
            }
        }
        //session.stopRunning()
    }
    
    func startImageCapture() {
        if presentedViewCount == 0 {
            presentedViewCount = presentedViewCount + 1
        }
        UIView.animate(withDuration: 0.5, animations: {
        let modelName = UIDevice.current.modelName
        self.cameraPreviewHeightConstraint.constant = self.view.frame.height - 200
            self.cameraPreviewWidthConstraint.constant = self.view.frame.width
            if modelName == self.iphone11 {
            self.cameraPreview.frame.origin.y = -6.0
            self.cameraPreview.frame.origin.x = 0.0
        }
            
//            let rootLayer :CALayer = self.cameraPreview.layer
//            rootLayer.masksToBounds=true
//            self.previewLayer.frame = rootLayer.bounds
//            self.view.layoutIfNeeded()
            if Platform.isSimulator {

                return

            }else{

                let rootLayer :CALayer = self.cameraPreview.layer

                rootLayer.masksToBounds=true

                self.previewLayer.frame = rootLayer.bounds

                self.view.layoutIfNeeded()

            }
            
        })
    }
    
        

    struct Platform {

            static let isSimulator: Bool = {

                var isSim = false

                #if arch(i386) || arch(x86_64)

                    isSim = true

                #endif

                return isSim

            }()

        }


    func checkImageCapture() {
        self.cameraPreview.frame = videoInitialFrame ?? CGRect(x: 0, y: 0, width: 0, height: 0)
        
    }
    
    
    
    // Convert CIImage to CGImage
    func convert(cmage:CIImage) -> UIImage
    {
        let context:CIContext = CIContext.init(options: nil)
        let cgImage:CGImage = context.createCGImage(cmage, from: cmage.extent)!
        let image:UIImage = UIImage.init(cgImage: cgImage)
        return image
    }
}
