//
//  Action.swift
//  Test_AVFoundation
//
//  Created by 스냅태그 on 2023/07/17.
//

import AVFoundation
import UIKit

var captureBackDevice = bestDevice(in: .back)
var captureFrontDevice = bestDevice(in: .front)
var videoInput: AVCaptureDeviceInput!
var videoOutput = AVCaptureVideoDataOutput()
var captureDevice: AVCaptureDevice?

var isTorch: Bool = false
var isBack: Bool = true
var isDefaultLens: Bool = false

class Action: NSObject {
    
    var previewLayer: AVCaptureVideoPreviewLayer!
    var lastFrame: CMSampleBuffer?
    var session: AVCaptureSession?
    
    private var cameraView: CameraView!
    
    override init() {
        super.init()
        self.session = AVCaptureSession()
        self.previewLayer = AVCaptureVideoPreviewLayer()
        
        getLensStatus()
        settingCamera()
    }
    
    func getLensStatus() {
        do {
            if captureBackDevice.deviceType != .builtInWideAngleCamera {
                try captureBackDevice.lockForConfiguration()
                captureBackDevice.videoZoomFactor = 2.0
                isDefaultLens =  false
            } else {
                isDefaultLens = true
            }
        } catch {
            print("Error setting up camera: \(error.localizedDescription)")
        }
    }
    
    func settingCamera() {
        do {
            guard let session = session else { fatalError("session을 못받았음") }
            
            videoInput = try AVCaptureDeviceInput(device: (isBack) ? captureBackDevice : captureFrontDevice)
            
            if session.canAddInput(videoInput!) && session.canAddOutput(videoOutput) {
                session.addInput(videoInput!)
                session.addOutput(videoOutput)
                
                previewLayer = AVCaptureVideoPreviewLayer(session: session)
                
                videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
                videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
                
                self.session!.startRunning()
                
            }
        } catch {
            print("Error setting up camera: \(error.localizedDescription)")
        }
    }
}

extension Action {
    
    //MARK: - Selector
    func removeVideoInput(session: AVCaptureSession) {
        do {
            session.beginConfiguration()
            
            session.inputs.forEach { input in
                session.removeInput(input)
            }
            
            session.commitConfiguration()
        }
    }
    
    func tapPhoto() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.session!.startRunning()
        }
    }
    
    func tapCamera() {
        do {
            DispatchQueue.main.async { [self] in
                guard let session = session else { fatalError("session을 못받았음") }
                self.removeVideoInput(session: session)
                
                videoInput = (isBack) ? try? AVCaptureDeviceInput(device: captureFrontDevice) : try? AVCaptureDeviceInput(device: captureBackDevice)
                
                isBack.toggle()
                
                if let newVideoInput = videoInput,
                   session.canAddInput(newVideoInput) {
                    session.beginConfiguration()
                    session.addInput(newVideoInput)
                    session.commitConfiguration()
                    session.startRunning()
                }
                
            }
        }
    }
    
    func getImageBuffer(completion: @escaping (UIViewController?) -> Void) {
        if let lastFrame = self.lastFrame,
           let pixelBuffer = CMSampleBufferGetImageBuffer(lastFrame),
           let capturedImage = convertCIImageToUIImage(ciImage: CIImage(cvPixelBuffer: pixelBuffer)) {
            
            let capturedViewController = CapturedViewController(capturedImage: capturedImage, session: session!)
            capturedViewController.modalPresentationStyle = .fullScreen
            
            DispatchQueue.main.async {
                completion(capturedViewController)
            }
        } else {
            DispatchQueue.main.async {
                completion(nil)
            }
        }
    }
}

extension Action: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    //MARK: - Delegate
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        lastFrame = sampleBuffer
    }
}
