//
//  ViewController.swift
//  Test_AVFoundation
//
//  Created by 스냅태그 on 2023/07/06.
//

import UIKit
import SnapKit
import AVFoundation

class ViewController: UIViewController {
    
    //MARK: - Declaration
    private var session = AVCaptureSession()
    private var captureBackDevice: AVCaptureDevice?
    private var captureFrontDevice: AVCaptureDevice?
    private var captureDevice: AVCaptureDevice?
    private var videoInput: AVCaptureDeviceInput?
    private var photoOutput = AVCapturePhotoOutput()
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private var isTorch: Bool = false
    private var isBack: Bool = true
    private var isDefaultLens: Bool!
    
    //MARK: - UI Component
    private var cameraView: CameraView!
    
    private var lensButton: UIButton!
    
    //MARK: - View Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        settingCamera()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        addCameraView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        view.subviews.forEach { subview in
            subview.removeFromSuperview()
        }
    }
}

extension ViewController {
    
    //MARK: - Add View
    func addCameraView() {
        cameraView = CameraView(cameraMode: .camera, isDefaultLens: isDefaultLens)
        
        self.view.addSubview(cameraView)
        
        cameraView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

}

extension ViewController {
    //MARK: - Function
    func settingCamera() {
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(doPinch(_:)))
        self.view.addGestureRecognizer(pinch)
        
        do {
            captureBackDevice = bestDevice(in: .back)
            captureFrontDevice = bestDevice(in: .front)
            
            captureDevice = (isBack) ? captureBackDevice : captureFrontDevice
            videoInput = try AVCaptureDeviceInput(device: captureDevice!)
            
            if session.canAddInput(videoInput!) && session.canAddOutput(photoOutput) {
                session.addInput(videoInput!)
                session.addOutput(photoOutput)
                
                let previewLayer = AVCaptureVideoPreviewLayer(session: session)
                
                previewLayer.frame = view.bounds
                previewLayer.videoGravity = .resizeAspect
                
                if captureBackDevice?.deviceType != .builtInWideAngleCamera {
                    try captureBackDevice?.lockForConfiguration()
                    captureBackDevice?.videoZoomFactor = 2.0
                    isDefaultLens = false
                } else {
                    isDefaultLens = true
                }
                
                
                view.layer.addSublayer(previewLayer)
                
                DispatchQueue.global(qos: .userInitiated).async {
                    self.session.startRunning()
                }
            }
        } catch {
            print("Error setting up camera: \(error.localizedDescription)")
        }
    }

    
    //MARK: - Selector
    @objc func tapCamera(_ sender: UIButton) {
        do {
            session.removeInput(videoInput!)
            captureDevice = (isBack) ? captureFrontDevice : captureBackDevice
            videoInput = try AVCaptureDeviceInput(device: captureDevice!)
            
            session.addInput(videoInput!)
            
            isBack.toggle()
            cameraView.torchButton.isHidden.toggle()
            cameraView.noZoomButton.isHidden.toggle()
            cameraView.doubleZoomButton.isHidden.toggle()
        } catch {
            print("Error setting up camera: \(error.localizedDescription)")
        }
        self.isTorch = false
        self.cameraView.torchButton.setImage(UIImage(systemName:"bolt.fill"), for: .normal)
    }
    
    @objc func tapTorch(_ sender: UIButton) {
        guard let captureDevice = captureDevice else { return }
        
        do {
            try captureDevice.lockForConfiguration()
            (isTorch) ? (captureDevice.torchMode = .off): (captureDevice.torchMode = .on)
            isTorch.toggle()
        } catch {
            return
        }
        captureDevice.unlockForConfiguration()
        sender.setImage(UIImage(systemName: (isTorch) ? "bolt.slash.fill" : "bolt.fill"), for: .normal)
    }
    
    @objc func tapNoZoom(_ sender: UIButton) {
        guard let captureDevice = captureDevice else { return }
        
        
        do {
            try captureDevice.lockForConfiguration()
            captureDevice.ramp(toVideoZoomFactor: 1.0, withRate: 2.0)
        } catch {
            return
        }
        captureDevice.unlockForConfiguration()
    }
    
    @objc func tapDoubleZoom(_ sender: UIButton) {
        guard let captureDevice = captureDevice else { return }
        
        
        do {
            try captureDevice.lockForConfiguration()
            captureDevice.ramp(toVideoZoomFactor: 2.0, withRate: 2.0)
        } catch {
            return
        }
        captureDevice.unlockForConfiguration()
    }
    
    @objc func tapShutter(_ sender: UIButton) {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    @objc func tapVideo(_ sender: UIButton) {
        let videoVC = VideoViewController()
        videoVC.modalPresentationStyle = .fullScreen
        self.present(videoVC, animated: true)
    }
    
    @objc func doPinch(_ pinch: UIPinchGestureRecognizer) {
        guard let captureDevice = captureDevice else { return }
        var initialScale: CGFloat = captureDevice.videoZoomFactor
        
        let minAvailableZoomScale = captureDevice.minAvailableVideoZoomFactor
        let maxAvailableZoomScale = 6.0
        
        do {
            try captureDevice.lockForConfiguration()
            if (pinch.state == UIPinchGestureRecognizer.State.began) {
                initialScale = captureDevice.videoZoomFactor
            }
            else {
                if (initialScale * (pinch.scale) < minAvailableZoomScale) {
                    captureDevice.videoZoomFactor = minAvailableZoomScale
                }
                else if (initialScale * (pinch.scale) > maxAvailableZoomScale) {
                    captureDevice.videoZoomFactor = maxAvailableZoomScale
                }
                else {
                    captureDevice.videoZoomFactor = initialScale * (pinch.scale)
                }
            }
            pinch.scale = 1.0
        } catch {
            return
        }
        captureDevice.unlockForConfiguration()
    }
}

extension ViewController: AVCapturePhotoCaptureDelegate {
    
    //MARK: - Delegate
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        // globalQueue 에서 Session stop
        DispatchQueue.global().async {
            self.session.stopRunning()
        }
        
        guard let imageData = photo.fileDataRepresentation() else { return }
        
        let capturedImage = UIImage(data: imageData)
        
        let preView = CapturedViewController(capturedImage: capturedImage!, session: session)
        preView.modalPresentationStyle = .fullScreen
        self.present(preView, animated: true)
        self.isTorch = false
        self.cameraView.torchButton.setImage(UIImage(systemName:"bolt.fill"), for: .normal)
    }
}
