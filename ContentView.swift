import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var camera = CameraManager()

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.07, blue: 0.12).ignoresSafeArea()
            VStack(spacing: 18) {
                Text("DUALCAM LC")
                    .font(.system(size: 25, weight: .black, design: .rounded))
                    .foregroundColor(Color(red: 1, green: 0.76, blue: 0.13))
                Text("Cámara frontal + trasera")
                    .foregroundColor(.white.opacity(0.8))
                ZStack(alignment: .bottomTrailing) {
                    CameraPreview(session: camera.session)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.2), lineWidth: 1))
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text("VISTA FRONTAL")
                                .font(.caption2.bold())
                                .padding(7)
                                .background(.black.opacity(0.7))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(12)
                    // MultiCam preview output is presented as one preview layer;
                    // the two still photos are captured independently.
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(3/4, contentMode: .fit)
                HStack(spacing: 24) {
                    Button {
                        camera.captureBoth()
                    } label: {
                        Image(systemName: "camera.circle.fill")
                            .font(.system(size: 76))
                            .foregroundColor(Color(red: 1, green: 0.76, blue: 0.13))
                    }
                    .disabled(!camera.isReady || camera.isCapturing)
                }
                Text(camera.status)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal)
                Spacer(minLength: 4)
            }
            .padding()
        }
        .onAppear { camera.start() }
        .onDisappear { camera.stop() }
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }
    func updateUIView(_ uiView: PreviewView, context: Context) {}
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}
