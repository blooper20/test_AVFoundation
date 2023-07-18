//
//  VideoViewController.swift
//  Test_AVFoundation
//
//  Created by 스냅태그 on 2023/07/10.
//

import UIKit
import SnapKit

class VideoViewController: UIViewController {
    
    //MARK: - Declaration
    private var action: Action!
    
    //MARK: - UI Component
    private var cameraView: CameraView!
    
    //MARK: - View Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        config()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        action.settingCamera()
        addCameraView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        view.subviews.forEach { subview in
            subview.removeFromSuperview()
        }
        view.layer.sublayers?.forEach { sublayer in
            sublayer.removeFromSuperlayer()
        }
    }
}

extension VideoViewController {
    
    //MARK: - Add View
    func addCameraView() {
        cameraView = CameraView(cameraMode: .video)
        
        self.view.addSubview(cameraView)
        
        cameraView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}

extension VideoViewController {
    
    //MARK: - Function
    
    func config() {
        action = Action()
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(doPinch(_:)))
        self.view.addGestureRecognizer(pinch)

        action.getLensStatus()
        action.settingCamera()

        guard let previewLayer = action.previewLayer else { fatalError("preview를 찾을 수 없음")}
        
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        
        view.layer.addSublayer(previewLayer)
    }
    
    //MARK: - Selector
    @objc func tapCamera(_ sender: UIButton) {
        DispatchQueue.main.async { [self] in
            action.tapCamera()
            cameraView.torchButton.isHidden.toggle()
            cameraView.noZoomButton.isHidden.toggle()
            cameraView.doubleZoomButton.isHidden.toggle()
            
            isTorch = false
            self.cameraView.torchButton.setImage(UIImage(systemName: "bolt.fill"), for: .normal)
        }
    }
    
    @objc func tapTorch(_ sender: UIButton) {
        do {
            captureDevice = (isBack) ? captureBackDevice : captureFrontDevice
            if let captureDevice = captureDevice {
                try captureDevice.lockForConfiguration()
                (isTorch) ? (captureDevice.torchMode = .off): (captureDevice.torchMode = .on)
                isTorch.toggle()
                captureDevice.unlockForConfiguration()
            }
        } catch {
            return
        }
        
        sender.setImage(UIImage(systemName: (isTorch) ? "bolt.slash.fill" : "bolt.fill"), for: .normal)
    }
    
    
    @objc func tapNoZoom(_ sender: UIButton) {
        do {
            captureDevice = (isBack) ? captureBackDevice : captureFrontDevice
            if let captureDevice = captureDevice {
                try captureDevice.lockForConfiguration()
                captureDevice.ramp(toVideoZoomFactor: 1.0, withRate: 2.0)
                captureDevice.unlockForConfiguration()
            }
        } catch {
            return
        }
    }
    
    @objc func tapDoubleZoom(_ sender: UIButton) {
        do {
            captureDevice = (isBack) ? captureBackDevice : captureFrontDevice
            
            if let captureDevice = captureDevice {
                try captureDevice.lockForConfiguration()
                captureDevice.ramp(toVideoZoomFactor: 2.0, withRate: 2.0)
                captureDevice.unlockForConfiguration()
            }
        } catch {
            return
        }
    }
    
    @objc func tapPhoto(_ sender: UIButton) {
        self.dismiss(animated: true, completion: {
            self.action.tapPhoto()
        })
    }
    
    @objc func tapShutter(_ sender: UIButton) {
        
        action.getImageBuffer(completion: { capturedViewController in
            guard let capturedViewController = capturedViewController else { return }
            DispatchQueue.main.async {
                self.present(capturedViewController, animated: true, completion: { [self] in
                    isTorch = false
                    guard let session = action.session else { fatalError("session을 못받았음") }
                    session.stopRunning()
                })
            }
        })
        self.cameraView.torchButton.setImage(UIImage(systemName:"bolt.fill"), for: .normal)
    }
    
    @objc func doPinch(_ pinch: UIPinchGestureRecognizer) {
        do {
            captureDevice = (isBack) ? captureBackDevice : captureFrontDevice
            guard let captureDevice = captureDevice else { return }
            
            var initialScale: CGFloat = captureDevice.videoZoomFactor
            
            let minAvailableZoomScale = captureDevice.minAvailableVideoZoomFactor
            let maxAvailableZoomScale = 6.0
            
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
            captureDevice.unlockForConfiguration()
        } catch {
            return
        }
    }
}
