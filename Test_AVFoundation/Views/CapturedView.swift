//
//  PreView.swift
//  Test_AVFoundation
//
//  Created by 스냅태그 on 2023/07/11.
//

import UIKit
import SnapKit

class CapturedView: UIView {
    
    //MARK: - Declaration
    private var capturedImage: UIImage!
    
    //MARK: - UI Component
    private var img: UIImageView!
    private var saveButton: UIButton!
    private var reTakeButton: UIButton!
    
    //MARK: - Initialize
    convenience init(capturedImage: UIImage) {
        self.init()
        self.capturedImage = capturedImage
        
        addImg()
        addSaveButton()
        addReTakeButton()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CapturedView {
    
    //MARK: - Add View
    func addImg() {
        img = UIImageView()
        img.image = capturedImage
        
        self.addSubview(img)
        
        img.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    func addSaveButton() {
        saveButton = UIButton()
        saveButton.setTitle("저장하기", for: .normal)
        saveButton.backgroundColor = .blue
        
        self.addSubview(saveButton)
        
        saveButton.snp.makeConstraints {
            $0.bottom.equalToSuperview().inset(30)
            $0.right.equalToSuperview().offset(-30)
            $0.height.equalTo(50)
            $0.width.equalTo(100)
        }
        
        saveButton.addTarget(self, action: #selector(saveButtonTap(_:)), for: .touchUpInside)
    }
    
    func addReTakeButton() {
        reTakeButton = UIButton()
        reTakeButton.setTitle("다시찍기", for: .normal)
        reTakeButton.backgroundColor = .blue
        
        self.addSubview(reTakeButton)
        
        reTakeButton.snp.makeConstraints {
            $0.bottom.equalToSuperview().inset(30)
            $0.left.equalToSuperview().offset(30)
            $0.height.equalTo(50)
            $0.width.equalTo(100)
        }
        
        reTakeButton.addTarget(self, action: #selector(reTakeButtonTap(_:)), for: .touchUpInside)
    }
}

extension CapturedView {
    
    //MARK: - Selector
    @objc func reTakeButtonTap(_ sender: UIButton) {
        (superview?.next as? CapturedViewController)?.reTakeButtonTap(sender)
    }
    
    @objc func saveButtonTap(_ sender: UIButton) {
        (superview?.next as? CapturedViewController)?.saveButtonTap(sender)
    }
}

