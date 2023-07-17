//
//  VideoViewController.swift
//  Test_AVFoundation
//
//  Created by 스냅태그 on 2023/07/10.
//

import UIKit
import SnapKit
import AVFoundation

class VideoViewController: UIViewController {
    
    //MARK: - Declaration
    private var session = AVCaptureSession()
    private var captureBackDevice: AVCaptureDevice?
    private var captureFrontDevice: AVCaptureDevice?
    private var captureDevice: AVCaptureDevice?
    private var videoInput: AVCaptureDeviceInput?
    private var videoOutput = AVCaptureVideoDataOutput()
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private var lastFrame: CMSampleBuffer?
    private var isTorch: Bool = false
    private var isBack: Bool = true
    private var isDefaultLens: Bool!
    
    //MARK: - UI Component
    private var cameraView: CameraView!
    
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

extension VideoViewController {
    
    //MARK: - Add View
    func addCameraView() {
        cameraView = CameraView(cameraMode: .video, isDefaultLens: self.isDefaultLens)
        
        self.view.addSubview(cameraView)
        
        cameraView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}

extension VideoViewController {
    
    //MARK: - Function
    func settingCamera() {

        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(doPinch(_:)))
        self.view.addGestureRecognizer(pinch)
        
        do {
            captureBackDevice = bestDevice(in: .back)
            captureFrontDevice = bestDevice(in: .front)
            
            captureDevice = (isBack) ? captureBackDevice : captureFrontDevice
            
            videoInput = try AVCaptureDeviceInput(device: captureDevice!)
            
            if session.canAddInput(videoInput!) && session.canAddOutput(videoOutput) {
                session.addInput(videoInput!)
                session.addOutput(videoOutput)
                
                let previewLayer = AVCaptureVideoPreviewLayer(session: session)
                previewLayer.frame = view.bounds
                previewLayer.videoGravity = .resizeAspectFill
                
                if captureBackDevice?.deviceType != .builtInWideAngleCamera {
                    try captureBackDevice?.lockForConfiguration()
                    captureBackDevice?.videoZoomFactor = 2.0
                    isDefaultLens = false
                } else {
                    isDefaultLens = true
                }
                
                view.layer.addSublayer(previewLayer)
                videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
                
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
    
    @objc func tapPhoto(_ sender: UIButton) {
        self.dismiss(animated: true)
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }
    
    @objc func tapShutter(_ sender: UIButton) {
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let lastFrame = self.lastFrame,
               let pixelBuffer = CMSampleBufferGetImageBuffer(lastFrame),
               let capturedImage = convertCIImageToUIImage(ciImage: CIImage(cvPixelBuffer: pixelBuffer)) {
                DispatchQueue.main.async {
                    let preViewController = PreViewController(capturedImage: capturedImage, session: self.session)
                    preViewController.modalPresentationStyle = .fullScreen
                    self.present(preViewController, animated: true)
                }
            }
        }
        self.session.stopRunning()
        self.isTorch = false
        self.cameraView.torchButton.setImage(UIImage(systemName:"bolt.fill"), for: .normal)
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

extension VideoViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    //MARK: - Delegate
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        lastFrame = sampleBuffer
    }
}
