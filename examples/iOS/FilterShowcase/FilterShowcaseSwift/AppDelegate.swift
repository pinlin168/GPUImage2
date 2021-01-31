import UIKit
import GPUImage

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func applicationDidFinishLaunching(_ application: UIApplication) {
        _needCheckFilterContainerThread = false
    }
}
