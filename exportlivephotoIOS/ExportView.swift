import SwiftUI
import Photos
import AVFoundation
import Combine

struct LivePhotoCreationView: View {
    @State private var selectedImage: UIImage?
    @State private var selectedVideo: URL?
    @State private var isLivePhotoCreated = false
    @State private var errorMessage: String?
    @State private var isImagePickerPresented = false
    @State private var isDocumentPickerPresented = false
    @State private var percentage: Double = 0.0
    @State private var urlExported: String = ""
    var body: some View {
        VStack {
            // Image Selection
            Button("Select Image") {
                isImagePickerPresented = true
            }
            .sheet(isPresented: $isImagePickerPresented) {
                ImagePicker(selectedImage: $selectedImage)
            }
            
            // Video Selection
            Button("Select Video") {
                isDocumentPickerPresented = true
            }
            .sheet(isPresented: $isDocumentPickerPresented) {
                DocumentPicker(selectedVideo: $selectedVideo)
            }
            
            // Create Live Photo Button
            Button("Create Live Photo") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    // your function
                    createLivePhoto()
                }
               
            }
            .disabled(selectedImage == nil || selectedVideo == nil)
            
            // Display Selected Media
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
            }
            if let videoURL = selectedVideo, let thumbnail = generateThumbnail(from: videoURL) {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
            }
            Text("Exporting: \(percentage * 100) %")
            Text("URL exported: \(urlExported)")
            // Status Messages
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
            
            if isLivePhotoCreated {
                Text("Live Photo Created Successfully!")
                    .foregroundColor(.green)
            }
        }
        .padding()
    }
    func generateThumbnail(from videoURL: URL) -> UIImage? {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true

        let time = CMTime(seconds: 1, preferredTimescale: 600)
        do {
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            print("Error generating thumbnail: \(error)")
            return nil
        }
    }
    func createLivePhoto() {
        guard let image = selectedImage, let videoURL = selectedVideo else {
            errorMessage = "Please select both image and video"
            return
        }
        
        let tempDirectory = FileManager.default.temporaryDirectory
        let imageFileName = "temp_image_\(UUID().uuidString).jpg"
        let videoFileName = "temp_video_\(UUID().uuidString).mov"
        
        let tempImageURL = tempDirectory.appendingPathComponent(imageFileName)
        let tempVideoURL = tempDirectory.appendingPathComponent(videoFileName)
        
        do {
            if let imageData = image.jpegData(compressionQuality: 1.0) {
                try imageData.write(to: tempImageURL)
            }
            
            try FileManager.default.copyItem(at: videoURL, to: tempVideoURL)
            LivePhoto.generate(from: tempImageURL, videoURL: tempVideoURL) { percent in
                print(percent)
                percentage = percent
            } completion: { livePhoto, resouces in
                if let resouces = resouces {
                    LivePhoto.saveToLibrary(resouces) { result in
                        print("video exported \(resouces)")
                        urlExported = "\(resouces)"
                    }
                }
            }

           
        } catch {
            errorMessage = "Error preparing files: \(error.localizedDescription)"
        }
    }
}

// MARK: - ImagePicker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }

    }
}

// MARK: - DocumentPicker
struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var selectedVideo: URL?
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(documentTypes: ["public.movie"], in: .import)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            // Start accessing the security-scoped resource
            if url.startAccessingSecurityScopedResource() {
                defer { url.stopAccessingSecurityScopedResource() }
                parent.selectedVideo = url
            } else {
                // Handle failure to access resource
                print("Failed to access security-scoped resource.")
            }
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {}
    }
}
