//
//  CameraView.swift
//  Test_AVFoundation
//
//  Created by 스냅태그 on 2023/07/11.
//

import UIKit
import SnapKit
import AVFoundation

class CameraView: UIView {
    
    //MARK: - Declaration
    private var cameraMode: CameraMode!
    private var isTorch: Bool = false
    
    //MARK: - UI Component
    private var cameraLabel: UILabel!
    private var shutterButton: UIButton!
    private var videoButton: UIButton!
    private var cameraButton: UIButton!
    
    var noZoomButton: UIButton!
    var doubleZoomButton: UIButton!
    
    var torchButton: UIButton!
    var isDefaultLens: Bool!
    
    //MARK: - Initialize
    convenience init(cameraMode: CameraMode, isDefaultLens: Bool) {
        self.init()
        self.cameraMode = cameraMode
        self.isDefaultLens = isDefaultLens
        
        addShutterButton()
        addVideoButton()
        addCameraLabel()
        addDoubleZoomButton()
        addNoZoomButton()
        addTorchButton()
        addCameraButton()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CameraView {
    
    //MARK: - Add View
    func addCameraButton() {
        cameraButton = UIButton()
        cameraButton.setImage(UIImage(systemName: "repeat.circle.fill"), for: .normal)
        cameraButton.backgroundColor = .black
        
        self.addSubview(cameraButton)
        
        cameraButton.snp.makeConstraints {
            $0.bottom.equalToSuperview().offset(-20)
            $0.right.equalToSuperview().offset(-20)
            $0.width.height.equalTo(50)
        }
        
        cameraButton.addTarget(self, action: #selector(tapCamera(_:)), for: .touchUpInside)
    }
    
    func addTorchButton() {
        torchButton = UIButton()
        torchButton.setImage(UIImage(systemName: (isTorch) ? "bolt.slash.fill" : "bolt.fill"), for: .normal)
        torchButton.tintColor = .yellow
        torchButton.backgroundColor = .black.withAlphaComponent(0.7)
        torchButton.addTarget(self, action: #selector(tapTorch(_:)), for: .touchUpInside)
        
        self.addSubview(torchButton)
        
        torchButton.snp.makeConstraints {
            $0.top.equalTo(cameraLabel.snp.bottom).offset(10)
            $0.width.height.equalTo(50)
            $0.centerX.equalToSuperview()
        }
    }
    
    func addNoZoomButton() {
        noZoomButton = UIButton()
        noZoomButton.setTitle((isDefaultLens) ? "1.0" : "0.5", for: .normal)
        noZoomButton.addTarget(self, action: #selector(tapNoZoom(_:)), for: .touchUpInside)
        noZoomButton.backgroundColor = .black.withAlphaComponent(0.7)
        
        self.addSubview(noZoomButton)
        
        noZoomButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.centerX.equalToSuperview().offset(-30)
            $0.width.height.equalTo(50)
        }
    }
    
    func addDoubleZoomButton() {
        doubleZoomButton = UIButton()
        doubleZoomButton.setTitle((isDefaultLens) ? "2.0" : "1.0", for: .normal)
        doubleZoomButton.addTarget(self, action: #selector(tapDoubleZoom(_:)), for: .touchUpInside)
        doubleZoomButton.backgroundColor = .black.withAlphaComponent(0.7)
        
        self.addSubview(doubleZoomButton)
        
        doubleZoomButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.centerX.equalToSuperview().offset(30)
            $0.width.height.equalTo(50)
        }
    }
    
    func addCameraLabel() {
        cameraLabel = UILabel()
        cameraLabel.backgroundColor = .black.withAlphaComponent(0.7)
        cameraLabel.text = cameraMode.rawValue
        cameraLabel.textColor = .white
        cameraLabel.textAlignment = .center
        
        self.addSubview(cameraLabel)
        
        cameraLabel.snp.makeConstraints {
            $0.width.equalTo(100)
            $0.height.equalTo(50)
            $0.top.equalToSuperview().offset(50)
            $0.centerX.equalToSuperview()
        }
    }
    
    func addVideoButton() {
        videoButton = UIButton()
        
        if cameraMode == .camera {
            videoButton.setTitle("비디오", for: .normal)
        } else {
            videoButton.setTitle("사진", for: .normal)
        }
        
        videoButton.tintColor = .white
        videoButton.backgroundColor = .black
        
        self.addSubview(videoButton)
        
        videoButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(shutterButton.snp.top).offset(-20)
            $0.height.equalTo(50)
            $0.width.equalTo(100)
        }
        
        videoButton.addTarget(self, action: #selector(tapVideo(_:)), for: .touchUpInside)
    }
    
    func addShutterButton() {
        shutterButton = UIButton()
        shutterButton.setImage(UIImage(systemName: "record.circle"), for: .normal)
        shutterButton.tintColor = .red
        shutterButton.backgroundColor = .black
        
        self.addSubview(shutterButton)
        
        shutterButton.snp.makeConstraints {
            $0.bottom.equalToSuperview().inset(30)
            $0.width.height.equalTo(50)
            $0.centerX.equalToSuperview().inset(100)
        }
        
        shutterButton.addTarget(self, action: #selector(tapShutter(_:)), for: .touchUpInside)
    }
}

extension CameraView {
    
    //MARK: - Selector
    @objc func tapCamera(_ sender: UIButton) {
        switch cameraMode {
        case .camera:
            (superview?.next as? ViewController)?.tapCamera(sender)
            break
        case .video:
            (superview?.next as? VideoViewController)?.tapCamera(sender)
            break
        case .none:
            break
        }
    }
    
    @objc func tapTorch(_ sender: UIButton) {
        switch cameraMode {
        case .camera:
            (superview?.next as? ViewController)?.tapTorch(sender)
            break
        case .video:
            (superview?.next as? VideoViewController)?.tapTorch(sender)
            break
        case .none:
            break
        }
    }
    
    @objc func tapNoZoom(_ sender: UIButton) {
        switch cameraMode {
        case .camera:
            (superview?.next as? ViewController)?.tapNoZoom(sender)
            break
        case .video:
            (superview?.next as? VideoViewController)?.tapNoZoom(sender)
            break
        case .none:
            break
        }
    }
    
    @objc func tapDoubleZoom(_ sender: UIButton) {
        switch cameraMode {
        case .camera:
            (superview?.next as? ViewController)?.tapDoubleZoom(sender)
            break
        case .video:
            (superview?.next as? VideoViewController)?.tapDoubleZoom(sender)
            break
        case .none:
            break
        }
    }
    
    @objc func tapShutter(_ sender: UIButton) {
        switch cameraMode {
        case .camera:
            (superview?.next as? ViewController)?.tapShutter(sender)
            break
        case .video:
            (superview?.next as? VideoViewController)?.tapShutter(sender)
            break
        case .none:
            break
        }
    }
    
    @objc func tapVideo(_ sender: UIButton) {
        switch cameraMode {
        case .camera:
            (superview?.next as? ViewController)?.tapVideo(sender)
            break
        case .video:
            (superview?.next as? VideoViewController)?.tapPhoto(sender)
            break
        case .none:
            break
        }
    }
}
