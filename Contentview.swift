import SwiftUI
import UIKit
import Photos

struct ContentView: View {
    @State private var youtubeLink: String = ""
    @State private var thumbnailUrl: String? = nil
    @State private var isFetchingThumbnail: Bool = false
    @State private var thumbnailImage: UIImage? = nil
    @State private var isSettingsPresented = false
    @State private var backgroundColor = Color.black
    @State private var savedImages: [UIImage] = []

    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor 

                VStack {
                    TextField("Enter YouTube video link", text: $youtubeLink)
                        .padding()
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button(action: {
                        isFetchingThumbnail = true
                        fetchThumbnail()
                    }) {
                        Text("Fetch Thumbnail")
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10).stroke(Color.blue, lineWidth: 2))
                    }
                    .padding()

                    if isFetchingThumbnail {
                        Text("Fetching thumbnail, please wait...")
                            .foregroundColor(.blue)
                            .padding()
                    }

                    if let thumbnailImage = thumbnailImage {
                        Image(uiImage: thumbnailImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 200, height: 200)
                            .padding()

                        HStack {
                            Button(action: {
                                shareImage(image: thumbnailImage)
                            }) {
                                Text("Share")
                                    .padding()
                                    .background(RoundedRectangle(cornerRadius: 10).stroke(Color.blue, lineWidth: 2))
                            }
                            .padding()

                            Button(action: {
                                saveImage(image: thumbnailImage)
                            }) {
                                Text("Save")
                                    .padding()
                                    .background(RoundedRectangle(cornerRadius: 10).stroke(Color.blue, lineWidth: 2))
                            }
                            .padding()
                        }
                    } else {
                        Text("No thumbnail available")
                            .foregroundColor(.red)
                            .padding()
                    }

                    Divider()

                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(savedImages, id: \.self) { image in
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 100, height: 100)
                            }
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isSettingsPresented.toggle()
                    }) {
                        Image(systemName: "gearshape.fill")
                            .imageScale(.large)
                    }
                }
            }
            .sheet(isPresented: $isSettingsPresented) {
                SettingsView(backgroundColor: $backgroundColor)
            }
            .navigationBarTitle("Thumbnail Viewer")
        }
    }

    private func fetchThumbnail() {
        guard let videoId = extractVideoId(from: youtubeLink) else {
            print("Invalid YouTube link")
            isFetchingThumbnail = false
            return
        }

        let urlString = "https://img.youtube.com/vi/\(videoId)/maxresdefault.jpg"
        thumbnailUrl = urlString

        guard let url = URL(string: urlString),
              let imageData = try? Data(contentsOf: url),
              let image = UIImage(data: imageData) else {
            print("Failed to fetch or convert thumbnail image")
            isFetchingThumbnail = false
            return
        }

        thumbnailImage = image
        isFetchingThumbnail = false
    }

    private func extractVideoId(from youtubeLink: String) -> String? {
        guard let url = URL(string: youtubeLink) else {
            return nil
        }

        guard let htmlString = try? String(contentsOf: url) else {
            return nil
        }

        if let videoIdRange = htmlString.range(of: #""videoId":"([^"]*)""#, options: .regularExpression),
           let videoId = htmlString[videoIdRange].split(separator: ":").last?.replacingOccurrences(of: #"""#, with: "") {
            return videoId
        }

        return nil
    }

    private func saveImage(image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            print("Failed to convert image to data")
            return
        }

        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized:
                PHPhotoLibrary.shared().performChanges {
                    let request = PHAssetCreationRequest.forAsset()
                    request.addResource(with: .photo, data: imageData, options: nil)
                } completionHandler: { success, error in
                    if let error = error {
                        print("Error saving image to photo library: \(error)")
                    } else {
                        print("Image saved to photo library successfully")
                    }
                }
            case .denied, .restricted:
                print("Access to photo library denied")
            case .notDetermined:
                print("Access to photo library not determined")
            @unknown default:
                print("Unknown authorization status")
            }
        }
    }

    private func shareImage(image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            print("Failed to convert image to data")
            return
        }

        let activityViewController = UIActivityViewController(activityItems: [imageData], applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(activityViewController, animated: true, completion: nil)
    }
}

struct SettingsView: View {
    @Binding var backgroundColor: Color
    
    var body: some View {
        VStack {
            Text("made by speedyfriend67")
                .padding()
                .background(RoundedRectangle(cornerRadius: 10).stroke(Color.blue, lineWidth: 2))
            
            Spacer()
            
            ColorPicker("Select Background Color", selection: $backgroundColor)
                .padding()
                .background(RoundedRectangle(cornerRadius: 10).stroke(Color.blue, lineWidth: 2))
            
            Spacer()
        }
        .padding()
        .frame(width: 300, height: 300, alignment: .center)
        .cornerRadius(20)
        .shadow(radius: 10)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
