//
//  ViewController.swift
//  LaneDetector
//
//  Created by Helge Stahlmann on 14.01.22.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    private var captureSession: AVCaptureSession = AVCaptureSession()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.addCameraInput()
        self.getFrames()
        self.captureSession.startRunning()
        
    }
    
    @IBOutlet weak var imageView: UIImageView!
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection) {
//        // here we can process the frame
//        print("did receive frame")
            
            guard let  imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags.readOnly)
            let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)
            let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
            let width = CVPixelBufferGetWidth(imageBuffer)
            let height = CVPixelBufferGetHeight(imageBuffer)
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            var bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Little.rawValue
            bitmapInfo |= CGImageAlphaInfo.premultipliedFirst.rawValue & CGBitmapInfo.alphaInfoMask.rawValue
            let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)
            guard let quartzImage = context?.makeImage() else { return }
            CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags.readOnly)
            let image = UIImage(cgImage: quartzImage)
            let imageWithLaneOverlay = LaneDetectorBridge().detectLane(in: image)
            
            DispatchQueue.main.async {
                self.imageView.image = imageWithLaneOverlay
            }
    
    }
    
    // MARK: - Private functions
    
    private func addCameraInput() {
        guard let device = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera],
            mediaType: .video,
            position: .back).devices.first else {
                fatalError("No back camera device found, please make sure to run SimpleLaneDetection in an iOS device and not a simulator")
        }
        let cameraInput = try! AVCaptureDeviceInput(device: device)
        self.captureSession.addInput(cameraInput)
    }
    
    private func getFrames() {
        videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.frame.processing.queue"))
        self.captureSession.addOutput(videoDataOutput)
        guard let connection = self.videoDataOutput.connection(with: AVMediaType.video),
            connection.isVideoOrientationSupported else { return }
        connection.videoOrientation = .portrait
    }

}

