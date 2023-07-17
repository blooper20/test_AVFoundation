//
//  convertCIImageToUIImage.swift
//  Test_AVFoundation
//
//  Created by 스냅태그 on 2023/07/11.
//

import UIKit

func convertCIImageToUIImage(ciImage: CIImage) -> UIImage? {
    let context = CIContext(options: nil)
    guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
        return nil
    }
    
    let orientation: UIImage.Orientation
    let currentDeviceOrientation = UIDevice.current.orientation
    
    switch currentDeviceOrientation {
    case .portrait:
        orientation = .right
    case .portraitUpsideDown:
        orientation = .left
    case .landscapeLeft:
        orientation = .up
    case .landscapeRight:
        orientation = .down
    default:
        orientation = .right
    }
    
    let uiImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: orientation)
    return uiImage
}
