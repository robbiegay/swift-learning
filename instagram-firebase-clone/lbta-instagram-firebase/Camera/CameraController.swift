//
//  CameraController.swift
//  lbta-instagram-firebase
//
//  Created by Robbie Gay on 4/13/20.
//  Copyright © 2020 robbiegay. All rights reserved.
//

import UIKit
import AVFoundation

class CameraController: UIViewController, AVCapturePhotoCaptureDelegate, UIViewControllerTransitioningDelegate {
    
    let captureButton: UIButton = {
        let  button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "capture_photo").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleCapturePhoto), for: .touchUpInside)
        return button
    }()
    
    let dismissButton: UIButton = {
        let  button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "arrow.right"), for: .normal)
        button.addTarget(self, action: #selector(handleDismiss), for: .touchUpInside)
        button.tintColor = .white
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        transitioningDelegate = self
        
        setupCaptureSession()
        setupHUD()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    let customAnimationPreseneter = CustomAnimationPresenter()
    let customAnimationDismisser = CustomAnimationDismisser()
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        return customAnimationPreseneter
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return customAnimationDismisser
    }
    
    fileprivate func setupHUD() {
        view.addSubview(captureButton)
        captureButton.anchor(top: nil, left: nil, bottom: view.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 24, paddingRight: 0, width: 80, height: 80)
        captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        view.addSubview(dismissButton)
        dismissButton.anchor(top: view.topAnchor, left: nil, bottom: nil, right: view.rightAnchor, paddingTop: 12, paddingLeft: 0, paddingBottom: 0, paddingRight: 12, width: 50, height: 50)
    }
    
    @objc func handleCapturePhoto() {
        print("Capturing photo...")
        
        let settings = AVCapturePhotoSettings()
        
        guard let previewFormatType = settings.availablePreviewPhotoPixelFormatTypes.first else { return }
        
        settings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewFormatType]
                
        output.capturePhoto(with: settings, delegate: self)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        
        var data: Data?
        
        // Attempt to fix outdate JPEG Representation function
//        if #available(iOS 11.0, *) {
//            func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
//                    data = photo.fileDataRepresentation()
//            }
//        } else {
            data = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer!, previewPhotoSampleBuffer: previewPhotoSampleBuffer!)
//        }
        
        // Alerts the user if the camera fails to capture a photo
        guard let unwrappedData = data else {
            let alert = UIAlertController(title: "Failed to capture photo", message: "Please try again later.", preferredStyle: .alert)

            alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))

            self.present(alert, animated: true)
            return
        }
        
        let previewImage = UIImage(data: unwrappedData)
        
        let containerView = PreviewPhotoContainerView()
        containerView.previewImageView.image = previewImage

        view.addSubview(containerView)
        containerView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
    }
    
    @objc func handleDismiss() {
        dismiss(animated: true, completion: nil)
    }
    
    let output = AVCapturePhotoOutput()

    fileprivate func setupCaptureSession() {
        let captureSession = AVCaptureSession()
        
        // 1. Setup Inputs
        guard let captureDevice = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
        } catch let err {
            print("Could not setup camera input:",err)
        }
        
        // 2. Setup Outputs
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
        }
        
        // 3. Setup Output Preview
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.frame
        
        // Shows us the camera preview
        view.layer.addSublayer(previewLayer)
        
        // Start the session
        captureSession.startRunning()
    }
}
