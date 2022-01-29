//
//  CaptureDelegate.swift
//  DART
//
//  Created by Yago  Cereijo Botana on 19/10/21.
//

import Foundation
import AVFoundation
import UIKit

class CaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate{
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        print("I am the delegate")
        guard let imageData = photo.fileDataRepresentation() else { return }
        let previewImage = UIImage(data: imageData)
        //self.image = previewImage
    }
}
