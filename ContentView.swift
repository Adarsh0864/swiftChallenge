import SwiftUI
import CoreImage.CIFilterBuiltins
import PhotosUI

// Extension to handle hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct ContentView: View {
    @State private var inputText = ""
    @State private var qrCode: UIImage?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var selectedImage: UIImage?
    @State private var pixelArtText: String = ""
    @State private var showingImagePicker = false
    @State private var generationType: GenerationType = .text
    @State private var isQRGenerated = false
    @State private var showingShareSheet = false
    
    enum GenerationType {
        case text
        case image
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#f2f2f7").edgesIgnoringSafeArea(.all)
                
                VStack {
                    if !isQRGenerated {
                        Picker("QR Code Type", selection: $generationType) {
                            Text("Text").tag(GenerationType.text)
                            Text("Image").tag(GenerationType.image)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding()
                        
                        if generationType == .text {
                            TextField("Enter text for QR code", text: $inputText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.horizontal)
                                .padding(.bottom)
                            
                            Button(action: {
                                generateQRCode()
                                isQRGenerated = true
                            }) {
                                Text("Generate QR Code")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(height: 50)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                            .disabled(inputText.isEmpty)
                        } else {
                            VStack {
                                if let selectedImage = selectedImage {
                                    Image(uiImage: selectedImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 200)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .shadow(color: .blue.opacity(0.6), radius: 5)
                                }
                                
                                Button(action: {
                                    showingImagePicker = true
                                }) {
                                    Text(selectedImage == nil ? "Select Image" : "Change Image")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(height: 50)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.green)
                                        .cornerRadius(12)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                
                                if selectedImage != nil {
                                    Button(action: {
                                        generatePixelArt()
                                        isQRGenerated = true
                                    }) {
                                        Text("Generate Pixel Art QR Code")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .frame(height: 50)
                                            .frame(maxWidth: .infinity)
                                            .background(Color.blue)
                                            .cornerRadius(12)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    } else {
                        if let qrCode = qrCode {
                            Spacer()
                            
                            VStack(spacing: 16) {
                                Image(uiImage: qrCode)
                                    .interpolation(.none)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 250, height: 250)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .shadow(color: .gray.opacity(0.3), radius: 10)
                                
                                if !pixelArtText.isEmpty {
                                    Text("Original Pixel Art:")
                                        .font(.headline)
                                        .foregroundColor(.black)
                                        .padding(.top, 8)
                                    
                                    Text(pixelArtText)
                                        .font(.system(.body, design: .monospaced))
                                        .padding(8)
                                        .background(Color.white)
                                        .cornerRadius(8)
                                }
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 20) {
                                Button(action: {
                                    isQRGenerated = false
                                    pixelArtText = ""
                                }) {
                                    Text("Change")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(height: 50)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.gray)
                                        .cornerRadius(12)
                                }
                                
                                Button(action: {
                                    saveQRCode()
                                }) {
                                    Text("Save")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(height: 50)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.blue)
                                        .cornerRadius(12)
                                }
                                
                                Button(action: {
                                    showingShareSheet = true
                                }) {
                                    Text("Share")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(height: 50)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.green)
                                        .cornerRadius(12)
                                }
                            }
                            .padding()
                        }
                    }
                    Spacer()
                }
            }
            .navigationTitle("QRMatrix")
            .foregroundColor(.black)
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Info"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showingShareSheet) {
                if let qrCode = qrCode {
                    ShareSheet(items: [qrCode])
                }
            }
        }
    }

    func generateQRCode() {
        guard !inputText.isEmpty else {
            qrCode = nil
            return
        }
        
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        let data = Data(inputText.utf8)
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        
        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledQRImage = outputImage.transformed(by: transform)
            
            if let cgImage = context.createCGImage(scaledQRImage, from: scaledQRImage.extent) {
                qrCode = UIImage(cgImage: cgImage)
            }
        }
    }
    
    func generatePixelArt() {
        guard let selectedImage = selectedImage else { return }
        
        let pixelArt = createPixelArt(from: selectedImage, size: 15)
        let emojiPixelArt = convertToEmojiPixelArt(pixelArt)
        pixelArtText = emojiPixelArt
        generateQRFromText(emojiPixelArt)
    }
    
    func createPixelArt(from image: UIImage, size: Int) -> [[UIColor]] {
        let resizedImage = resizeImage(image: image, targetSize: CGSize(width: size, height: size))
        var pixelColors = Array(repeating: Array(repeating: UIColor.clear, count: size), count: size)
        
        if let cgImage = resizedImage.cgImage {
            let bytesPerRow = cgImage.bytesPerRow
            let dataSize = bytesPerRow * cgImage.height
            var pixelData = [UInt8](repeating: 0, count: dataSize)
            
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let context = CGContext(data: &pixelData,
                                   width: cgImage.width,
                                   height: cgImage.height,
                                   bitsPerComponent: 8,
                                   bytesPerRow: bytesPerRow,
                                   space: colorSpace,
                                   bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            
            context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
            for y in 0..<size {
                for x in 0..<size {
                    let offset = (bytesPerRow * y) + x * 4
                    let red = CGFloat(pixelData[offset]) / 255.0
                    let green = CGFloat(pixelData[offset + 1]) / 255.0
                    let blue = CGFloat(pixelData[offset + 2]) / 255.0
                    let alpha = CGFloat(pixelData[offset + 3]) / 255.0
                    
                    pixelColors[y][x] = UIColor(red: red, green: green, blue: blue, alpha: alpha)
                }
            }
        }
        
        return pixelColors
    }
    
    func convertToEmojiPixelArt(_ pixelArt: [[UIColor]]) -> String {
        var result = ""
        
        for row in pixelArt {
            for color in row {
                var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
                color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                
                if alpha < 0.5 {
                    result += "⬜️"
                } else if red > 0.7 && green < 0.3 && blue < 0.3 {
                    result += "🟥"
                } else if red > 0.7 && green > 0.5 && blue < 0.3 {
                    result += "🟧"
                } else if red > 0.7 && green > 0.7 && blue < 0.3 {
                    result += "🟨"
                } else if red < 0.3 && green > 0.6 && blue < 0.3 {
                    result += "🟩"
                } else if red < 0.3 && green < 0.3 && blue > 0.6 {
                    result += "🟦"
                } else if red > 0.5 && green < 0.3 && blue > 0.5 {
                    result += "🟪"
                } else if red > 0.5 && green > 0.3 && blue < 0.3 {
                    result += "🟫"
                } else if red < 0.2 && green < 0.2 && blue < 0.2 {
                    result += "⬛️"
                } else {
                    result += "⬜️"
                }
            }
            result += "\n"
        }
        
        return result
    }
    
    func generateQRFromText(_ text: String) {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        guard let data = text.data(using: .utf8) else {
            alertMessage = "Failed to encode text"
            showingAlert = true
            return
        }
        
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        
        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledQRImage = outputImage.transformed(by: transform)
            
            if let cgImage = context.createCGImage(scaledQRImage, from: scaledQRImage.extent) {
                qrCode = UIImage(cgImage: cgImage)
            }
        }
    }
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        
        let ratio = min(widthRatio, heightRatio)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        
        let originX = (targetSize.width - newSize.width) / 2.0
        let originY = (targetSize.height - newSize.height) / 2.0
        
        image.draw(in: CGRect(x: originX, y: originY, width: newSize.width, height: newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? image
    }
    
    func saveQRCode() {
        guard let qrCode = qrCode else { return }
        
        UIImageWriteToSavedPhotosAlbum(qrCode, nil, nil, nil)
        alertMessage = "QR Code saved to Photos"
        showingAlert = true
    }
}


struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
