import Foundation
import AVFoundation
import Photos
import SwiftUI

final class CameraManager: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    let session = AVCaptureMultiCamSession()
    private let photoQueue = DispatchQueue(label: "com.lc.dualcamlc.photo")
    private var backOutput = AVCapturePhotoOutput()
    private var frontOutput = AVCapturePhotoOutput()
    private var pending = 0
    private var capturedData: [Data] = []
    @Published var status = "Preparando cámaras…"
    @Published var isReady = false
    @Published var isCapturing = false

    func start() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            guard let self else { return }
            guard granted else {
                DispatchQueue.main.async { self.status = "Permite el acceso a la cámara en Ajustes." }
                return
            }
            self.configure()
        }
    }

    private func configure() {
        guard AVCaptureMultiCamSession.isMultiCamSupported else {
            DispatchQueue.main.async { self.status = "Este iPhone no admite captura simultánea de ambas cámaras." }
            return
        }
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        guard let back = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let front = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let backInput = try? AVCaptureDeviceInput(device: back),
              let frontInput = try? AVCaptureDeviceInput(device: front),
              session.canAddInput(backInput), session.canAddInput(frontInput),
              session.canAddOutput(backOutput), session.canAddOutput(frontOutput) else {
            DispatchQueue.main.async { self.status = "No fue posible configurar las dos cámaras." }
            return
        }

        session.addInputWithNoConnections(backInput)
        session.addInputWithNoConnections(frontInput)
        session.addOutput(backOutput)
        session.addOutput(frontOutput)

        if let backPort = backInput.ports(for: .video, sourceDeviceType: back.deviceType, sourceDevicePosition: .back).first,
           let connection = AVCaptureConnection(inputPorts: [backPort], output: backOutput),
           session.canAddConnection(connection) { session.addConnection(connection) }

        if let frontPort = frontInput.ports(for: .video, sourceDeviceType: front.deviceType, sourceDevicePosition: .front).first,
           let connection = AVCaptureConnection(inputPorts: [frontPort], output: frontOutput),
           session.canAddConnection(connection) { session.addConnection(connection) }

        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
            DispatchQueue.main.async {
                self.isReady = true
                self.status = "Listo. Toca el botón para fotografiar ambas cámaras."
            }
        }
    }

    func captureBoth() {
        guard isReady, !isCapturing else { return }
        isCapturing = true
        capturedData.removeAll()
        pending = 2
        let settingsBack = AVCapturePhotoSettings()
        let settingsFront = AVCapturePhotoSettings()
        photoQueue.async {
            self.backOutput.capturePhoto(with: settingsBack, delegate: self)
            self.frontOutput.capturePhoto(with: settingsFront, delegate: self)
        }
        status = "Capturando cámara frontal y trasera…"
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let data = photo.fileDataRepresentation() { capturedData.append(data) }
        pending -= 1
        if pending == 0 {
            let images = capturedData
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { permission in
                guard permission == .authorized || permission == .limited else {
                    DispatchQueue.main.async {
                        self.status = "No hay permiso para guardar en Fotos."
                        self.isCapturing = false
                    }
                    return
                }
                PHPhotoLibrary.shared().performChanges({
                    images.forEach { data in
                        let request = PHAssetCreationRequest.forAsset()
                        request.addResource(with: .photo, data: data, options: nil)
                    }
                }) { success, error in
                    DispatchQueue.main.async {
                        self.status = success ? "¡Listo! Las dos fotos se guardaron en Fotos." : "Error al guardar: \(error?.localizedDescription ?? "desconocido")"
                        self.isCapturing = false
                    }
                }
            }
        }
    }

    func stop() {
        DispatchQueue.global(qos: .utility).async {
            if self.session.isRunning { self.session.stopRunning() }
        }
    }
}
