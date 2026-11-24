# DualCam LC

Proyecto inicial nativo SwiftUI para iOS. Utiliza `AVCaptureMultiCamSession` para preparar captura de fotografía con cámara frontal y trasera y guarda ambas imágenes en Fotos.

## Compilación de verificación
GitHub Actions usa un runner macOS, instala XcodeGen y genera el proyecto Xcode desde `project.yml`. La compilación del simulador verifica el proyecto, pero **el simulador no tiene cámaras reales**.

## Importante
- La captura simultánea depende del modelo de iPhone y de que `AVCaptureMultiCamSession.isMultiCamSupported` sea verdadero.
- La vista previa actual es una vista de sesión y todavía no compone una vista PiP real de las dos cámaras.
- Este primer prototipo captura dos imágenes y las guarda en Fotos.
- Para instalar en un iPhone físico hace falta una compilación firmada y un método de distribución compatible. La cuenta gratuita de Apple no habilita TestFlight.
