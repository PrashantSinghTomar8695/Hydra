import SwiftUI
import AVFoundation

struct PairingView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var networkManager: NetworkManager
    @State private var isScanning = false
    @State private var scannedCode: String?
    
    var body: some View {
        NavigationView {
            VStack {
                if isScanning {
                    QRCodeScannerView { code in
                        scannedCode = code
                        isScanning = false
                        handleScannedCode(code)
                    }
                } else {
                    Text("Tap to scan QR code")
                        .font(.headline)
                        .padding()
                    
                    Button("Start Scanning") {
                        isScanning = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Pair Device")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func handleScannedCode(_ code: String) {
        // Parse QR code URL: HYDRA://pair?token=...&device_id=...&port=...&ip=...
        guard let url = URL(string: code),
              url.scheme == "HYDRA",
              url.host == "pair" else {
            return
        }
        
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []
        
        var token: String?
        var deviceId: String?
        var port: Int?
        var ip: String?
        
        for item in queryItems {
            switch item.name {
            case "token":
                token = item.value
            case "device_id":
                deviceId = item.value
            case "port":
                port = Int(item.value ?? "")
            case "ip":
                ip = item.value
            default:
                break
            }
        }
        
        if let token = token, let deviceId = deviceId, let port = port, let ip = ip {
            networkManager.connect(ip: ip, port: port, token: token, deviceId: deviceId)
            dismiss()
        }
    }
}

struct QRCodeScannerView: UIViewControllerRepresentable {
    let onCodeScanned: (String) -> Void
    
    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.onCodeScanned = onCodeScanned
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}
}

class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onCodeScanned: ((String) -> Void)?
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        captureSession = AVCaptureSession()
        captureSession?.addInput(videoInput)
        
        let metadataOutput = AVCaptureMetadataOutput()
        captureSession?.addOutput(metadataOutput)
        
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = [.qr]
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        previewLayer?.frame = view.layer.bounds
        previewLayer?.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer!)
        
        captureSession?.startRunning()
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           let stringValue = metadataObject.stringValue {
            captureSession?.stopRunning()
            onCodeScanned?(stringValue)
        }
    }
}

