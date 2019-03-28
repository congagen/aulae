//
//  QrScanner.swift
//  Aulae
//
//  Created by Tim Sandgren on 2019-03-09.
//  Copyright © 2019 Abstraqata. All rights reserved.
//

import Foundation
import Vision
import AVFoundation

import ARKit


extension ARViewer {
    
    
    func handleEnterURL(alertView: UIAlertAction!) {
        print("Adding QRURL: " + qrUrl)
        FeedActions().addFeedUrl(feedUrl: qrUrl, refreshExisting: true)
        qrCaptureSession.stopRunning()
        qrCapturePreviewLayer.removeFromSuperlayer()
        
        searchQRBtn.tintColor = self.view.window?.tintColor
    }
    
    
    func cancelHandler(alertView: UIAlertAction!) {
        qrCaptureSession.stopRunning()
        qrCapturePreviewLayer.removeFromSuperlayer()
        
        searchQRBtn.tintColor = self.view.window?.tintColor
    }
    
    
    func showQRURLAlert(aMessage: String) {
        let alert = UIAlertController(
            title: aMessage,
            message: nil,
            preferredStyle: UIAlertController.Style.alert
        )
        
        qrUrl = aMessage
        
        alert.addAction(UIAlertAction(title: "Cancel",     style: UIAlertAction.Style.cancel,  handler: cancelHandler))
        alert.addAction(UIAlertAction(title: "Add to Lib", style: UIAlertAction.Style.default, handler: handleEnterURL))
        alert.addAction(UIAlertAction(title: "Open Link",  style: UIAlertAction.Style.default, handler: {_ in self.openUrl(scheme: self.qrUrl)} ))
        
        alert.view.tintColor = UIColor.black
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func captureQRCode() {
        
        // TODO: Add if Image?
    
        qrCaptureSession.stopRunning()
        qrCaptureSession = AVCaptureSession()
        
        let device = AVCaptureDevice.default(for: AVMediaType.video)

        do {
            let input = try AVCaptureDeviceInput(device: device!)
            qrCaptureSession.addInput(input)
        } catch (let writeError) {
            print(writeError)
        }
        
        let output = AVCaptureMetadataOutput()
        output.setMetadataObjectsDelegate((self as AVCaptureMetadataOutputObjectsDelegate), queue: DispatchQueue.main)
        qrCaptureSession.addOutput(output)
        output.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
        
        qrCapturePreviewLayer = AVCaptureVideoPreviewLayer(session: qrCaptureSession)
        let bounds = self.view.layer.bounds
        qrCapturePreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        qrCapturePreviewLayer.bounds = bounds
        /////////////////////qrCapturePreviewLayer.position = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds))
        qrCapturePreviewLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        
        self.view.layer.addSublayer(qrCapturePreviewLayer)
        qrCaptureSession.startRunning()
    }    
    
}
