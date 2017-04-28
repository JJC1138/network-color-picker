import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        networkColorPickerClient.start()
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        networkColorPickerClient.stop()
    }
    
    var networkColorPickerClient = NetworkColorPickerClient()
    
}
