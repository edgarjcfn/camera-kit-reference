//  Copyright Snap Inc. All rights reserved.
//  CameraKitSample

import UIKit
import SCSDKCameraKit
import SCSDKCameraKitReferenceUI
import SCSDKCreativeKit
// Reenable if using SwiftUI reference UI
//import SCSDKCameraKitReferenceSwiftUI
//import SwiftUI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, SnapchatDelegate {

    private enum Constants {
        static let partnerGroupId = "REPLACE-THIS-WITH-YOUR-OWN-APP-SPECIFIC-VALUE"
    }

    var window: UIWindow?
    fileprivate var supportedOrientations: UIInterfaceOrientationMask = .allButUpsideDown

    let snapAPI = SCSDKSnapAPI()
    let cameraController = SampleCameraController()
    
    // This is how you configure properties for a CameraKit Session
    // Pass in applicationID and apiToken through a SessionConfig which will override the ones stored in the app's Info.plist
    // which is useful to dynamically update your apiToken in case it ever gets revoked.
    // let cameraController = CameraController(
    //    sessionConfig: SessionConfig(
    //        applicationID: "application_id_here", apiToken: "api_token_here"))

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        cameraController.groupIDs = [SCCameraKitLensRepositoryBundledGroup, Constants.partnerGroupId]
        
        // If you want to support sharing to Snapchat (via CreativeKit) you can set this delegate below.
        // Note that you need to make sure CreativeKit is set up correctly in your app, which includes
        // adding proper SnapKit app id in Info.plist (`SCSDKClientId`) and ensuring your app is either
        // approved in production and/or your Snapchat username is allowlisted in SnapKit dashboard.
        // See https://docs.snap.com/snap-kit/creative-kit/Tutorials/ios
        cameraController.snapchatDelegate = self
        let cameraViewController = CameraViewController(cameraController: cameraController)
        
        // It is mandatory to add a "Powered by Snap" attribution overlay
        // otherwise your app will be rejected during review.
        // You can however, configure other positions for your overlay
        // See https://docs.snap.com/snap-kit/camera-kit/release/design-guide
        addSnapAttributionOverlay(cameraViewController)
        
        cameraViewController.appOrientationDelegate = self
        window?.rootViewController = cameraViewController
        
//        If your application has a deployment target of 14.0 or higher, CameraKit Reference UI
//        supports a preview SwiftUI implementation.
//        let view = CameraView(cameraController: cameraController)
//        let cameraViewController = UIHostingController(rootView: view)
//        window?.rootViewController = cameraViewController
        
        window?.makeKeyAndVisible()

        return true
    }
    
    fileprivate func addSnapAttributionOverlay(_ cameraViewController: CameraViewController) {
        let imageName = "SnapAttribution.png"
        let image = UIImage(named: imageName)
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        cameraViewController.view.addSubview(imageView)
        let centerXConst = NSLayoutConstraint(item: imageView, attribute: .centerX, relatedBy: .equal, toItem: cameraViewController.view, attribute: .centerX, multiplier: 1.0, constant: 0.0)
        let topConst = NSLayoutConstraint(item: imageView, attribute: .top, relatedBy: .equal, toItem: cameraViewController.view, attribute: .top, multiplier: 1.0, constant: 20.0)
        
        NSLayoutConstraint.activate([centerXConst, topConst])
    }
    
    func cameraKitViewController(_ viewController: UIViewController, openSnapchat screen: SnapchatScreen) {
        switch screen {
        case .profile, .lens(_):
            // not supported yet in creative kit (1.4.2), should be added in next version
            break
        case .photo(let image):
            let photo = SCSDKSnapPhoto(image: image)
            let content = SCSDKPhotoSnapContent(snapPhoto: photo)
            sendSnapContent(content, viewController: viewController)
        case .video(let url):
            let video = SCSDKSnapVideo(videoUrl: url)
            let content = SCSDKVideoSnapContent(snapVideo: video)
            sendSnapContent(content, viewController: viewController)
        }
    }

    private func sendSnapContent(_ content: SCSDKSnapContent, viewController: UIViewController) {
        viewController.view.isUserInteractionEnabled = false
        snapAPI.startSending(content) { error in
            DispatchQueue.main.async {
                viewController.view.isUserInteractionEnabled = true
            }
            if let error = error {
                print("Failed to send content to Snapchat with error: \(error.localizedDescription)")
                return
            }
        }
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return supportedOrientations
    }
}

// MARK: Helper Orientation Methods

extension AppDelegate: AppOrientationDelegate {

    func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        supportedOrientations = orientation
    }

    func unlockOrientation() {
        supportedOrientations = .allButUpsideDown
    }

}

// MARK: Data Provider

class SampleCameraController: CameraController {
    override func configureDataProvider() -> DataProviderComponent {
        DataProviderComponent(
            deviceMotion: nil, userData: UserDataProvider(), lensHint: nil, location: nil,
            mediaPicker: lensMediaProvider, remoteApiServiceProviders: [CatFactRemoteApiServiceProvider()])
    }
}
