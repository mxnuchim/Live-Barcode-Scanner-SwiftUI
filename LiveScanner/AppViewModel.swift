//
//  AppViewModel.swift
//  LiveScanner
//
//  Created by Manuchim Oliver on 26/04/2023.
//

import Foundation
import SwiftUI
import AVKit
import VisionKit

enum ScanType: String {
    case text, barcode
}

enum DataScannerAccessType {
    case notDetermined
    case cameraAccessNotGranted
    case cameraNotAvailable
    case scannerAvailable
    case scannerNotAvailable
}

@MainActor
final class AppViewModel: ObservableObject {
    
    @Published var dataScannerAccessStatus: DataScannerAccessType = .notDetermined
    
    @Published var recognizedItems: [RecognizedItem] = []
    
    @Published var ScanType: ScanType = .text
    
    @Published var textContentType: DataScannerViewController.TextContentType?
    
    @Published var recognizesMultipleItems = false
    
    var recognizedDataType: DataScannerViewController.RecognizedDataType {
        ScanType == .barcode ? .barcode() : .text(textContentType: textContentType)
    }
    
    var headerText: String {
        if recognizedItems.isEmpty {
            return "Scanning \(ScanType.rawValue)"
        } else {
            return "Found \(recognizedItems.count) item(s)"
        }
    }
    
    var dataScannerViewId: Int {
        var hasher = Hasher()
        hasher.combine(ScanType)
        hasher.combine(recognizesMultipleItems)
        
        if let textContentType {
            hasher.combine(textContentType)
        }
        return hasher.finalize()
    }
    
    private var isScannerAvailable: Bool {
        DataScannerViewController.isAvailable && DataScannerViewController.isSupported
    }
    
    func requestDataScannerAccess () async {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            dataScannerAccessStatus = .cameraNotAvailable
            return
        }
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                dataScannerAccessStatus = isScannerAvailable ? .scannerAvailable : .scannerNotAvailable
                
            case .restricted, .denied:
                dataScannerAccessStatus = .cameraAccessNotGranted
                
            case .notDetermined:
                let accessGranted = await AVCaptureDevice.requestAccess(for: .video)
                if accessGranted {
                    dataScannerAccessStatus = isScannerAvailable ? .scannerAvailable : .scannerNotAvailable
                } else {
                    dataScannerAccessStatus = .cameraAccessNotGranted
                }
                
            default: break
        }
    }
}
