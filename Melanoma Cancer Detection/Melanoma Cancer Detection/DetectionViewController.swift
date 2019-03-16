import UIKit
import CoreML
import Vision
import AVKit

class DetectionViewController: UIViewController,AVCaptureVideoDataOutputSampleBufferDelegate {
    
    enum MelanomaIndicator: String {
        case benign = "Benign"
        case normal = "Normal"
        case developing = "Developing"
        
    }
    
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        guard let melanomaPredictModel = try? VNCoreMLModel(for: melanomaPredict().model ) else{
            return
        }
        
        let request = VNCoreMLRequest(model: melanomaPredictModel) { (finishedRequest, err) in
            
            guard let results = finishedRequest.results as? [VNClassificationObservation] else {
                return
                
            }
            
            guard let initialResult = results.first else{
                return
            }
            
            var predictString = ""
            
            DispatchQueue.main.async {
                
                switch initialResult.identifier{
                    
                case MelanomaIndicator.developing.rawValue:
                    predictString = "You are developing Melanoma"
                    
                case MelanomaIndicator.benign.rawValue:
                    predictString = "You are diagnosed with Melanoma"
                    
                case MelanomaIndicator.normal.rawValue:
                    predictString = "You are not diagnosed with Melanoma"
                    
                default:
                    break
                }
                
                self.predictionLabel.text = predictString + "(\(initialResult.confidence))"
            }
        }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:] ).perform([request])
        
        
    }
    
    
    
    @IBOutlet weak var predictionLabel: UILabel!
    
    func configureCamera() {
        
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        captureSession.startRunning()
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            return
        }
        
        guard let captureInput = try? AVCaptureDeviceInput(device: captureDevice) else {
            return
        }
        
        
        captureSession.addInput(captureInput)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self as AVCaptureVideoDataOutputSampleBufferDelegate, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCamera()
    }
}

