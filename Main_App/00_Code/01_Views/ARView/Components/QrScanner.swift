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
        FeedActions().addNewSource(feedUrl: qrUrl, feedApiKwd: "", refreshExisting: true)
        qrCaptureSession?.stopRunning()
        qrCapturePreviewLayer?.removeFromSuperlayer()
        
        //searchQRBtn.tintColor = self.view.window?.tintColor
    }
    
    
    func cancelHandler(alertView: UIAlertAction!) {
        qrCaptureSession?.stopRunning()
        qrCapturePreviewLayer?.removeFromSuperlayer()
        
        qrCapturePreviewLayer = nil
        qrCaptureSession = nil
        //searchQRBtn.tintColor = self.view.window?.tintColor
    }
    
    
    func openQRUrl(scheme: String) {
        if let url = URL(string: scheme) {
            if #available(iOS 10, *) {
                UIApplication.shared.open(
                    url, options: [:], completionHandler: { (success) in print("Open \(scheme): \(success)")
                })
            } else {
                let success = UIApplication.shared.openURL(url)
                print("Open \(scheme): \(success)")
            }
        }
        
        qrCaptureSession?.stopRunning()
        qrCapturePreviewLayer?.removeFromSuperlayer()
        
        qrCapturePreviewLayer = nil
        qrCaptureSession = nil
        //searchQRBtn.tintColor = self.view.window?.tintColor
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
        alert.addAction(UIAlertAction(title: "Open Link",  style: UIAlertAction.Style.default, handler: {_ in self.openQRUrl(scheme: self.qrUrl)} ))
        
        alert.view.tintColor = UIColor.black
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        for item in metadataObjects {
            if let metadataObject = item as? AVMetadataMachineReadableCodeObject {
                
                if metadataObject.type == AVMetadataObject.ObjectType.qr {
                    qrUrl = metadataObject.stringValue!
                    
                    if (qrUrl != "") {
                        print(metadataObject.stringValue!)
                        showQRURLAlert(aMessage: metadataObject.stringValue!)
                    }
                    
                    //loadingView.isHidden = true
                    loadingView.layer.opacity = 1
                    qrCaptureSession?.stopRunning()
                    qrCapturePreviewLayer?.removeFromSuperlayer()
                    
                    qrCapturePreviewLayer = nil
                    qrCaptureSession = nil
                }
                
                if metadataObject.type == AVMetadataObject.ObjectType.upce {
                    print(AVMetadataObject.ObjectType.upce)
                }
            }
        }
    }
    
    
    func captureQRCode() {
        isTrackingQR = true

        // TODO: Add if Image?
        self.view.isHidden = true

        qrCaptureSession?.stopRunning()
        qrCaptureSession = AVCaptureSession()
        
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        //let device = AVCaptureDevice.default(for: AVMediaType.video)

        do {
            let input = try AVCaptureDeviceInput(device: device)
            qrCaptureSession?.addInput(input)
        } catch (let writeError) {
            print(writeError)
        }
        
        let output = AVCaptureMetadataOutput()
        output.setMetadataObjectsDelegate((self as AVCaptureMetadataOutputObjectsDelegate),
                                          queue: DispatchQueue.main)
        qrCaptureSession?.addOutput(output)
        output.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
        
        qrCapturePreviewLayer = AVCaptureVideoPreviewLayer(session: qrCaptureSession!)
        let bounds = self.view.layer.bounds
        qrCapturePreviewLayer!.videoGravity = AVLayerVideoGravity.resizeAspectFill
        qrCapturePreviewLayer!.bounds = bounds
                
        qrCapturePreviewLayer!.position = CGPoint(x: bounds.midX, y: bounds.midY)
        self.view.layer.addSublayer(qrCapturePreviewLayer!)
        
        ViewAnimation().fade(viewToAnimate: self.view, aDuration: 1, hideView: false, aMode: .curveEaseIn)
        
        qrCaptureSession!.startRunning()
    }    
    
}
