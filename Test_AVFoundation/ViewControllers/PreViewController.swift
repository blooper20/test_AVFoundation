//
//  PreViewController.swift
//  Test_AVFoundation
//
//  Created by 스냅태그 on 2023/07/10.
//

import UIKit
import SnapKit
import AVFoundation
import Photos

class PreViewController: UIViewController {
    
    //MARK: - Declaration
    private var capturedImage: UIImage!
    private var session: AVCaptureSession!
    
    
    //MARK: - UI Component
    private var preView: PreView!
    
    //MARK: - Initialize
    convenience init(capturedImage: UIImage, session: AVCaptureSession) {
        self.init()
        
        self.capturedImage = capturedImage
        self.session = session
    }
    
    //MARK: - View Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addPreView()
    }
}

extension PreViewController {
    
    func addPreView() {
        preView = PreView(capturedImage: capturedImage)
        
        self.view.addSubview(preView)
        
        preView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    //MARK: - Selector
    @objc func reTakeButtonTap(_ sender: UIButton) {
        DispatchQueue.main.async {
            self.dismiss(animated: true)
            self.session.startRunning()
        }
    }
    
    @objc func saveButtonTap(_ sender: UIButton) {
        DispatchQueue.main.async {
            PHPhotoLibrary.requestAuthorization { status in
                guard status == .authorized else {
                    print("권한이 거부되었습니다.")
                    
                    return
                }
                PHPhotoLibrary.shared().performChanges({
                    _ = PHAssetChangeRequest.creationRequestForAsset(from: self.capturedImage)
                }) { success, error in
                    if success {
                        print("사진이 저장되었습니다.")
                        DispatchQueue.main.async {
                            self.dismiss(animated: true)
                        }
                        self.session.startRunning()
                    } else {
                        print("사진 저장에 실패했습니다: \(error?.localizedDescription ?? "")")
                    }
                }
            }
        }
    }
}
