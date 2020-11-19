//
//  QRScannerVC.swift
//  Aulae
//
//  Created by Tim Sandgren on 2019-11-08.
//  Copyright © 2019 Tim Sandgren. All rights reserved.
//

import Foundation
import Vision
import AVFoundation
import UIKit
import ARKit


class QRScannerVC: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    //var isTrackingQR = false
    var qrUrl = ""
    
    var qrCapturePreviewLayer: AVCaptureVideoPreviewLayer? = nil
    var qrCaptureSession: AVCaptureSession? = nil
    
    @IBAction func closeBtnAction(_ sender: UIBarButtonItem) {
    
        DispatchQueue.global(qos: .default).async {
            [weak self] in

            DispatchQueue.main.sync {
                if ((self!.qrCaptureSession) != nil){
                    self?.qrCaptureSession!.stopRunning()
                }
            }

            DispatchQueue.main.async {
                if ((self!.qrCapturePreviewLayer) != nil) {
                    self?.qrCapturePreviewLayer?.removeFromSuperlayer()
                    self?.qrCapturePreviewLayer = nil
                }
            }
        }

        qrCaptureSession?.stopRunning()
        qrCapturePreviewLayer?.removeFromSuperlayer()
        //qrCapturePreviewLayer = nil
        
        UIOps().updateNavUiMode(navCtrl: self.navigationController!)
        self.navigationController?.dismiss( animated: true, completion: { super.viewDidAppear(true)} )
        self.view.removeFromSuperview()
        
    }
    
    
    func handleEnterURL(alertView: UIAlertAction!) {
        print("Adding QRURL: " + qrUrl)
        FeedActions().addNewSource(feedUrl: qrUrl, feedApiKwd: "", refreshExisting: true)
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
    }
    
    
    func showQRURLAlert(aMessage: String) {
        let alert = UIAlertController(
            title: aMessage,
            message: nil,
            preferredStyle: UIAlertController.Style.alert
        )
        
        qrUrl = aMessage
        
        alert.addAction(UIAlertAction(title: "Cancel",     style: UIAlertAction.Style.cancel,  handler: nil))
        alert.addAction(UIAlertAction(title: "Add to Lib", style: UIAlertAction.Style.default, handler: handleEnterURL))
        alert.addAction(UIAlertAction(title: "Open Link",  style: UIAlertAction.Style.default, handler: {_ in self.openQRUrl(scheme: self.qrUrl)} ))
        
        if traitCollection.userInterfaceStyle == .light {
            alert.view.tintColor = UIColor.black
        } else {
            alert.view.tintColor = UIColor.white
        }
        
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
                }
                
                if metadataObject.type == AVMetadataObject.ObjectType.upce {
                    print(AVMetadataObject.ObjectType.upce)
                }
            }
        }
    }
    
    
    func captureQRCode() {
        print("captureQRCode")
        view.backgroundColor = UIColor.black
        qrCaptureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if (qrCaptureSession!.canAddInput(videoInput)) {
            qrCaptureSession!.addInput(videoInput)
        } else {
            failed()
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if (qrCaptureSession!.canAddOutput(metadataOutput)) {
            qrCaptureSession!.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
            return
        }

        qrCapturePreviewLayer = AVCaptureVideoPreviewLayer(session: qrCaptureSession!)
        qrCapturePreviewLayer!.frame = view.layer.bounds
        qrCapturePreviewLayer!.videoGravity = .resizeAspectFill
        view.layer.addSublayer(qrCapturePreviewLayer!)

        qrCaptureSession!.startRunning()
    }    
    
    
    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        qrCaptureSession = nil
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        captureQRCode()
    }
    

}
